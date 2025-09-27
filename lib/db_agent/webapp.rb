module DbAgent
  class Webapp < Sinatra::Base

    set :raise_errors, false
    set :show_exceptions, false
    set :dump_errors, true
    set :db_handler, DbAgent.default_handler

    error do
      route = env['sinatra.route']
      params = env['sinatra.error.params']
      error = env['sinatra.error']
      "DbAgent (route: #{route} | params: #{params}) error: #{error.message}\n#{error.backtrace[0..10]}\n\n"
    end

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
      settings.db_handler.seeder.install(request["id"])
      "ok"
    end

    post '/seeds/flush' do
      seed_name = request["id"]
      settings.db_handler.seeder.flush(request["id"])
      "ok"
    end

  end
end
