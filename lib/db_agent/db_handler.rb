module DbAgent
  class DbHandler

    def initialize(options)
      @options = options
      @config = options[:config]
      @superconfig = options[:superconfig]
      @root_folder = options[:root]
      @backup_folder = options[:backup] || options[:root]/'backups'
      @schema_folder = options[:schema] || options[:root]/'schema'
      @migrations_folder = options[:migrations] || options[:root]/'migrations'
      @data_folder = options[:data] || options[:root]/'data'
      @viewpoints_folder = options[:viewpoints] || options[:root]/'viewpoints'
      @migrations_table = options[:migrations_table] || 'schema_migrations'
      @superuser_migrations_table = options[:superuser_migrations_table] || 'superuser_migrations'
      require_viewpoints!
    end
    attr_reader :options, :config, :superconfig
    attr_reader :backup_folder, :schema_folder, :migrations_folder
    attr_reader :data_folder, :viewpoints_folder
    attr_reader :migrations_table, :superuser_migrations_table

    def self.factor(options)
      if options[:databases]
        Composite.new(options)
      else
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
    end

    def system(cmd, *args)
      puts cmd
      ::Kernel.system(cmd, *args)
    end

    def require_viewpoints!
      f = viewpoints_folder.expand_path
      Path.require_tree(f) if f.directory?
    end

  # Forking

    def fork(options = {})
      DbHandler.factor(@options.merge(options))
    end

    def fork_config(partial_config = {})
      fork(config: config.merge(partial_config))
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
require_relative 'db_handler/actions'
require_relative 'db_handler/composite'
require_relative 'db_handler/relational'
require_relative 'db_handler/postgresql'
require_relative 'db_handler/mssql'
require_relative 'db_handler/mysql'
