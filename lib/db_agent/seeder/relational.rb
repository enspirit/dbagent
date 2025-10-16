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

      def flush(to, inherits = "empty")
        target_path = data_folder.seed_folder(to).path.rm_rf.mkdir_p
        inherit_seed = data_folder.seed_folder(inherits)
        inherit_path = inherit_seed.path
        seed_files = inherit_seed.seed_files_per_table

        (target_path/"metadata.json").write <<-JSON.strip
          { "inherits": "#{inherits}" }
        JSON

        seed_files.each_pair do |table_name, inherit_file|
          target_file = target_path/inherit_file.basename.to_s
          table = file2table(target_file)
          flush_table(table, target_file, inherit_file)
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

      def flush_table(table, target_file, inherit_file)
        rel = viewpoint.send(table.gsub(/\./, '__').to_sym)
        data = order_data(target_file, rel)
        table_name = qualify_table(table)
        if data.empty?
          LOGGER.info("Skipping table `#{table_name}`: empty")
        elsif same_data?(inherit_file, data)
          LOGGER.info("Skipping table `#{table_name}`: same as inherited one")
        else
          LOGGER.info("Flushing table `#{table_name}`")
          json = JSON.pretty_generate(data)
          target_file.write(json)
        end
      end

      def same_data?(inherit_file, data)
        return false unless inherit_file.file?

        r = Bmg.json(inherit_file)
        s = Bmg.in_memory(data)
        same_set = (r.to_set == s.to_set)
        same_json = !same_set && (r.to_json == s.to_json)
        same_set || same_json
      end

      def order_data(file, rel)
        tuples = rel.to_a
        return tuples unless rel.type.knows_keys?

        keys = rel.type.keys.sort{|k1,k2| k1.size <=> k2.size }
        ordering = Bmg::Ordering.new(keys.first)

        tuples.sort{|t1,t2| ordering.call(t1, t2) }
      rescue => ex
        puts "Error when trying to sort `#{file}` (#{ex.message})"
        rel.to_a
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
