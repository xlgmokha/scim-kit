# frozen_string_literal: true

RSpec.describe Scim::Kit::Cli::Validator do
  describe '.errors_for' do
    let(:schema) do
      {
        'type' => 'object',
        'properties' => { 'userName' => { 'type' => 'string' } },
        'required' => ['userName'],
        'additionalProperties' => false
      }
    end

    it 'returns an empty array for a valid document' do
      errors = described_class.errors_for(schema, { userName: 'bjensen' })

      expect(errors).to eql([])
    end

    it 'returns a readable error for a missing required property' do
      errors = described_class.errors_for(schema, {})

      expect(errors).to eql(['root is missing required keys: userName'])
    end

    it 'returns a readable error for a wrong type' do
      errors = described_class.errors_for(schema, { userName: 1 })

      expect(errors).to eql(["property '/userName' is not of type: string"])
    end

    context 'with an optional attribute' do
      let(:schema) do
        {
          'type' => 'object',
          'properties' => {
            'userName' => { 'type' => 'string' },
            'externalId' => { 'type' => 'string' }
          },
          'required' => ['userName']
        }
      end

      it 'accepts null, which RFC 7643 2.5 makes equivalent to unassigned' do
        errors = described_class.errors_for(
          schema, { userName: 'bjensen', externalId: nil }
        )

        expect(errors).to eql([])
      end

      it 'still reports a wrong type' do
        errors = described_class.errors_for(
          schema, { userName: 'bjensen', externalId: 1 }
        )

        expect(errors).to eql(["property '/externalId' is not of type: string"])
      end
    end

    it 'reports null for a required attribute as unassigned' do
      errors = described_class.errors_for(schema, { userName: nil })

      expect(errors).to eql(['root is missing required keys: userName'])
    end

    context 'with an optional attribute behind a $ref' do
      let(:schema) do
        {
          'type' => 'object',
          'properties' => { 'meta' => { '$ref' => '#/$defs/meta' } },
          '$defs' => {
            'meta' => {
              'type' => 'object',
              'properties' => { 'version' => { 'type' => 'string' } }
            }
          }
        }
      end

      it 'reports only the error the server actually made' do
        errors = described_class.errors_for(schema, { meta: { version: 1 } })

        expect(errors).to eql(
          ["property '/meta/version' is not of type: string"]
        )
      end
    end

    it 'accepts a declared attribute the server spelled differently' do
      errors = described_class.errors_for(schema, { USERNAME: 'bjensen' })

      expect(errors).to eql([])
    end

    it 'reports the canonical name when a differently spelled value is wrong' do
      errors = described_class.errors_for(schema, { USERNAME: 1 })

      expect(errors).to eql(["property '/userName' is not of type: string"])
    end

    it 'returns a readable error for an undeclared property' do
      errors = described_class.errors_for(schema, { userName: 'bjensen', extra: true })

      expect(errors).to eql(["property '/extra' is invalid: error_type=schema"])
    end
  end
end
