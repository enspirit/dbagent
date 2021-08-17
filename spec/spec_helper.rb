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

end

RSpec.configure do |c|
  c.include SpecHelper
end
