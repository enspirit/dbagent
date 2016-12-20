require 'db_agent'
require 'rspec'
require 'rack/test'

module SpecHelper
  include Rack::Test::Methods

  def app
    DbAgent::Webapp
  end

  def database
    DbAgent::SEQUEL_DATABASE
  end

end

RSpec.configure do |c|
  c.include SpecHelper
end
