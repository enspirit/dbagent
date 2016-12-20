module DbAgent
  class Seeder

    def initialize(db = SEQUEL_DATABASE)
      @db = db
    end
    attr_reader :db

    def install(from)
      db.transaction do
        folder = DATA_FOLDER/from

        # load files in order
        pairs = merged_data(from)
        names = pairs.keys.sort{|p1,p2|
          pairs[p1].basename <=> pairs[p2].basename
        }

        # Truncate tables then fill them
        names.reverse.each do |name|
          db[name.to_sym].delete
        end
        names.each do |name|
          file = pairs[name]
          db[name.to_sym].multi_insert(file.load)
        end
      end
    end

    def flush(to)
      target = (DATA_FOLDER/to).rm_rf.mkdir_p
      source = (DATA_FOLDER/"empty")
      (target/"metadata.json").write <<-JSON.strip
        { "inherits": "empty" }
      JSON
      seed_files(source).each do |f|
        flush_seed_file(f, to)
      end
    end

    def flush_seed_file(f, to = f.parent)
      target = (DATA_FOLDER/to)
      table = file2table(f)
      data = db[table.to_sym].to_a
      unless data.empty?
        json = JSON.pretty_generate(data)
        (target/f.basename).write(json)
      end
    end

    def each_seed(install = true)
      DATA_FOLDER.glob('**/*') do |file|
        next unless file.directory?
        next unless (file/"metadata.json").exists?

        base = file.relative_to(DATA_FOLDER)
        begin
          Seeder.new.install(base)
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
      folder = DATA_FOLDER/from
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

  end # class Seeder
end # module DbAgent
