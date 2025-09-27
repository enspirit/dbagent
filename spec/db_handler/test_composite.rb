
require 'spec_helper'

module DbAgent
  describe DbHandler::Composite do

    let(:config) {
      {
        user: 'postgres',
        database: 'sap',
      }
    }

    let(:handler) {
      DbHandler::Composite.new({
        databases: databases,
        config: config,
        root: examples_folder/subfolder
      })
    }

    context 'on a single database with no instruction' do
      let(:subfolder) {
        'suppliers-and-parts'
      }

      let(:databases) {
        nil
      }

      it 'uses the main database' do
        expect(handler.database_names).to eql(['sap'])
      end
    end

    context 'on multiple database with an explicit list' do
      let(:subfolder) {
        'multi-db'
      }

      let(:databases) {
        'db1,db2'
      }

      it 'uses the main database' do
        expect(handler.database_names).to eql(['db1', 'db2'])
      end
    end

    context 'on multiple database from empty seeds' do
      let(:subfolder) {
        'multi-db'
      }

      let(:databases) {
        '/from-empty-seeds'
      }

      it 'uses the main database' do
        expect(handler.database_names).to eql(['db1', 'db2'])
      end
    end

  end
end
