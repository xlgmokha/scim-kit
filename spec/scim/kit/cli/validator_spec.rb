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

    it 'returns a readable error for an undeclared property' do
      errors = described_class.errors_for(schema, { userName: 'bjensen', extra: true })

      expect(errors).to eql(["property '/extra' is invalid: error_type=schema"])
    end
  end
end
