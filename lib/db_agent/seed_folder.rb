module DbAgent
  class SeedFolder
    include SeedUtils

    def initialize(data_folder, seed = 'empty', database_suffix = nil)
      @data_folder = data_folder
      @database_suffix = database_suffix
      @seed = seed
    end
    attr_reader :data_folder, :seed

    def db_handler
      data_folder.db_handler
    end

    def metadata
      @metadata ||= (path(seed)/"metadata.json").load
    end

    def path(seed = self.seed)
      if @database_suffix
        data_folder/seed/@database_suffix
      else
        data_folder/seed
      end
    end

    def parent
      @parent ||= if inherits = metadata["inherits"]
        SeedFolder.new(data_folder, inherits, @database_suffix)
      else
        NullObject.new(data_folder)
      end
    end

    def before_seeding_files
      f = (path/'before_seeding.sql')
      fs = f.file? ? [f] : []
      parent.before_seeding_files + fs
    end

    def after_seeding_files
      f = (path/'after_seeding.sql')
      fs = f.file? ? [f] : []
      parent.after_seeding_files + fs
    end

    # Returns a Hash[Sequel.qualify(table_name) => Path]
    def seed_files_per_table
      pairs = _seed_files_per_table
      pairs
        .keys
        .sort{|p1,p2|
          pairs[p1].basename <=> pairs[p2].basename
        }
        .each_with_object({}) do |name,index|
          index[qualify_table(name)] = pairs[name]
        end
    end

  protected

    def _seed_files_per_table
      folder = self.path(seed)
      map = parent._seed_files_per_table

      seed_files(folder).each do |f|
        map[file2table(f)] = f
      end

      map
    end

    def seed_files(folder)
      folder
        .glob("*.json")
        .reject{|f| f.basename.to_s =~ /^metadata/ }
    end

    class NullObject < SeedFolder
      def _seed_files_per_table
        {}
      end

      def before_seeding_files
        []
      end

      def after_seeding_files
        []
      end
    end
  end # class SeedFolder
end # module DbAgent
