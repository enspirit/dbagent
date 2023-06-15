module DbAgent
  class DbHandler
    class MSSQL < DbHandler

      def create
        raise
      end

      def drop
        raise
      end

      def backup
        raise
      end

      def repl
        raise
      end

      def spy
        spy_jar = DbAgent._!('vendor').glob('schema*.jar').first
        jdbc_jar = DbAgent._!('vendor').glob('mssql*.jar').first
        cmd = ""
        cmd << %Q{java -jar #{spy_jar}}
        cmd << %Q{ -dp #{jdbc_jar} -t mssql05}
        cmd << %Q{ -host #{config[:host]}}
        cmd << %Q{ -u #{config[:user]}}
        cmd << %Q{ -p #{config[:password]}}
        cmd << %Q{ -db #{config[:database]}}
        cmd << %Q{ -port #{config[:port]}}
        cmd << %Q{ -s dbo}
        cmd << %Q{ -o #{schema_folder}/spy}
        cmd << %Q{ #{ENV['SCHEMA_SPY_ARGS']}} if ENV['SCHEMA_SPY_ARGS']
        system(cmd)
        system %Q{open #{schema_folder}/spy/index.html}
      end

      def restore(t, args)
      end
    end # MSSQL
  end # DbHandler
end # DbAgent
