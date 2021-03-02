require_relative 'db_handler/postgresql'
require_relative 'db_handler/mssql'
require_relative 'db_handler/mysql'

module DbAgent
  class DbHandler

    def initialize(options)
      @config = options[:config]
      @superconfig = options[:superconfig]
      @backup_folder = options[:backup]
      @schema_folder = options[:schema]
      @migrations_folder = options[:migrations]
    end
    attr_reader :config, :superconfig, :backup_folder, :schema_folder, :migrations_folder

    def ping
      puts "Using #{config}"
      sequel_db.test_connection
      puts "Everything seems fine!"
    end

    def create
      raise NotImplementedError
    end

    def drop
      raise NotImplementedError
    end

    def backup
      raise NotImplementedError
    end

    def wait_server
      require 'net/ping'
      raise "No host found" unless config[:host]
      check = Net::Ping::External.new(config[:host])
      puts "Trying to ping `#{config[:host]}`"
      15.downto(0) do |i|
        print "."
        if check.ping?
          print "\nServer found.\n"
          break
        elsif i == 0
          print "\n"
          raise "Server not found, I give up."
        else
          sleep(1)
        end
      end    
    end

    def restore(t, args)
      candidates = backup_folder.glob("*.sql").sort
      if args[:pattern] && rx = Regexp.new(args[:pattern])
        candidates = candidates.select{|f| f.basename.to_s =~ rx }
      end
      file = candidates.last
      shell pg_cmd('psql', config[:database], '<', file.to_s)
    end

    def migrate
      Sequel.extension :migration
      if (sf = migrations_folder/'superuser').exists?
        Sequel::Migrator.run(sequel_superdb, migrations_folder/'superuser', table: 'superuser_migrations')
      end
      Sequel::Migrator.run(sequel_db, migrations_folder)  
    end

    def repl
      raise NotImplementedError
    end

    def spy 
      raise NotImplementedError
    end

    def self.factor(options)
      case options[:config][:adapter]
      when 'postgres'
        PostgreSQL.new(options)
      when 'mssql'
        MSSQL.new(options)
      when 'mysql'
        MySQL.new(options)
      else
        PostgreSQL.new(options)
      end
    end

  private

    def sequel_db
      @sequel_db ||= ::Sequel.connect(config)
    end

    def sequel_superdb
      raise "No superconfig set" if superconfig.nil?
      @sequel_superdb ||= ::Sequel.connect(superconfig)
    end

  end # class DbHandler
end # module DbAgent
