require_relative 'db_handler/postgresql'
require_relative 'db_handler/mssql'

module DbAgent
  class DbHandler
    attr_reader :adapter_klass
    
    def initialize
    end

    def create
      adapter_klass.create
    end

    def drop
      adapter_klass.drop
    end

    private
    def klass_for(adapter)
      case adapter
      when 'postgres'
        PostgreSQL
      when 'mssql'
        MSSQL
      when 'mysql'
        MySQL
      else
        PostgreSQL
      end
    end

    def adapter_klass
      @adapter_klass ||= klass_for(DATABASE_CONFIG[:adapter]).new
    end
  end # class DbHandler
end # module DbAgent
