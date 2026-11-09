require 'spec_helper'

module DbAgent
  describe 'DbHandler#data_version' do

    def handler_of(klass)
      klass.new(config: { database: 'sap' }, root: Path.dir/'fixtures')
    end

    it 'is not supported by default' do
      handler = handler_of(DbHandler)
      expect(handler.supports_data_version?).to eql(false)
      expect(handler.data_version).to be_nil
    end

    it 'is not supported yet on MySQL nor MSSQL' do
      expect(handler_of(DbHandler::MySQL).supports_data_version?).to eql(false)
      expect(handler_of(DbHandler::MSSQL).supports_data_version?).to eql(false)
    end

    it 'is not implemented yet on MySQL nor MSSQL' do
      expect { handler_of(DbHandler::MySQL).data_version }.to raise_error(NotImplementedError)
      expect { handler_of(DbHandler::MSSQL).data_version }.to raise_error(NotImplementedError)
    end

    context 'on PostgreSQL' do
      let(:handler) { DbAgent.default_handler }

      it 'is supported' do
        expect(handler).to be_a(DbHandler::PostgreSQL)
        expect(handler.supports_data_version?).to eql(true)
        expect(handler.data_version).to be_a(String)
      end

      it 'does not change on a read' do
        version = handler.data_version
        database[:suppliers].count
        expect(handler.data_version).to eql(version)
      end

      it 'changes on a write, even one rolled back' do
        version = handler.data_version
        database.transaction(rollback: :always) do
          database[:suppliers].insert(sid: 'S99', name: 'Nobody', status: 1, city: 'Nowhere')
        end
        expect(handler.data_version).not_to eql(version)
      end
    end

  end
end
