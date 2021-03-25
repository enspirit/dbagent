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
        jdbc_jar = (Path.dir.parent / 'vendor').glob('mysql*.jar').first
        system %(java -jar vendor/schemaSpy_5.0.0.jar -dp #{jdbc_jar} -t mysql -host #{config[:host]} -u #{config[:user]} -p #{config[:password]} -db #{config[:database]} -s public -o #{schema_folder}/spy)
        system %(open #{schema_folder}/spy/index.html)
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
