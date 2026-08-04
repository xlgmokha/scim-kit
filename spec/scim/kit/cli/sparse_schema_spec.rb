# frozen_string_literal: true

RSpec.describe Scim::Kit::Cli::SparseSchema do
  describe '.relax' do
    let(:schema) do
      {
        'type' => 'object',
        'properties' => {
          'schemas' => { 'type' => 'array', 'items' => { 'type' => 'string' } },
          'id' => { 'type' => 'string' },
          'userName' => { 'type' => 'string' },
          'meta' => {
            'type' => 'object',
            'properties' => { 'resourceType' => { 'type' => 'string' } },
            'required' => ['resourceType']
          },
          'emails' => {
            'type' => 'array',
            'items' => {
              'type' => 'object',
              'properties' => {
                'value' => { 'type' => 'string' },
                'required' => { 'type' => 'boolean' }
              },
              'required' => ['value']
            }
          }
        },
        'required' => %w[schemas id userName]
      }
    end

    it 'requires only the always-returned attributes' do
      expect(described_class.relax(schema)['required']).to eql(%w[schemas id])
    end

    it 'strips required from nested objects' do
      relaxed = described_class.relax(schema)

      expect(relaxed['properties']['meta']).not_to include('required')
    end

    it 'strips required from array items' do
      relaxed = described_class.relax(schema)

      expect(relaxed['properties']['emails']['items'])
        .not_to include('required')
    end

    it 'keeps a sub-attribute named required' do
      relaxed = described_class.relax(schema)

      expect(relaxed['properties']['emails']['items']['properties'])
        .to include('required' => { 'type' => 'boolean' })
    end

    it 'leaves the original schema untouched' do
      described_class.relax(schema)

      expect(schema['required']).to eql(%w[schemas id userName])
    end

    it 'keeps type constraints' do
      relaxed = described_class.relax(schema)

      expect(relaxed['properties']['userName']).to eql('type' => 'string')
    end

    it 'accepts a resource carrying only the requested attributes' do
      errors = Scim::Kit::Cli::Validator.errors_for(
        described_class.relax(schema), schemas: ['urn:x'], id: '1'
      )

      expect(errors).to be_empty
    end
  end
end
