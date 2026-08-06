# frozen_string_literal: true

RSpec.describe Scim::Kit::Cli::ResourceSchemaResolver do
  subject { described_class.new(Scim::Kit::Cli::Client.new(base_url)) }

  let(:base_url) { FFaker::Internet.uri('https') }
  let(:core_urn) { 'urn:ietf:params:scim:schemas:core:2.0:User' }
  let(:extension_urn) { 'urn:ietf:params:scim:schemas:extension:enterprise:2.0:User' }
  let(:resource_type) { { id: 'User', name: 'User', endpoint: '/Users', schema: core_urn, schemaExtensions: [{ schema: extension_urn, required: true }] } }
  let(:core_schema) { { id: core_urn, attributes: [{ name: 'userName', type: 'string', required: true }] } }
  let(:extension_schema) { { id: extension_urn, attributes: [{ name: 'employeeNumber', type: 'string' }] } }

  describe '#schema_for' do
    let(:schema) { subject.schema_for(resource_type) }
    let(:resource) { { schemas: [core_urn], id: '1', userName: 'mo', meta: { resourceType: 'User' }, extension_urn => { employeeNumber: '1' } } }

    def errors_for(body)
      Scim::Kit::V2::JsonSchema.new(schema).errors_for(body)
    end

    context 'when the core and extension schemas are both found' do
      let(:expected_extension_schema) do
        {
          'type' => 'object',
          'properties' => { 'employeeNumber' => { 'type' => 'string' } },
          'required' => []
        }
      end

      before do
        stub_request(:get, "#{base_url}/Schemas").to_return(status: 200, body: [core_schema, extension_schema].to_json)
      end

      specify { expect(schema['properties']['userName']).to eql('type' => 'string') }
      specify { expect(schema['required']).to include('userName') }
      specify { expect(schema['properties']).to include('id', 'meta', 'schemas') }
      specify { expect(schema['properties'][extension_urn]).to eql(expected_extension_schema) }
      specify { expect(schema['required']).to include(extension_urn) }
      specify { expect(errors_for(resource.merge('urn:vendor:custom' => { a: true }))).to be_empty }
      specify { expect(errors_for(userName: 'mo')).to include(/missing required keys.*schemas/) }
      specify { expect(errors_for(userName: 'mo')).to include(/missing required keys.*id/) }
      specify { expect(errors_for(resource.merge(meta: { version: '123' }))).not_to be_empty }
      specify { expect(errors_for(resource.merge(meta: { version: 'W/"123"' }))).to be_empty }
      specify { expect(errors_for(resource.merge(schemas: []))).not_to be_empty }
      specify { expect(errors_for(resource.merge(schemas: ['urn:x']))).not_to be_empty }
      specify { expect(errors_for(resource.merge(schemas: [core_urn, extension_urn]))).to be_empty }
      specify { expect(errors_for(resource.merge(meta: { location: '/Users/1' }))).to be_empty }
    end

    context 'when the resource type is ResourceType' do
      let(:core_schema) { { id: resource_type_urn, attributes: [{ name: 'name', type: 'string', required: true }] } }
      let(:resource_type) { { id: 'ResourceType', name: 'ResourceType', endpoint: '/ResourceTypes', schema: resource_type_urn } }
      let(:resource_type_urn) { 'urn:ietf:params:scim:schemas:core:2.0:ResourceType' }

      before do
        stub_request(:get, "#{base_url}/Schemas").to_return(status: 200, body: [core_schema].to_json)
      end

      specify { expect(errors_for(schemas: [resource_type_urn], name: 'User')).to be_empty }
    end

    context 'when the resource type declares an extension /Schemas omits' do
      before do
        stub_request(:get, "#{base_url}/Schemas").to_return(status: 200, body: [core_schema].to_json)
      end

      it 'records the undeclared extension URN' do
        subject.schema_for(resource_type)

        expect(subject.undeclared_extensions).to eql([extension_urn])
      end

      it { expect(errors_for(resource)).to be_empty }
    end

    context 'when the extension schema is not found' do
      let(:schema) { subject.schema_for(resource_type) }

      before do
        stub_request(:get, "#{base_url}/Schemas").to_return(status: 200, body: [core_schema].to_json)
      end

      specify { expect(schema['properties']).to include('userName') }
      specify { expect(schema['properties']).not_to include(extension_urn) }
    end

    context 'when the core schema is not found' do
      before do
        stub_request(:get, "#{base_url}/Schemas").to_return(status: 200, body: [extension_schema].to_json)
      end

      specify { expect(subject.schema_for(resource_type)).to be_nil }
    end

    context 'when the /Schemas request fails' do
      before do
        stub_request(:get, "#{base_url}/Schemas").to_return(status: 500, body: '{}')
      end

      specify { expect(subject.schema_for(resource_type)).to be_nil }
    end

    context 'when the resource type has no extensions' do
      let(:resource_type) { { id: 'User', name: 'User', endpoint: '/Users', schema: core_urn } }

      before do
        stub_request(:get, "#{base_url}/Schemas").to_return(status: 200, body: [core_schema].to_json)
      end

      specify { expect(schema['properties'].keys).to match_array(%w[schemas id externalId meta userName]) }
    end

    context 'when /Schemas returns a ListResponse envelope' do
      let(:resource_type) { { id: 'User', name: 'User', endpoint: '/Users', schema: core_urn } }

      before do
        stub_request(:get, "#{base_url}/Schemas").to_return(
          status: 200,
          body: {
            schemas: ['urn:ietf:params:scim:api:messages:2.0:ListResponse'],
            totalResults: 1,
            Resources: [core_schema]
          }.to_json
        )
      end

      specify { expect(subject.schema_for(resource_type)['properties']).to include('userName') }
    end
  end
end
