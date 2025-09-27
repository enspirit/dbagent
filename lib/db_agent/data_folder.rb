module DbAgent
  class DataFolder

    def initialize(db_handler, database_suffix = nil)
      @db_handler = db_handler
      @database_suffix = database_suffix
    end
    attr_reader :db_handler

    def seed_folder(seed, database_suffix = @database_suffix)
      SeedFolder.new(self, seed, database_suffix)
    end

    def path
      db_handler.data_folder
    end

    def /(part)
      path/part
    end

    def glob(*args, &bl)
      path.glob(*args, &bl)
    end

  end # class DataFolder
end # module DbAgent
