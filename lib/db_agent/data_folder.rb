module DbAgent
  class DataFolder

    def initialize(db_handler)
      @db_handler = db_handler
    end
    attr_reader :db_handler

    def seed_folder(seed)
      SeedFolder.new(self, seed)
    end

  end # class DataFolder
end # module DbAgent
