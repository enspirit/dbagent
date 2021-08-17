module DbAgent
  class Seeder

    def initialize(handler)
      @handler = handler
    end
    attr_reader :handler

    def install(from)
      handler.sequel_db.transaction do
        folder = handler.data_folder/from

        # load files in order
        pairs = merged_data(from)
        names = pairs.keys.sort{|p1,p2|
          pairs[p1].basename <=> pairs[p2].basename
        }

        # Truncate tables then fill them
        names.reverse.each do |name|
          LOGGER.info("Emptying table `#{name}`")
          handler.sequel_db[name.to_sym].delete
        end
        names.each do |name|
          LOGGER.info("Filling table `#{name}`")
          file = pairs[name]
          handler.sequel_db[name.to_sym].multi_insert(file.load)
        end
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

    def flush_seed_file(f, to = f.parent)
      target = (handler.data_folder/to)
      table = file2table(f)
      data = viewpoint.send(table.to_sym).to_a
      if data.empty?
        LOGGER.info("Skipping table `#{table}` since empty")
      else
        LOGGER.info("Flushing table `#{table}`")
        json = JSON.pretty_generate(data)
        (target/f.basename).write(json)
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
