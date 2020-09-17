require 'spec_helper'

module DbAgent
  describe TableOrderer do

    subject {
      db = DbAgent::SEQUEL_DATABASE
      TableOrderer.new(db)
    }

    it 'has a tsort that returns table in order, least dependent first' do
      tsort = subject.tsort
      expect(tsort.index(:supplies) > tsort.index(:parts)).to eql(true)
      expect(tsort.index(:supplies) > tsort.index(:suppliers)).to eql(true)
    end

    it 'lets get all dependencies of a given table' do
      s = subject
      expect(s.dependencies(:supplies)).to eql([])
      expect(s.dependencies(:parts)).to eql([:supplies])
    end

  end
end
