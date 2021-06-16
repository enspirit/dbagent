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

  # Folder containing database migrations
  MIGRATIONS_FOLDER = _!(ROOT_FOLDER/'migrations')

  # Folder containing database schema files
  SCHEMA_FOLDER = _!(ROOT_FOLDER/'schema')

  # Folder containing database data files
  DATA_FOLDER = _!(ROOT_FOLDER/'data')

  # Folder containing database data files
  BACKUP_FOLDER = _!(ROOT_FOLDER/'backups')

  # Logger instance to use
  LOGGER = Logger.new(STDOUT)
  LOGGER.level = Logger.const_get(ENV['DBAGENT_LOGLEVEL'] || 'WARN')

  # What database configuration to use for normal access
  DATABASE_CONFIG = {
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
    DATABASE_CONFIG[:socket] = socket
  else
    DATABASE_CONFIG[:host] = ENV['DBAGENT_HOST'] || 'localhost'
  end

  # Set a logger if explicitly requested
  if ENV['DBAGENT_LOGSQL'] == 'yes'
    DATABASE_CONFIG[:loggers] = [LOGGER]
  end

  # Sequel database object (for connection pooling)
  SEQUEL_DATABASE = ::Sequel.connect(DATABASE_CONFIG)

  # What database configuration to use for superuser access
  SUPERUSER_CONFIG = DATABASE_CONFIG.merge({
    user:     ENV['DBAGENT_SUPER_USER']     || DATABASE_CONFIG[:user],
    database: ENV['DBAGENT_SUPER_DB']       || DATABASE_CONFIG[:database],
    password: ENV['DBAGENT_SUPER_PASSWORD'] || DATABASE_CONFIG[:password]
  })

  # Sequel database for superuser
  SUPERUSER_DATABASE = ::Sequel.connect(SUPERUSER_CONFIG)

  def self.require_viewpoints
    vp = ROOT_FOLDER/'viewpoints'
    return unless vp.directory?
    Path.require_tree(vp.expand_path)
  end

end # module DbAgent
require 'db_agent/viewpoint'
require 'db_agent/seeder'
require 'db_agent/table_orderer'
require 'db_agent/webapp'
DbAgent.require_viewpoints
