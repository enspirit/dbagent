module DbAgent
  class Seeder
    include SeedUtils

    def initialize(handler)
      @handler = handler
      @data_folder = DataFolder.new(handler)
    end
    attr_reader :handler, :data_folder

  end # class Seeder
end # module DbAgent
require_relative 'seeder/actions'
require_relative 'seeder/composite'
require_relative 'seeder/relational'
