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

    context 'on a singledb and base seed' do
      let(:root) {
        Path.backfind('.[Gemfile]')/'examples/suppliers-and-parts'
      }

      it 'works' do
        expect(subject).to be_a(DataFolder)
      end

      it 'helps getting merged_data' do
        seed_folder = subject.seed_folder('base')
        expect(seed_folder.seed_files_per_table).to eql({
          :suppliers => root/'data/base/100-suppliers.json',
          :parts => root/'data/base/200-parts.json',
          Sequel.qualify(:public, :supplies) => root/'data/base/300-public.supplies.json',
        })
      end

      it 'helps getting before and after seeding files' do
        seed_folder = subject.seed_folder('base')
        expect(seed_folder.before_seeding_files).to eql([])
        expect(seed_folder.after_seeding_files).to eql([])
      end
    end

    context 'on a singledb and hooks seed' do
      let(:root) {
        Path.backfind('.[Gemfile]')/'examples/suppliers-and-parts'
      }

      it 'works' do
        expect(subject).to be_a(DataFolder)
      end

      it 'helps getting merged_data' do
        seed_folder = subject.seed_folder('hooks')
        expect(seed_folder.seed_files_per_table).to eql({
          :suppliers => root/'data/base/100-suppliers.json',
          :parts => root/'data/base/200-parts.json',
          Sequel.qualify(:public, :supplies) => root/'data/base/300-public.supplies.json',
        })
      end

      it 'helps getting before and after seeding files' do
        seed_folder = subject.seed_folder('hooks')
        expect(seed_folder.before_seeding_files).to eql([
          root/'data/hooks/before_seeding.sql',
        ])
        expect(seed_folder.after_seeding_files).to eql([
          root/'data/hooks/after_seeding.sql',
        ])
      end

      it 'helps getting before and after seeding files recursively' do
        seed_folder = subject.seed_folder('hooks/child')
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
