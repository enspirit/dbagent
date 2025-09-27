require 'spec_helper'

module DbAgent
  describe DbHandler do

    let(:config) {
      {
        user: 'postgres',
        database: 'sap',
      }
    }

    let(:handler) {
      DbHandler.new({
        config: config,
        root: Path.dir/'fixtures',
      })
    }

    it 'has a Sequel config' do
      expect(handler.config).to eql(config)
      expect(handler.config[:database]).to eql('sap')
    end

    it 'helps forking the config' do
      fork = handler.fork_config({
        database: 'anotherone',
      })
      expect(handler.config[:database]).to eql('sap')
      expect(fork.config[:database]).to eql('anotherone')
    end

  end
end
