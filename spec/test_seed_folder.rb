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

    context 'on a singledb and base seed' do
      let(:root) {
        examples_folder/'suppliers-and-parts'
      }

      it 'works' do
        expect(data_folder).to be_a(DataFolder)
      end

      it 'helps getting seed files per table' do
        seed_folder = data_folder.seed_folder('base')
        expect(seed_folder.seed_files_per_table).to eql({
          :suppliers => root/'data/base/100-suppliers.json',
          :parts => root/'data/base/200-parts.json',
          Sequel.qualify(:public, :supplies) => root/'data/base/300-public.supplies.json',
        })
      end

      it 'helps getting before and after seeding files' do
        seed_folder = data_folder.seed_folder('base')
        expect(seed_folder.before_seeding_files).to eql([])
        expect(seed_folder.after_seeding_files).to eql([])
      end
    end

    context 'on a multi-db and base seed' do
      let(:root) {
        examples_folder/'multi-db'
      }
      let(:database_suffix) {
        'db1'
      }

      it 'helps getting seed files per table' do
        seed_folder = data_folder.seed_folder('base')
        expect(seed_folder.seed_files_per_table).to eql({
          :todo => root/'data/base/db1/01-todo.json',
        })
      end


      it 'helps getting before and after seeding files' do
        seed_folder = data_folder.seed_folder('base')
        expect(seed_folder.before_seeding_files).to eql([
          root/'data/empty/db1/before_seeding.sql',
          root/'data/base/db1/before_seeding.sql',
        ])
        expect(seed_folder.after_seeding_files).to eql([
          root/'data/empty/db1/after_seeding.sql',
          root/'data/base/db1/after_seeding.sql',
        ])
      end
    end

    context 'on a singledb and hooks seed' do
      let(:root) {
        Path.backfind('.[Gemfile]')/'examples/suppliers-and-parts'
      }

      it 'works' do
        expect(data_folder).to be_a(DataFolder)
      end

      it 'helps getting seed files per table' do
        seed_folder = data_folder.seed_folder('hooks')
        expect(seed_folder.seed_files_per_table).to eql({
          :suppliers => root/'data/base/100-suppliers.json',
          :parts => root/'data/base/200-parts.json',
          Sequel.qualify(:public, :supplies) => root/'data/base/300-public.supplies.json',
        })
      end

      it 'helps getting before and after seeding files' do
        seed_folder = data_folder.seed_folder('hooks')
        expect(seed_folder.before_seeding_files).to eql([
          root/'data/hooks/before_seeding.sql',
        ])
        expect(seed_folder.after_seeding_files).to eql([
          root/'data/hooks/after_seeding.sql',
        ])
      end

      it 'helps getting before and after seeding files recursively' do
        seed_folder = data_folder.seed_folder('hooks/child')
        expect(seed_folder.before_seeding_files).to eql([
          root/'data/hooks/before_seeding.sql',
          root/'data/hooks/child/before_seeding.sql',
        ])
        expect(seed_folder.after_seeding_files).to eql([
          root/'data/hooks/after_seeding.sql',
          root/'data/hooks/child/after_seeding.sql',
        ])
      end
    end
  end
end
