module DbAgent
  class Seeder
    include SeedUtils

    def initialize(handler, database_suffix = nil)
      @handler = handler
      @database_suffix = database_suffix
      @data_folder = DataFolder.new(handler, database_suffix)
    end
    attr_reader :handler, :data_folder, :database_suffix

    def ignored_flush_fields
      @ignored_flush_fields ||= begin
        ignored = ENV['DBAGENT_IGNORED_FLUSH_FIELDS'] || ''
        ignored.split(/\s*,\s*/).map(&:to_sym)
      end
    end

  end # class Seeder
end # module DbAgent
require_relative 'seeder/actions'
require_relative 'seeder/composite'
require_relative 'seeder/relational'
