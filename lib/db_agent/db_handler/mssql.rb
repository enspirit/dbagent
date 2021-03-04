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
        system %Q{java -jar vendor/schemaSpy_5.0.0.jar -dp #{jdbc_jar} -t mssql05 -host #{DATABASE_CONFIG[:host]} -u #{DATABASE_CONFIG[:user]} -p #{DATABASE_CONFIG[:password]} -db #{DATABASE_CONFIG[:database]} -port #{DATABASE_CONFIG[:port]} -s dbo -o #{SCHEMA_FOLDER}/spy}
        system %Q{open #{schema_folder}/spy/index.html}
      end

      def restore(t, args)
      end
    end # MSSQL
  end # DbHandler
end # DbAgent
