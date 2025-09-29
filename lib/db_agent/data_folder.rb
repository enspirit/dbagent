module DbAgent
  class DataFolder

    def initialize(db_handler, database_suffix = nil)
      @db_handler = db_handler
      @database_suffix = database_suffix
    end
    attr_reader :db_handler, :database_suffix

    def seed_folder(seed)
      SeedFolder.new(self, seed, database_suffix)
    end

    def seed_folders
      folders = path.glob('**/metadata.json').map(&:parent)
      if database_suffix
        folders = folders.filter{|dir|
          dir.basename.to_s == database_suffix.to_s
        }.map(&:parent)
      end
      folders
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
