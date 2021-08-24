module DbAgent
  class Webapp < Sinatra::Base

    set :raise_errors, true
    set :show_exceptions, false
    set :dump_errors, true
    set :db_handler, DbAgent.default_handler

    get '/ping' do
      settings.db_handler.sequel_db.test_connection
      status 200
      "ok"
    end

    get %r{/schema/?} do
      send_file(settings.db_handler.schema_folder/'spy/index.html')
    end

    get '/schema/*' do |url|
      send_file(settings.db_handler.schema_folder/'spy'/url)
    end

    post '/seeds/install' do
      Seeder.new(settings.db_handler).install(request["id"])
      "ok"
    end

    post '/seeds/flush' do
      seed_name = request["id"]
      Seeder.new(settings.db_handler).flush(request["id"])
      "ok"
    end

  end
end
