# frozen_string_literal: true

module DbAgent
  class DbHandler
    class MySQL < DbHandler
      def create
        raise
      end

      def drop
        raise
      end

      def backup
        datetime = Time.now.strftime('%Y%m%dT%H%M%S')
        shell mysqldump(config[:database], "> #{backup_folder}/backup-#{datetime}.sql")
      end

      def repl
        shell mysql(config[:database])
      end

      def spy
        spy_jar = DbAgent._!('vendor').glob('schema*.jar').first
        jdbc_jar = DbAgent._!('vendor').glob('mysql*.jar').first
        cmd = ""
        cmd << %Q{java -jar #{spy_jar}}
        cmd << %Q{ -dp #{jdbc_jar} -t mysql}
        cmd << %Q{ -host #{config[:host]}}
        cmd << %Q{ -u #{config[:user]}}
        cmd << %Q{ -p #{config[:password]}}
        cmd << %Q{ -db #{config[:database]}}
        cmd << %Q{ -port #{config[:port]}}
        cmd << %Q{ -s public}
        cmd << %Q{ -o #{schema_folder}/spy}
        cmd << %Q{ #{ENV['SCHEMA_SPY_ARGS']}} if ENV['SCHEMA_SPY_ARGS']
        system(cmd)
        system %Q{open #{schema_folder}/spy/index.html}
      end

      def restore(_t, args)
        candidates = backup_folder.glob('*.sql').sort
        if args[:pattern] && rx = Regexp.new(args[:pattern])
          candidates = candidates.select { |f| f.basename.to_s =~ rx }
        end
        file = candidates.last
        shell mysql(config[:database], '<', file.to_s)
      end

      private

      def mysql_cmd(cmd, *args)
        conf = config
        %(#{cmd} -h #{config[:host]} --password=#{config[:password]} -P #{config[:port]} -u #{config[:user]} #{args.join(' ')})
      end

      def mysql(*args)
        mysql_cmd('mysql', *args)
      end

      def mysqldump(*args)
        mysql_cmd('mysqldump', *args)
      end
    end # MySQL
  end # DbHandler
end # DbAgent
