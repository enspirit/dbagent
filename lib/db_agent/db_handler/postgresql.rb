module DbAgent
  class DbHandler
    class PostgreSQL
      def initialize ;end 

      def create
        shell pg_cmd("createuser","--no-createdb","--no-createrole","--no-superuser","--no-password",DATABASE_CONFIG[:user]),
        pg_cmd("createdb","--owner=#{DATABASE_CONFIG[:user]}", DATABASE_CONFIG[:database])
      end

      def drop
        shell pg_cmd("dropdb", DATABASE_CONFIG[:database]),
        pg_cmd("dropuser", DATABASE_CONFIG[:user])
      end
      
      private
      def pg_cmd(cmd, *args)
        conf = DATABASE_CONFIG
        %Q{#{cmd} -h #{conf[:host]} -p #{conf[:port]} -U #{conf[:user]} #{args.join(' ')}}
      end
    
      def psql(*args)
        pg_cmd('psql', *args)
      end    
    end
  end # module DbHandler
end # module DbAgent