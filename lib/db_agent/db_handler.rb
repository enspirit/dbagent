module DbAgent
  class DbHandler

    def initialize(options)
      @config = options[:config]
      @superconfig = options[:superconfig]
      @root_folder = options[:root]
      @backup_folder = options[:backup] || options[:root]/'backups'
      @schema_folder = options[:schema] || options[:root]/'schema'
      @migrations_folder = options[:migrations] || options[:root]/'migrations'
      @data_folder = options[:data] || options[:root]/'data'
      @viewpoints_folder = options[:viewpoints] || options[:root]/'viewpoints'
      require_viewpoints!
    end
    attr_reader :config, :superconfig
    attr_reader :backup_folder, :schema_folder, :migrations_folder
    attr_reader :data_folder, :viewpoints_folder

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

    def repl
      raise NotImplementedError
    end

    def wait_server
      require 'net/ping'
      raise "No host found" unless config[:host]
      check = Net::Ping::External.new(config[:host])
      print "Trying to ping `#{config[:host]}`\n"
      wait_timeout_in_seconds.downto(0) do |i|
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

    def wait
      print "Using #{config}\n"
      wait_timeout_in_seconds.downto(0) do |i|
        print "."
        begin
          sequel_db.test_connection
          print "\nDatabase is there. Great.\n"
          break
        rescue Sequel::Error
          if i==0
            print "\n"
            raise
          end
          sleep(1)
        end
      end
    end

    def restore(t, args)
      raise NotImplementedError
    end

    def migrate(version = nil)
      Sequel.extension :migration
      if (sf = migrations_folder/'superuser').exists?
        Sequel::Migrator.run(sequel_superdb, migrations_folder/'superuser', table: 'superuser_migrations', target: version)
      end
      Sequel::Migrator.run(sequel_db, migrations_folder, target: version)
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
      when /mysql/
        MySQL.new(options)
      else
        PostgreSQL.new(options)
      end
    end

    def sequel_db
      @sequel_db ||= ::Sequel.connect(config)
    end

    def sequel_superdb
      raise "No superconfig set" if superconfig.nil?
      @sequel_superdb ||= ::Sequel.connect(superconfig)
    end

    def system(cmd, *args)
      puts cmd
      ::Kernel.system(cmd, *args)
    end

    def require_viewpoints!
      f = viewpoints_folder.expand_path
      Path.require_tree(f) if f.directory?
    end

  private

    def wait_timeout_in_seconds
      (ENV['DBAGENT_WAIT_TIMEOUT_IN_SEC'] || '15').to_i
    end

    def print(*args)
      super.tap{ $stdout.flush }
    end

  end # class DbHandler
end # module DbAgent
require_relative 'db_handler/postgresql'
require_relative 'db_handler/mssql'
require_relative 'db_handler/mysql'
