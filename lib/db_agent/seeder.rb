module DbAgent
  class Seeder

    def initialize(handler)
      @handler = handler
    end
    attr_reader :handler

    def install(from)
      handler.sequel_db.transaction do
        before_seeding!

        folder = handler.data_folder/from

        # load files in order
        pairs = merged_data(from)
        names = pairs.keys.sort{|p1,p2|
          pairs[p1].basename <=> pairs[p2].basename
        }

        # Truncate tables
        names.reverse.each do |name|
          LOGGER.info("Emptying table `#{name}`")
          handler.sequel_db[name.to_sym].delete
        end

        # Fill them
        names.each do |name|
          LOGGER.info("Filling table `#{name}`")
          file = pairs[name]
          handler.sequel_db[name.to_sym].multi_insert(file.load)
        end

        after_seeding!(folder)
      end
    end

    def insert_script(from)
      folder = handler.data_folder/from

      # load files in order
      pairs = merged_data(from)
      names = pairs.keys.sort{|p1,p2|
        pairs[p1].basename <=> pairs[p2].basename
      }

      # Fill them
      names.each do |name|
        file = pairs[name]
        data = file.load
        next if data.empty?

        keys = data.first.keys
        values = data.map{|t|
          keys.map{|k| t[k] }
        }
        puts handler.sequel_db[name.to_sym].multi_insert_sql(keys, values)
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

    def flush_table(table_name, target_folder, file_name, skip_empty)
      data = viewpoint.send(table_name.to_sym).to_a
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

    def after_seeding!(folder)
      file = folder/"after_seeding.sql"
      handler.sequel_db.execute(file.read) if file.exists?
      after_seeding!(folder.parent) unless folder == handler.data_folder
    end

    def merged_data(from)
      folder = handler.data_folder/from
      data   = {}

      # load metadata and install parent dataset if any
      metadata = (folder/"metadata.json").load
      if parent = metadata["inherits"]
        data = merged_data(parent)
      end

      seed_files(folder).each do |f|
        data[file2table(f)] = f
      end

      data
    end

    def seed_files(folder)
      folder
        .glob("*.json")
        .reject{|f| f.basename.to_s =~ /^metadata/ }
    end

    def file2table(f)
      f.basename.rm_ext.to_s[/^\d+-(.*)/, 1]
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
