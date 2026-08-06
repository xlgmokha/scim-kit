# frozen_string_literal: true

RSpec.describe Scim::Kit::V2::JsonSchema do
  let(:config) do
    {
      schemas: ['urn:ietf:params:scim:schemas:core:2.0:ServiceProviderConfig'],
      patch: { supported: true },
      bulk: { supported: false, maxOperations: 0, maxPayloadSize: 0 },
      filter: { supported: false, maxResults: 0 },
      changePassword: { supported: false },
      sort: { supported: false },
      etag: { supported: false },
      authenticationSchemes: [
        { type: 'oauthbearertoken', name: 'OAuth Bearer Token',
          description: 'desc', primary: true }
      ]
    }
  end
  let(:list_urn) { 'urn:ietf:params:scim:api:messages:2.0:ListResponse' }

  describe '#errors_for' do
    let(:schema) do
      {
        'type' => 'object',
        'properties' => { 'userName' => { 'type' => 'string' } },
        'required' => ['userName'],
        'additionalProperties' => false
      }
    end

    it 'returns an empty array for a valid document' do
      errors = described_class.new(schema).errors_for({ userName: 'bjensen' })

      expect(errors).to eql([])
    end

    it 'returns a readable error for a missing required property' do
      errors = described_class.new(schema).errors_for({})

      expect(errors).to eql(['root is missing required keys: userName'])
    end

    it 'returns a readable error for a wrong type' do
      errors = described_class.new(schema).errors_for({ userName: 1 })

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
        errors = described_class.new(schema).errors_for({ userName: 'bjensen', externalId: nil })

        expect(errors).to eql([])
      end

      it 'still reports a wrong type' do
        errors = described_class.new(schema).errors_for({ userName: 'bjensen', externalId: 1 })

        expect(errors).to eql(["property '/externalId' is not of type: string"])
      end
    end

    it 'reports null for a required attribute as unassigned' do
      errors = described_class.new(schema).errors_for({ userName: nil })

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
        errors = described_class.new(schema).errors_for({ meta: { version: 1 } })

        expect(errors).to eql(
          ["property '/meta/version' is not of type: string"]
        )
      end
    end

    it 'accepts a declared attribute the server spelled differently' do
      errors = described_class.new(schema).errors_for({ USERNAME: 'bjensen' })

      expect(errors).to eql([])
    end

    it 'reports the canonical name when a differently spelled value is wrong' do
      errors = described_class.new(schema).errors_for({ USERNAME: 1 })

      expect(errors).to eql(["property '/userName' is not of type: string"])
    end

    it 'returns a readable error for an undeclared property' do
      errors = described_class.new(schema).errors_for({ userName: 'bjensen', extra: true })

      expect(errors).to eql(["property '/extra' is invalid: error_type=schema"])
    end
  end

  def errors_for(key, document)
    described_class.fetch(key).errors_for(document)
  end

  def list_document(*resources)
    { schemas: [list_urn], totalResults: resources.length,
      Resources: resources }
  end

  describe '.fetch' do
    specify { expect(errors_for(:service_provider_configuration, config)).to be_empty }
    specify { expect(errors_for(:service_provider_configuration, {})).to include(/missing required keys.*patch/) }
    specify { expect(errors_for(:resource_types, {})).to include(/missing required keys.*totalResults/) }
    specify { expect(errors_for(:schemas, {})).to include(/missing required keys.*totalResults/) }

    it 'validates each ResourceType inside the envelope' do
      entry = { schemas: ['urn:ietf:params:scim:schemas:core:2.0:ResourceType'],
                name: 'User', schema: 'urn:x' }

      expect(errors_for(:resource_types, list_document(entry)))
        .to include(%r{/Resources/0.*missing required keys.*endpoint})
    end

    it 'validates each Schema inside the envelope' do
      entry = { schemas: ['urn:ietf:params:scim:schemas:core:2.0:Schema'],
                id: 'urn:x' }

      expect(errors_for(:schemas, list_document(entry)))
        .to include(%r{/Resources/0.*missing required keys.*attributes})
    end

    it 'raises for an unknown document' do
      expect { described_class.fetch(:nope) }.to raise_error(KeyError)
    end
  end

  describe '.definition' do
    specify { expect(described_class.definition('meta')['properties']).to include('version') }
    specify { expect { described_class.definition('nope') }.to raise_error(KeyError) }
  end

  describe '.list_of' do
    def list_errors(item_schema, *resources)
      described_class.list_of(item_schema).errors_for(list_document(*resources))
    end

    specify { expect(list_errors({ 'type' => 'object' }, { a: 1 })).to be_empty }
    specify { expect(list_errors({ 'type' => 'object' }, 'x')).to include(%r{/Resources/0}) }

    it 'does not leak a mutated document into the next call' do
      described_class.list_of('type' => 'object').to_h['$defs'].clear

      expect(list_errors({ 'type' => 'object' }, { a: 1 })).to be_empty
    end
  end

  describe 'the bundled document' do
    specify { expect(JSONSchemer.valid_schema?(described_class.fetch(:error).to_h)).to be(true) }
    specify { expect(JSONSchemer.valid_schema?(described_class.fetch(:schemas).to_h)).to be(true) }
    specify { expect(JSONSchemer.valid_schema?(described_class.fetch(:resource_types).to_h)).to be(true) }
    specify { expect(JSONSchemer.valid_schema?(described_class.fetch(:service_provider_configuration).to_h)).to be(true) }
    specify { expect(JSONSchemer.valid_schema?(described_class.list_of({}).to_h)).to be(true) }
  end
end
