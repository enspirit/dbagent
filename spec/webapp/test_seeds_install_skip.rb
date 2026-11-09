require 'spec_helper'

# POST /seeds/install against the example database, with
# DBAGENT_SEED_SKIP_UNCHANGED on.
describe 'POST /seeds/install with DBAGENT_SEED_SKIP_UNCHANGED' do

  around do |example|
    before = ENV['DBAGENT_SEED_SKIP_UNCHANGED']
    ENV['DBAGENT_SEED_SKIP_UNCHANGED'] = 'true'
    DbAgent::SeedSkip.current.forget!
    example.run
  ensure
    DbAgent::SeedSkip.current.forget!
    ENV['DBAGENT_SEED_SKIP_UNCHANGED'] = before
  end

  def data_version
    DbAgent.default_handler.data_version
  end

  def install(seed = 'base')
    post '/seeds/install', id: seed
    expect(last_response).to be_ok
  end

  it 'leaves the database untouched when nothing changed since the last install' do
    install
    version = data_version
    install
    expect(data_version).to eql(version)
  end

  it 'installs again once something was written' do
    install
    count = database[:suppliers].count
    database[:supplies].delete
    database[:suppliers].where(sid: 'S1').delete
    install
    expect(database[:suppliers].count).to eql(count)
  end

end
