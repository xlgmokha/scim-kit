# frozen_string_literal: true

RSpec.describe Scim::Kit::Cli::SchemaRegistry do
  describe '.fetch' do
    it 'loads the service_provider_configuration schema' do
      schema = described_class.fetch(:service_provider_configuration)

      expect(schema['required']).to include('patch', 'bulk')
    end

    it 'loads the resource_types schema' do
      schema = described_class.fetch(:resource_types)

      expect(schema['items']['required']).to include('endpoint')
    end

    it 'loads the schemas schema' do
      schema = described_class.fetch(:schemas)

      expect(schema['items']['required']).to include('attributes')
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
