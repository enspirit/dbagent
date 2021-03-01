module DbAgent
  class DbHandler
    class PostgreSQL < DbHandler

      def create
        shell pg_cmd("createuser","--no-createdb","--no-createrole","--no-superuser","--no-password",config[:user]),
        pg_cmd("createdb","--owner=#{config[:user]}", config[:database])
      end

      def drop
        shell pg_cmd("dropdb", config[:database]),
        pg_cmd("dropuser", config[:user])
      end

      def backup
        datetime = Time.now.strftime("%Y%m%dT%H%M%S")
        shell pg_cmd("pg_dump", "--clean", "> #{backup_folder}/backup-#{datetime}.sql")
      end

      def repl
        shell pg_cmd('psql', config[:database])
      end

      def spy
        jdbc_jar = (Path.dir.parent/'vendor').glob('postgresql*.jar').first
        system %Q{java -jar vendor/schemaSpy_5.0.0.jar -dp #{jdbc_jar} -t pgsql -host #{config[:host]} -u #{config[:user]} -db #{config[:database]} -s public -o #{schema_folder}/spy}
        system %Q{open #{schema_folder}/spy/index.html}    
      end

      private

      def pg_cmd(cmd, *args)
        %Q{#{cmd} -h #{config[:host]} -p #{config[:port]} -U #{config[:user]} #{args.join(' ')}}
      end

      def psql(*args)
        pg_cmd('psql', *args)
      end
    end # class PostgreSQL
  end # module DbHandler
end # module DbAgent