module DbAgent
  class Seeder
    class Relational < Seeder

      # Installs the `from` seed. When `include_parents` is false, only the
      # seed's own tables are reset — the tables it inherits from its parent
      # seed(s) are left untouched. Splitting rarely-written reference data into
      # a parent seed and re-installing the child with `include_parents: false`
      # thus skips reloading the (typically large) static tables. This mirrors
      # the option `insert_script` already exposes.
      def install(from, include_parents: true)
        seed_folder = data_folder.seed_folder(from)
        seed_files = seed_folder.seed_files_per_table(include_parents)

        # The tables a seed fills differ with `include_parents`, and so do the
        # files `seed_skip` compares: a full install never passes for a partial
        # one, or the other way round.
        seed_skip = SeedSkip.current
        if seed_skip.skippable?(handler, from, seed_files)
          LOGGER.info("Skipping install of `#{from}`: nothing changed since the last one")
          return
        end
        seed_skip.forget!

        sequel_db.transaction do
          disable_triggers! if disable_triggers?

          before_seeding!(seed_folder, include_parents)

          # Empty tables
          seed_files.keys.reverse.each do |table|
            LOGGER.info("Emptying table `#{sequel_db.literal(table)}`")
            sequel_db[table].delete
          end

          # Fill them
          seed_files.keys.each do |table|
            file = seed_files[table]
            data = file.load
            LOGGER.info("Filling table `#{sequel_db.literal(table)}` from #{file}")
            raise "Empty file: #{file}" if data.nil?

            sequel_db[table].multi_insert(data)
          end

          after_seeding!(seed_folder, include_parents)
        end
        seed_skip.installed!(handler, from, seed_files)
      end

      # Applies the `from` seed without emptying anything: its before_seeding
      # scripts, then its rows, then its after_seeding scripts, in a single
      # transaction. What `insert_script` prints, executed.
      #
      # `install` empties every table the seed names before refilling it, which
      # makes it unusable against a database holding rows the seed is not about
      # — a production one. `apply` is for a seed that carries a *slice* of the
      # database (one project, one tenant) and whose before_seeding script
      # deletes exactly the rows it is about to replace. That makes it
      # idempotent: applying it twice installs it, then updates it.
      #
      # `include_parents` defaults to false, the other way round from `install`:
      # a slice is self-contained, and its parent's rows are typically already
      # in the database that is being added to.
      def apply(from, include_parents: false)
        seed_folder = data_folder.seed_folder(from)
        seed_files = seed_folder.seed_files_per_table(include_parents)

        sequel_db.transaction do
          disable_triggers! if disable_triggers?

          before_seeding!(seed_folder, include_parents)

          seed_files.keys.each do |table|
            file = seed_files[table]
            data = file.load
            raise "Empty file: #{file}" if data.nil?
            next if data.empty?

            LOGGER.info("Filling table `#{sequel_db.literal(table)}` from #{file}")
            sequel_db[table].multi_insert(data)
          end

          after_seeding!(seed_folder, include_parents)
        end
      end

      def insert_script(from, include_parents: true)
        seed_folder = data_folder.seed_folder(from)
        seed_files = seed_folder.seed_files_per_table(include_parents)

        puts "BEGIN;"
        puts

        seed_folder.before_seeding_files(include_parents).each do |file|
          puts file.read
          puts
        end

        # Fill them
        seed_files.keys.each do |table|
          file = seed_files[table]
          data = file.load
          next if data.empty?

          keys = data.first.keys
          values = data.map{|t|
            keys.map{|k| t[k] }
          }
          puts sequel_db[table].multi_insert_sql(keys, values) << ';'
        end

        puts
        seed_folder.after_seeding_files(include_parents).each do |file|
          puts file.read
          puts
        end

        puts
        puts "COMMIT;"
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

        r = Bmg.json(inherit_file).allbut(ignored_flush_fields)
        s = Bmg.in_memory(data).allbut(ignored_flush_fields)
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

      # Whether to load the seed with user triggers (and foreign key checks)
      # suppressed, as `pg_dump --disable-triggers` does.
      #
      # A seed is a complete snapshot: every derived row it needs is already in
      # the data files. A trigger that derives rows (e.g. an AFTER INSERT on
      # auth.users that also writes user_roles) therefore re-derives state the
      # seed inserts itself, and the two collide. Suppressing triggers fixes
      # that, but it is not free: foreign key violations within the seed go
      # unnoticed, including those `rake db:check-seeds` exists to catch. Hence
      # opt-in, and off by default.
      def disable_triggers?
        DbAgent.flag?(ENV['DBAGENT_SEED_DISABLE_TRIGGERS'], false)
      end

      def disable_triggers!
        unless sequel_db.database_type == :postgres
          LOGGER.warn("Ignoring DBAGENT_SEED_DISABLE_TRIGGERS: PostgreSQL only")
          return
        end

        sequel_db.run("SET LOCAL session_replication_role = 'replica'")
      rescue Sequel::DatabaseError => ex
        raise "Unable to honor DBAGENT_SEED_DISABLE_TRIGGERS: setting " \
              "`session_replication_role` requires superuser privileges " \
              "(#{ex.message})"
      end

      def before_seeding!(seed_folder, include_parents = true)
        seed_folder.before_seeding_files(include_parents).each do |file|
          LOGGER.info("Executing `#{file}`")
          sequel_db.execute(file.read)
        end
      end

      def after_seeding!(seed_folder, include_parents = true)
        seed_folder.after_seeding_files(include_parents).each do |file|
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
