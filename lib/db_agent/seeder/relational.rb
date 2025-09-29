module DbAgent
  class Seeder
    class Relational < Seeder

      def install(from)
        seed_folder = data_folder.seed_folder(from)
        seed_files = seed_folder.seed_files_per_table

        sequel_db.transaction do
          before_seeding!(seed_folder)

          # Truncate tables
          seed_files.keys.reverse.each do |table|
            LOGGER.info("Emptying table `#{table}`")
            sequel_db[table].delete
          end

          # Fill them
          seed_files.keys.each do |table|
            file = seed_files[table]
            data = file.load
            LOGGER.info("Filling table `#{table}` from #{file}")
            raise "Empty file: #{file}" if data.nil?

            sequel_db[table].multi_insert(data)
          end

          after_seeding!(seed_folder)
        end
      end

      def insert_script(from)
        seed_folder = data_folder.seed_folder(from)
        seed_files = seed_folder.seed_files_per_table

        # Fill them
        seed_files.keys.each do |table|
          file = seed_files[table]
          data = file.load
          next if data.empty?

          keys = data.first.keys
          values = data.map{|t|
            keys.map{|k| t[k] }
          }
          puts sequel_db[table].multi_insert_sql(keys, values)
        end
      end

      def flush_empty(to = "empty")
        target = data_folder.seed_folder(to).path.rm_rf.mkdir_p

        (target/"metadata.json").write <<-JSON.strip
          {}
        JSON

        TableOrderer.new(handler).tsort.each_with_index do |table_name, index|
          (target/"#{(index*10).to_s.rjust(5,"0")}-#{table_name}.json").write("[]")
        end
      end

      def flush(to)
        target = data_folder.seed_folder(to).path.rm_rf.mkdir_p
        source = data_folder.seed_folder('empty')
        seed_files = source.seed_files_per_table

        (target/"metadata.json").write <<-JSON.strip
          { "inherits": "empty" }
        JSON

        seed_files.each_pair do |table_name, source_file|
          target_file = target/source_file.basename.to_s
          table = file2table(target_file)
          flush_table(table, target_file, true)
        end
      end

      def check_seeds
        data_folder.seed_folders.each do |file|
          base = file.relative_to(data_folder.path).to_s
          begin
            install(base)
            puts "#{database_suffix}/#{base} OK"
          rescue => ex
            puts "KO on #{database_suffix}/#{base}"
            puts ex.message
          end
        end
      end

    private

      def flush_table(table, target_file, skip_empty)
        data = viewpoint.send(table.gsub(/\./, '__').to_sym).to_a
        table_name = qualify_table(table)
        if data.empty? && skip_empty
          LOGGER.info("Skipping table `#{table_name}` since empty")
        else
          LOGGER.info("Flushing table `#{table_name}`")
          json = JSON.pretty_generate(data)
          target_file.write(json)
        end
      end

      def before_seeding!(seed_folder)
        seed_folder.before_seeding_files.each do |file|
          LOGGER.info("Executing `#{file}`")
          sequel_db.execute(file.read)
        end
      end

      def after_seeding!(seed_folder)
        seed_folder.after_seeding_files.each do |file|
          LOGGER.info("Executing `#{file}`")
          sequel_db.execute(file.read)
        end
      end

      def viewpoint
        @viewpoint ||= if vp = ENV['DBAGENT_VIEWPOINT']
          Kernel.const_get(vp).new(sequel_db)
        else
          Viewpoint::Base.new(sequel_db)
        end
      end

      def sequel_db
        handler.send(:sequel_db)
      end

    end # class Relational
  end # class Seeder
end # module DbAgent
