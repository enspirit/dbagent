module DbAgent
  class Webapp < Sinatra::Base

    set :raise_errors, true
    set :show_exceptions, false
    set :dump_errors, true

    get '/ping' do
      SEQUEL_DATABASE.test_connection
      status 200
      "ok"
    end

    get %r{/schema/?} do
      send_file(SCHEMA_FOLDER/'spy/index.html')
    end

    get '/schema/*' do |url|
      send_file(SCHEMA_FOLDER/'spy'/url)
    end

    post '/seeds/install' do
      Seeder.new(SEQUEL_DATABASE).install(request["id"])
      "ok"
    end

    post '/seeds/flush' do
      seed_name = request["id"]
      Seeder.new(SEQUEL_DATABASE).flush(request["id"])
      "ok"
    end

  end
end
