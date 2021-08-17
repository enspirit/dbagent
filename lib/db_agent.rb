require 'path'
require 'logger'
require 'sequel'
require 'sinatra'
require 'bmg'
require 'bmg/sequel'
module DbAgent

  # Current version of DbAgent
  VERSION = "2.2.2"

  # Simply checks that a path exists of raise an error
  def self._!(path)
    Path(path).tap do |p|
      raise "Missing #{p.basename}." unless p.exists?
    end
  end

  # Root folder of the project structure
  ROOT_FOLDER = if ENV['DBAGENT_ROOT_FOLDER']
    _!(ENV['DBAGENT_ROOT_FOLDER'])
  else
    Path.backfind('.[Gemfile]') or raise("Missing Gemfile")
  end

  # Logger instance to use
  LOGGER = Logger.new(STDOUT)
  LOGGER.level = Logger.const_get(ENV['DBAGENT_LOGLEVEL'] || 'WARN')

  # What database configuration to use for normal access
  def self.default_config
    cfg = {
      adapter:  ENV['DBAGENT_ADAPTER']  || 'postgres',
      port:     ENV['DBAGENT_PORT']     || 5432,
      database: ENV['DBAGENT_DB']       || 'suppliers-and-parts',
      user:     ENV['DBAGENT_USER']     || 'dbagent',
      password: ENV['DBAGENT_PASSWORD'] || 'dbagent',
      test:     false
    }

    # Favor a socket approach if specified, otherwise fallback to
    # host with default to postgres
    if socket = ENV['DBAGENT_SOCKET']
      cfg[:socket] = socket
    else
      cfg[:host] = ENV['DBAGENT_HOST'] || 'localhost'
    end

    # Set a logger if explicitly requested
    if ENV['DBAGENT_LOGSQL'] == 'yes'
      cfg[:loggers] = [LOGGER]
    end

    cfg
  end

  # What database configuration to use for superuser access
  def self.default_superconfig
    cfg = default_config
    cfg.merge({
      user:     ENV['DBAGENT_SUPER_USER']     || cfg[:user],
      database: ENV['DBAGENT_SUPER_DB']       || cfg[:database],
      password: ENV['DBAGENT_SUPER_PASSWORD'] || cfg[:password]
    })
  end

  def self.default_handler
    DbHandler.factor({
      config: default_config,
      superconfig: default_superconfig,
      root: ROOT_FOLDER
    })
  end

end # module DbAgent
require 'db_agent/viewpoint'
require 'db_agent/seeder'
require 'db_agent/table_orderer'
require 'db_agent/db_handler'
require 'db_agent/webapp'
