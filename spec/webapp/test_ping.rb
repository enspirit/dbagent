require 'spec_helper'

describe 'GET /ping' do

  it 'works' do
    get '/ping'
    expect(last_response).to be_ok
    expect(last_response.body).to eql("ok")
  end

end
