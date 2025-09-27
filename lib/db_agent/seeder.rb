module DbAgent
  class Seeder
    include SeedUtils

    def initialize(handler)
      @handler = handler
      @data_folder = DataFolder.new(handler)
    end
    attr_reader :handler, :data_folder

    def install(from)
      handler.sequel_db.transaction do
        before_seeding!

        seed_folder = data_folder.seed_folder(from)

        # load files in order
        pairs = seed_folder.seed_files_per_table

        # Truncate tables
        pairs.keys.reverse.each do |table|
          LOGGER.info("Emptying table `#{table}`")
          handler.sequel_db[table].delete
        end

        # Fill them
        pairs.keys.each do |table|
          LOGGER.info("Filling table `#{table}`")
          file = pairs[table]
          data = file.load
          raise "Empty file: #{file}" if data.nil?

          handler.sequel_db[table].multi_insert(data)
        end

        after_seeding!(seed_folder)
      end
    end

    def insert_script(from)
      seed_folder = data_folder.seed_folder(from)

      # load files in order
      pairs = seed_folder.seed_files_per_table

      # Fill them
      pairs.keys.each do |table|
        file = pairs[table]
        data = file.load
        next if data.empty?

        keys = data.first.keys
        values = data.map{|t|
          keys.map{|k| t[k] }
        }
        puts handler.sequel_db[table].multi_insert_sql(keys, values)
      end
    end

    def flush_empty(to = "empty")
      target = (handler.data_folder/to).rm_rf.mkdir_p
      (target/"metadata.json").write <<-JSON.strip
        {}
      JSON
      TableOrderer.new(handler).tsort.each_with_index do |table_name, index|
        (target/"#{(index*10).to_s.rjust(5,"0")}-#{table_name}.json").write("[]")
      end
    end

    def flush(to)
      target = (handler.data_folder/to).rm_rf.mkdir_p
      source = (handler.data_folder/"empty")
      (target/"metadata.json").write <<-JSON.strip
        { "inherits": "empty" }
      JSON
      seed_files(source).each do |f|
        flush_seed_file(f, to)
      end
    end

    def flush_seed_file(f, to)
      target = (handler.data_folder/to)
      table = file2table(f)
      flush_table(table, target, f.basename, true)
    end

    def flush_table(table, target_folder, file_name, skip_empty)
      data = viewpoint.send(table.gsub(/\./, '__').to_sym).to_a
      table_name = qualify_table(table)
      if data.empty? && skip_empty
        LOGGER.info("Skipping table `#{table_name}` since empty")
      else
        LOGGER.info("Flushing table `#{table_name}`")
        json = JSON.pretty_generate(data)
        (target_folder/file_name).write(json)
      end
    end

    def each_seed(install = true)
      handler.data_folder.glob('**/*') do |file|
        next unless file.directory?
        next unless (file/"metadata.json").exists?

        base = file.relative_to(handler.data_folder)
        begin
          Seeder.new(handler).install(base)
          puts "#{base} OK"
          yield(self, file) if block_given?
        rescue => ex
          puts "KO on #{file}"
          puts ex.message
        end if install
      end
    end

  private

    def before_seeding!
      file = handler.data_folder/"before_seeding.sql"
      return unless file.exists?

      handler.sequel_db.execute(file.read)
    end

    def after_seeding!(seed_folder, folder = seed_folder.folder)
      file = folder/"after_seeding.sql"
      handler.sequel_db.execute(file.read) if file.exists?
      after_seeding!(seed_folder, folder.parent) unless folder == handler.data_folder
    end

    def viewpoint
      @viewpoint ||= if vp = ENV['DBAGENT_VIEWPOINT']
        Kernel.const_get(vp).new(handler.sequel_db)
      else
        Viewpoint::Base.new(handler.sequel_db)
      end
    end

  end # class Seeder
end # module DbAgent
