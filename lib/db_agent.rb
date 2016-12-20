require 'path'
require 'sequel'
require 'sinatra'
module DbAgent

  # Simply checks that a path exists of raise an error
  def self._!(path)
    Path(path).tap do |p|
      raise "Missing #{p.basename}." unless p.exists?
    end
  end

  # Root folder of the project structure
  ROOT_FOLDER = Path.backfind('.[Gemfile]') or raise("Missing Gemfile")

  # Simple pointer to the config folder
  CONFIG_FOLDER = _!(ROOT_FOLDER/'config')

  # Folder containing database migrations
  MIGRATIONS_FOLDER = _!(ROOT_FOLDER/'migrations')

  # Folder containing database schema files
  SCHEMA_FOLDER = _!(ROOT_FOLDER/'schema')

  # Folder containing database data files
  DATA_FOLDER = _!(ROOT_FOLDER/'data')

  # Database configuration file
  DATABASE_CONFIG_FILE = CONFIG_FOLDER/'database.yml'

  # What database configuration to use for normal access
  DATABASE_CONFIG = {
    adapter:  ENV['DBAGENT_ADAPTER'] || 'postgres',
    host:     ENV['DBAGENT_HOST']    || 'postgres',
    port:     ENV['DBAGENT_PORT']    || 5432,
    database: ENV['DBAGENT_DB']      || 'postgres',
    user:     ENV['DBAGENT_USER']    || 'postgres',
    password: ENV['DBAGENT_PASSWORD']
  }

  # Sequel database object (for connection pooling)
  SEQUEL_DATABASE = ::Sequel.connect(DATABASE_CONFIG)

  # What database configuration to use for superuser access
  SUPERUSER_CONFIG = {
    adapter:  DATABASE_CONFIG[:adapter],
    host:     DATABASE_CONFIG[:host],
    port:     DATABASE_CONFIG[:port],
    user:     ENV['DBAGENT_SUPER_USER']     || DATABASE_CONFIG[:user],
    database: ENV['DBAGENT_SUPER_DB']       || DATABASE_CONFIG[:database],
    password: ENV['DBAGENT_SUPER_PASSWORD'] || DATABASE_CONFIG[:password]
  }

  # Sequel database for superuser
  SUPERUSER_DATABASE = ::Sequel.connect(SUPERUSER_CONFIG)

end # module DbAgent
require 'db_agent/seeder'
require 'db_agent/webapp'
