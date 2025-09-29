require 'spec_helper'

module DbAgent
  describe DataFolder do

    let(:data_folder) {
      DataFolder.new(db_handler, database_suffix)
    }

    let(:database_suffix) {
      nil
    }

    let(:db_handler) {
      DbHandler.new({
        config: {},
        root: root,
      })
    }

    context 'on a single-db' do
      let(:root) {
        examples_folder/'suppliers-and-parts'
      }

      it 'helps finding seed folders' do
        expect(data_folder.seed_folders.to_set).to eql([
          root/'data/base',
          root/'data/empty',
          root/'data/hooks/child',
          root/'data/hooks',
        ].to_set)
      end
    end

    context 'on a multi-db' do
      let(:root) {
        examples_folder/'multi-db'
      }

      let(:database_suffix) {
        'db1'
      }

      it 'helps finding seed folders' do
        expect(data_folder.seed_folders.to_set).to eql([
          root/'data/base',
          root/'data/empty',
        ].to_set)
      end
    end
  end
end
