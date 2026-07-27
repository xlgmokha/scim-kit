# frozen_string_literal: true

RSpec.describe Scim::Kit::Cli::ScimSchemaConverter do
  describe '.convert' do
    context 'with a string attribute' do
      let(:schema) { { attributes: [{ name: 'userName', type: 'string' }] } }
      let(:expected_schema) do
        {
          'type' => 'object',
          'properties' => { 'userName' => { 'type' => 'string' } },
          'required' => [],
          'additionalProperties' => false
        }
      end

      it 'maps a string attribute' do
        result = described_class.convert(schema)

        expect(result).to eql(expected_schema)
      end
    end

    context 'with a required attribute' do
      let(:schema) do
        {
          attributes: [
            { name: 'userName', type: 'string', required: true }
          ]
        }
      end

      it 'marks required attributes' do
        result = described_class.convert(schema)

        expect(result['required']).to eql(['userName'])
      end
    end

    context 'with a multiValued attribute' do
      let(:schema) do
        {
          attributes: [
            { name: 'emails', type: 'string', multiValued: true }
          ]
        }
      end

      it 'wraps multiValued attributes in an array schema' do
        result = described_class.convert(schema)

        expect(result['properties']['emails']).to eql('type' => 'array', 'items' => { 'type' => 'string' })
      end
    end

    context 'with canonicalValues' do
      let(:schema) do
        {
          attributes: [
            { name: 'type', type: 'string', canonicalValues: %w[work home] }
          ]
        }
      end

      it 'maps canonicalValues to enum' do
        result = described_class.convert(schema)

        expect(result['properties']['type']).to eql('type' => 'string', 'enum' => %w[work home])
      end
    end

    context 'with a complex attribute containing subAttributes' do
      let(:schema) do
        {
          attributes: [
            {
              name: 'name', type: 'complex',
              subAttributes: [
                { name: 'givenName', type: 'string', required: true },
                { name: 'familyName', type: 'string' }
              ]
            }
          ]
        }
      end
      let(:expected_name_schema) do
        {
          'type' => 'object',
          'properties' => {
            'givenName' => { 'type' => 'string' },
            'familyName' => { 'type' => 'string' }
          },
          'required' => ['givenName'],
          'additionalProperties' => false
        }
      end

      it 'maps complex attributes with nested subAttributes' do
        result = described_class.convert(schema)

        expect(result['properties']['name']).to eql(expected_name_schema)
      end
    end

    context 'with every scalar SCIM type' do
      let(:types) do
        {
          'boolean' => { 'type' => 'boolean' },
          'decimal' => { 'type' => 'number' },
          'integer' => { 'type' => 'integer' },
          'dateTime' => { 'type' => 'string', 'format' => 'date-time' },
          'reference' => { 'type' => 'string' },
          'binary' => { 'type' => 'string' }
        }
      end

      it 'maps every scalar SCIM type to its JSON Schema equivalent' do
        types.each do |scim_type, json_schema|
          schema = { attributes: [{ name: 'x', type: scim_type }] }
          result = described_class.convert(schema)

          expect(result['properties']['x']).to eql(json_schema)
        end
      end
    end

    it 'defaults to no attributes when attributes is missing' do
      result = described_class.convert({})

      expect(result['properties']).to eql({})
    end
  end
end
