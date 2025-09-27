require 'db_agent'
require 'rspec'
require 'rack/test'

module SpecHelper
  include Rack::Test::Methods

  def app
    DbAgent::Webapp
  end

  def database
    @db ||= DbAgent.default_handler.sequel_db
  end

  def examples_folder
    Path.backfind('.[Gemfile]')/'examples'
  end

end

RSpec.configure do |c|
  c.include SpecHelper
end
