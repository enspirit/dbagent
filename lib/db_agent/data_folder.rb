module DbAgent
  class DataFolder

    def initialize(db_handler)
      @db_handler = db_handler
    end
    attr_reader :db_handler

    def seed_folder(seed, database = nil)
      SeedFolder.new(self, seed, database)
    end

  end # class DataFolder
end # module DbAgent
