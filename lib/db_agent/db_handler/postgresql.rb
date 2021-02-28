module DbAgent
  class DbHandler
    class PostgreSQL
      def self.create
        shell pg_cmd("createuser","--no-createdb","--no-createrole","--no-superuser","--no-password",DATABASE_CONFIG[:user]),
        pg_cmd("createdb","--owner=#{DATABASE_CONFIG[:user]}", DATABASE_CONFIG[:database])
      end

      def self.drop
        shell pg_cmd("dropdb", DATABASE_CONFIG[:database]),
        pg_cmd("dropuser", DATABASE_CONFIG[:user])
      end
      
      private
      def self.pg_cmd(cmd, *args)
        puts "Im here"
        conf = DATABASE_CONFIG
        %Q{#{cmd} -h #{conf[:host]} -p #{conf[:port]} -U #{conf[:user]} #{args.join(' ')}}
      end
    
      def self.psql(*args)
        pg_cmd('psql', *args)
      end
    
      def self.shell(*cmds)
        cmd = cmds.join("\n")
        puts cmd
        system cmd
      end
    end
  end # module DbHandler
end # module DbAgent