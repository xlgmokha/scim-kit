# frozen_string_literal: true

RSpec.describe Scim::Kit::Cli::ResourceSchemaResolver do
  subject { described_class.new(Scim::Kit::Http.new, base_url, headers: {}) }

  let(:base_url) { FFaker::Internet.uri('https') }
  let(:core_urn) { 'urn:ietf:params:scim:schemas:core:2.0:User' }
  let(:extension_urn) do
    'urn:ietf:params:scim:schemas:extension:enterprise:2.0:User'
  end

  let(:resource_type) do
    {
      id: 'User', name: 'User', endpoint: '/Users', schema: core_urn,
      schemaExtensions: [{ schema: extension_urn, required: true }]
    }
  end

  let(:core_schema) do
    {
      id: core_urn,
      attributes: [{ name: 'userName', type: 'string', required: true }]
    }
  end

  let(:extension_schema) do
    {
      id: extension_urn,
      attributes: [{ name: 'employeeNumber', type: 'string' }]
    }
  end

  describe '#schema_for' do
    context 'when the core and extension schemas are both found' do
      let(:schema) { subject.schema_for(resource_type) }
      let(:expected_extension_schema) do
        {
          'type' => 'object',
          'properties' => { 'employeeNumber' => { 'type' => 'string' } },
          'required' => [],
          'additionalProperties' => false
        }
      end

      before do
        stub_request(:get, "#{base_url}/Schemas").to_return(
          status: 200, body: [core_schema, extension_schema].to_json
        )
      end

      it 'includes the core attributes at the top level' do
        expect(schema['properties']['userName']).to eql('type' => 'string')
      end

      it 'includes userName in the required list' do
        expect(schema['required']).to include('userName')
      end

      it 'includes common attributes' do
        expect(schema['properties']).to include('id', 'meta', 'schemas')
      end

      it 'nests extension attributes under the extension URN' do
        expect(schema['properties'][extension_urn]).to eql(expected_extension_schema)
      end

      it 'requires the extension URN when the extension is required' do
        expect(schema['required']).to include(extension_urn)
      end

      it 'disallows undeclared top-level properties' do
        expect(schema['additionalProperties']).to be(false)
      end
    end

    context 'when the extension schema is not found' do
      let(:schema) { subject.schema_for(resource_type) }

      before do
        stub_request(:get, "#{base_url}/Schemas")
          .to_return(status: 200, body: [core_schema].to_json)
      end

      it 'includes the core attributes' do
        expect(schema['properties']).to include('userName')
      end

      it 'excludes the extension URN from the properties' do
        expect(schema['properties']).not_to include(extension_urn)
      end
    end

    context 'when the core schema is not found' do
      before do
        stub_request(:get, "#{base_url}/Schemas")
          .to_return(status: 200, body: [extension_schema].to_json)
      end

      it 'returns nil' do
        expect(subject.schema_for(resource_type)).to be_nil
      end
    end

    context 'when the /Schemas request fails' do
      before do
        stub_request(:get, "#{base_url}/Schemas")
          .to_return(status: 500, body: '{}')
      end

      it 'returns nil' do
        expect(subject.schema_for(resource_type)).to be_nil
      end
    end

    context 'when the resource type has no extensions' do
      let(:resource_type) do
        { id: 'User', name: 'User', endpoint: '/Users', schema: core_urn }
      end

      before do
        stub_request(:get, "#{base_url}/Schemas")
          .to_return(status: 200, body: [core_schema].to_json)
      end

      it 'returns a schema without extension properties' do
        schema = subject.schema_for(resource_type)

        expect(schema['properties'].keys).to match_array(
          %w[schemas id externalId meta userName]
        )
      end
    end
  end
end
