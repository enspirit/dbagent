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
        jdbc_jar = (Path.dir.parent/'vendor').glob('mssql*.jar').first
        system %Q{java -jar vendor/schemaSpy_5.0.0.jar -dp #{jdbc_jar} -t mssql05 -host #{config[:host]} -u #{config[:user]} -p #{config[:password]} -db #{config[:database]} -port #{config[:port]} -s dbo -o #{schema_folder}/spy}
        system %Q{open #{schema_folder}/spy/index.html}
      end

      def restore(t, args)
      end
    end # MSSQL
  end # DbHandler
end # DbAgent
