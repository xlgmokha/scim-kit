# frozen_string_literal: true

RSpec.describe Scim::Kit::Cli::SchemaRegistry do
  describe '.fetch' do
    it 'loads the service_provider_configuration schema' do
      schema = described_class.fetch(:service_provider_configuration)

      expect(schema['required']).to include('patch', 'bulk')
    end

    it 'expects resource_types wrapped in a ListResponse envelope' do
      schema = described_class.fetch(:resource_types)

      expect(schema['required']).to include('totalResults', 'Resources')
    end

    it 'validates resource_type items inside the envelope' do
      schema = described_class.fetch(:resource_types)

      items = schema['properties']['Resources']['items']
      expect(items['required']).to include('endpoint')
    end

    it 'expects schemas wrapped in a ListResponse envelope' do
      schema = described_class.fetch(:schemas)

      expect(schema['required']).to include('totalResults', 'Resources')
    end

    it 'validates schema items inside the envelope' do
      schema = described_class.fetch(:schemas)

      items = schema['properties']['Resources']['items']
      expect(items['required']).to include('attributes')
    end
  end

  describe 'service_provider_configuration schema' do
    let(:config) do
      {
        schemas: [
          'urn:ietf:params:scim:schemas:core:2.0:ServiceProviderConfig'
        ],
        patch: { supported: true },
        bulk: { supported: false, maxOperations: 0, maxPayloadSize: 0 },
        filter: { supported: false, maxResults: 0 },
        changePassword: { supported: false },
        sort: { supported: false },
        etag: { supported: false },
        authenticationSchemes: [
          {
            type: 'oauthbearertoken', name: 'OAuth Bearer Token',
            description: 'desc', primary: true
          }
        ]
      }
    end

    it 'accepts a primary flag on authentication schemes' do
      schema = described_class.fetch(:service_provider_configuration)

      errors = Scim::Kit::Cli::Validator.errors_for(schema, config)

      expect(errors).to be_empty
    end
  end

  describe '.list_response_with_items' do
    it 'injects the given schema as the Resources items schema' do
      item_schema = { 'type' => 'object' }

      schema = described_class.list_response_with_items(item_schema)

      expect(schema['properties']['Resources']['items']).to eql(item_schema)
    end

    it 'returns independent schema objects across calls' do
      first = described_class.list_response_with_items({ 'type' => 'object' })
      first['properties']['Resources']['items']['type'] = 'mutated'

      second = described_class.list_response_with_items({ 'type' => 'string' })

      expect(second['properties']['Resources']['items']).to eql('type' => 'string')
    end
  end

  describe 'built-in schemas are valid JSON Schema documents' do
    it 'validates service_provider_configuration' do
      schema = described_class.fetch(:service_provider_configuration)

      expect(JSONSchemer.valid_schema?(schema)).to be(true)
    end

    it 'validates resource_types' do
      schema = described_class.fetch(:resource_types)

      expect(JSONSchemer.valid_schema?(schema)).to be(true)
    end

    it 'validates schemas' do
      schema = described_class.fetch(:schemas)

      expect(JSONSchemer.valid_schema?(schema)).to be(true)
    end

    it 'validates list_response' do
      schema = described_class.list_response_with_items({})

      expect(JSONSchemer.valid_schema?(schema)).to be(true)
    end
  end
end
