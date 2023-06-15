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
        shell pg_dump("--clean", config[:database], "> #{backup_folder}/backup-#{datetime}.sql")
      end

      def repl
        shell pg_cmd('psql', config[:database])
      end

      def spy
        spy_jar = DbAgent._!('vendor').glob('schema*.jar').first
        jdbc_jar = DbAgent._!('vendor').glob('postgresql*.jar').first
        cmd = ""
        cmd << %Q{java -jar #{spy_jar}}
        cmd << %Q{ -dp #{jdbc_jar} -t pgsql}
        cmd << %Q{ -host #{config[:host]}}
        cmd << %Q{ -port #{config[:port]}} if config[:port]
        cmd << %Q{ -u #{config[:user]}}
        cmd << %Q{ -p #{config[:password]}} if config[:password]
        cmd << %Q{ -db #{config[:database]}}
        cmd << %Q{ -s public}
        cmd << %Q{ -o #{schema_folder}/spy}
        cmd << %Q{ #{ENV['SCHEMA_SPY_ARGS']}} if ENV['SCHEMA_SPY_ARGS']
        system(cmd)
        system %Q{open #{schema_folder}/spy/index.html}
      end

      def restore(t, args)
        candidates = backup_folder.glob("*.sql").sort
        if args[:pattern] && rx = Regexp.new(args[:pattern])
          candidates = candidates.select{|f| f.basename.to_s =~ rx }
        end
        file = candidates.last
        shell pg_cmd('psql', config[:database], '<', file.to_s)
      end

    private

      def pg_cmd(cmd, *args)
        %Q{#{cmd} -h #{config[:host]} -p #{config[:port]} -U #{config[:user]} #{args.join(' ')}}
      end

      def psql(*args)
        cmd = "psql"
        cmd = "PGPASSWORD=#{config[:password]} #{cmd}" if config[:password]
        pg_cmd(cmd, *args)
      end

      def pg_dump(*args)
        cmd = "pg_dump"
        cmd = "PGPASSWORD=#{config[:password]} #{cmd}" if config[:password]
        pg_cmd(cmd, *args)
      end
    end # class PostgreSQL
  end # module DbHandler
end # module DbAgent
