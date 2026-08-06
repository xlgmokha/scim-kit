# frozen_string_literal: true

RSpec.describe Scim::Kit::V2::CanonicalKeys do
  let(:schema) do
    {
      'type' => 'object',
      'properties' => {
        'userName' => { 'type' => 'string' },
        'name' => {
          'type' => 'object',
          'properties' => { 'givenName' => { 'type' => 'string' } }
        },
        'emails' => {
          'type' => 'array',
          'items' => {
            'type' => 'object',
            'properties' => { 'value' => { 'type' => 'string' } }
          }
        }
      }
    }
  end

  describe '.apply' do
    it 'renames an upcased key to the declared spelling' do
      expect(described_class.apply(schema, 'USERNAME' => 'mo'))
        .to eql('userName' => 'mo')
    end

    it 'renames a downcased key to the declared spelling' do
      expect(described_class.apply(schema, 'username' => 'mo'))
        .to eql('userName' => 'mo')
    end

    it 'leaves a canonical key alone' do
      expect(described_class.apply(schema, 'userName' => 'mo'))
        .to eql('userName' => 'mo')
    end

    it 'renames nested sub-attributes' do
      result = described_class.apply(schema, 'NAME' => { 'GIVENNAME' => 'mo' })

      expect(result).to eql('name' => { 'givenName' => 'mo' })
    end

    it 'renames keys inside array items' do
      result = described_class.apply(schema, 'EMAILS' => [{ 'VALUE' => 'a@b' }])

      expect(result).to eql('emails' => [{ 'value' => 'a@b' }])
    end

    it 'passes undeclared vendor keys through untouched' do
      result = described_class.apply(schema, 'urn:vendor:X' => { 'A' => 1 })

      expect(result).to eql('urn:vendor:X' => { 'A' => 1 })
    end

    it 'leaves values alone' do
      expect(described_class.apply(schema, 'USERNAME' => 'MiXeD'))
        .to eql('userName' => 'MiXeD')
    end

    it 'returns non-object data unchanged' do
      expect(described_class.apply(schema, 'nope')).to eql('nope')
    end

    it 'returns data unchanged when the schema declares no properties' do
      expect(described_class.apply({ 'type' => 'object' }, 'A' => 1))
        .to eql('A' => 1)
    end
  end
end
