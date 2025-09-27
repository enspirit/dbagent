require 'spec_helper'

module DbAgent
  describe DataFolder do

    subject {
      DataFolder.new(db_handler)
    }

    let(:db_handler) {
      DbHandler.new({
        config: {},
        root: root,
      })
    }

    context 'on a singledb' do
      let(:root) {
        Path.backfind('.[Gemfile]')/'examples/suppliers-and-parts'
      }

      it 'works' do
        expect(subject).to be_a(DataFolder)
      end

      it 'helps getting merged_data' do
        expect(subject.seed_folder('base').seed_files_per_table).to eql({
          :suppliers => root/'data/base/100-suppliers.json',
          :parts => root/'data/base/200-parts.json',
          Sequel.qualify(:public, :supplies) => root/'data/base/300-public.supplies.json',
        })
      end
    end
  end
end
