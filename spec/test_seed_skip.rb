require 'spec_helper'
require 'tmpdir'

module DbAgent
  describe SeedSkip do

    # A handler whose driver answers `version` as its data version.
    class FakeHandler
      attr_accessor :version, :supported

      def initialize(version)
        @version = version
        @supported = true
      end

      def supports_data_version?
        supported
      end

      def data_version
        version
      end
    end

    let(:skip) { SeedSkip.new }
    let(:handler) { FakeHandler.new('0/A000') }
    let(:file) { examples_folder/'suppliers-and-parts'/'data'/'base'/'100-suppliers.json' }
    let(:seed_files) { { suppliers: file } }

    it 'never skips before a first install' do
      expect(skip.skippable?(handler, 'base', seed_files)).to eql(false)
    end

    it 'skips the same seed while the data version has not changed' do
      skip.installed!(handler, 'base', seed_files)
      expect(skip.skippable?(handler, 'base', seed_files)).to eql(true)
    end

    it 'installs again once the data version changed' do
      skip.installed!(handler, 'base', seed_files)
      handler.version = '0/A100'
      expect(skip.skippable?(handler, 'base', seed_files)).to eql(false)
    end

    it 'installs again for another seed' do
      skip.installed!(handler, 'base', seed_files)
      expect(skip.skippable?(handler, 'other', seed_files)).to eql(false)
    end

    it 'installs again when the seed reads other files (e.g. without its parents)' do
      skip.installed!(handler, 'base', seed_files)
      expect(skip.skippable?(handler, 'base', {})).to eql(false)
    end

    it 'installs again when a seed file changed on disk' do
      Dir.mktmpdir do |dir|
        changing = Path(dir)/'100-suppliers.json'
        changing.write('[]')
        files = { suppliers: changing }
        skip.installed!(handler, 'base', files)
        File.utime(Time.now + 60, Time.now + 60, changing.to_s)
        expect(skip.skippable?(handler, 'base', files)).to eql(false)
      end
    end

    it 'installs again after forget!' do
      skip.installed!(handler, 'base', seed_files)
      skip.forget!
      expect(skip.skippable?(handler, 'base', seed_files)).to eql(false)
    end

    it 'never skips when the data version cannot be read' do
      handler.version = nil
      skip.installed!(handler, 'base', seed_files)
      expect(skip.skippable?(handler, 'base', seed_files)).to eql(false)
    end

    it 'never skips when the driver has no data version' do
      handler.supported = false
      skip.installed!(handler, 'base', seed_files)
      expect(skip.skippable?(handler, 'base', seed_files)).to eql(false)
    end

    describe '.current' do
      around do |example|
        before = ENV['DBAGENT_SEED_SKIP_UNCHANGED']
        example.run
      ensure
        ENV['DBAGENT_SEED_SKIP_UNCHANGED'] = before
      end

      it 'is off by default' do
        ENV.delete('DBAGENT_SEED_SKIP_UNCHANGED')
        expect(SeedSkip.current.skippable?(handler, 'base', seed_files)).to eql(false)
      end

      it 'is on with DBAGENT_SEED_SKIP_UNCHANGED=true' do
        ENV['DBAGENT_SEED_SKIP_UNCHANGED'] = 'true'
        expect(SeedSkip.current).to be_a(SeedSkip)
      end
    end

  end
end
