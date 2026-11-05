require 'spec_helper'

module DbAgent
  describe "DbAgent.flag?" do

    it 'defaults to true on a missing or empty value' do
      expect(DbAgent.flag?(nil)).to eql(true)
      expect(DbAgent.flag?("")).to eql(true)
      expect(DbAgent.flag?("  ")).to eql(true)
    end

    it 'honors the provided default on a missing or empty value' do
      expect(DbAgent.flag?(nil, false)).to eql(false)
      expect(DbAgent.flag?("", false)).to eql(false)
    end

    it 'recognizes the falsy spellings, whatever the case' do
      %w[false 0 no off FALSE No OFF].each do |value|
        expect(DbAgent.flag?(value)).to eql(false), "expected #{value} to be falsy"
      end
    end

    it 'takes anything else for true' do
      %w[true 1 yes on whatever].each do |value|
        expect(DbAgent.flag?(value)).to eql(true), "expected #{value} to be truthy"
      end
    end

    it 'strips the value before matching' do
      expect(DbAgent.flag?(" false ")).to eql(false)
    end

  end
end
