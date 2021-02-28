require_relative 'db_handler/postgresql'
module DbAgent
  class DbHandler
    
    def initialize
    end

    def create
      klass_for(DATABASE_CONFIG[:adapter]).create
    end

    # def drop(adapter)
    #   klass_for(adapter).drop
    # end

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
  end # class DbHandler
end # module DbAgent
