module DbAgent
  class SeedFolder
    include SeedUtils

    def initialize(data_folder, seed = 'empty')
      @data_folder = data_folder
      @seed = seed
    end
    attr_reader :data_folder, :seed

    def db_handler
      data_folder.db_handler
    end

    def folder(seed = self.seed)
      db_handler.data_folder/seed
    end

    # Returns a Hash[Sequel.qualify(table_name) => Path]
    def seed_files_per_table
      pairs = _seed_files_per_table(seed)
      pairs
        .keys
        .sort{|p1,p2|
          pairs[p1].basename <=> pairs[p2].basename
        }
        .each_with_object({}) do |name,index|
          index[qualify_table(name)] = pairs[name]
        end
    end

    def _seed_files_per_table(seed)
      folder = self.folder(seed)
      data = {}

      # load metadata and install parent dataset if any
      metadata = (folder/"metadata.json").load
      if parent = metadata["inherits"]
        data = _seed_files_per_table(parent)
      end

      seed_files(folder).each do |f|
        data[file2table(f)] = f
      end

      data
    end
    private :_seed_files_per_table

  end # class SeedFolder
end # module DbAgent
