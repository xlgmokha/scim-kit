# frozen_string_literal: true

RSpec.describe Scim::Kit::V2::Conformance do
  subject { described_class.new(configuration) }

  let(:configuration) { Scim::Kit::V2::Configuration.new }
  let(:base_url) { FFaker::Internet.uri('https') }
  let(:user_urn) { Scim::Kit::V2::Schemas::USER }

  describe 'a resource against the schema its server advertises' do
    let(:schema) do
      Scim::Kit::V2::Schema.build(id: user_urn, name: 'User', location: base_url) do |x|
        x.add_attribute(name: 'userName') { |y| y.required = true }
      end
    end
    let(:resource_type) do
      Scim::Kit::V2::ResourceType.build(location: base_url) do |x|
        x.id = 'User'
        x.name = 'User'
        x.endpoint = '/Users'
        x.schema = user_urn
      end
    end
    let(:extended) do
      Scim::Kit::V2::ResourceType.build(location: base_url) do |x|
        x.name = 'User'
        x.schema = user_urn
        x.add_schema_extension(schema: 'urn:vendor:2.0:Thing', required: true)
      end
    end
    let(:unknown_type) do
      Scim::Kit::V2::ResourceType.build(location: base_url) do |x|
        x.name = 'Nope'
        x.schema = 'urn:nope'
      end
    end
    let(:resource) { { schemas: [user_urn], id: '1', userName: 'mo' } }

    before do
      configuration.schemas[schema.id] = schema
      configuration.resource_types[resource_type.id] = resource_type
    end

    def errors_for(body, **options)
      subject.resource_errors(body, resource_type: resource_type, **options)
    end

    specify { expect(errors_for(resource)).to be_empty }
    specify { expect(errors_for({ schemas: [user_urn], id: '1' })).to include(/userName/) }
    specify { expect(errors_for({ schemas: [user_urn], userName: 'mo' })).to include(/id/) }
    specify { expect(errors_for(resource.merge(schemas: ['urn:x']))).not_to be_empty }
    specify { expect(errors_for({ schemas: [user_urn], id: '1' }, sparse: true)).to be_empty }

    # Nil is "I could not check this", which is not "nothing was wrong".
    specify { expect(subject.resource_errors(resource, resource_type: unknown_type)).to be_nil }

    # RFC 7643 6: "If true, a resource of this type MUST include this schema
    # extension." Whether the server published its definition is irrelevant.
    it 'requires a declared extension even when /Schemas omits it' do
      errors = subject.resource_errors(resource, resource_type: extended)

      expect(errors).to include(/urn:vendor:2.0:Thing/)
    end

    describe 'a list response' do
      let(:list) do
        { schemas: [Scim::Kit::V2::Messages::LIST_RESPONSE],
          totalResults: 1, Resources: [resource] }
      end

      specify { expect(errors_for(list, list: true)).to be_empty }
      specify { expect(errors_for(list.merge(Resources: [{ id: '1' }]), list: true)).not_to be_empty }
      specify { expect(errors_for(list.merge(totalResults: nil), list: true)).to include(/totalResults/) }
    end
  end

  describe '#discovery_errors' do
    let(:spc) do
      { schemas: [Scim::Kit::V2::Schemas::SERVICE_PROVIDER_CONFIGURATION],
        patch: { supported: true },
        bulk: { supported: false, maxOperations: 0, maxPayloadSize: 0 },
        filter: { supported: false, maxResults: 0 },
        changePassword: { supported: false }, sort: { supported: false },
        etag: { supported: false }, authenticationSchemes: [] }
    end
    let(:schema_document) do
      { schemas: [Scim::Kit::V2::Schemas::SCHEMA], id: user_urn,
        name: 'User', attributes: [] }
    end
    let(:resource_type_document) do
      { schemas: [Scim::Kit::V2::Schemas::RESOURCE_TYPE], id: 'User',
        name: 'User', endpoint: '/Users', schema: user_urn }
    end

    def envelope(*resources)
      { schemas: [Scim::Kit::V2::Messages::LIST_RESPONSE],
        totalResults: resources.length, Resources: resources }
    end

    def body(resource_types: resource_type_document, schemas: schema_document)
      { service_provider_configuration: spc,
        schemas: envelope(schemas), resource_types: envelope(resource_types) }
    end

    specify { expect(subject.discovery_errors(body)).to eql({}) }

    it 'reports a document that does not conform' do
      errors = subject.discovery_errors(body.merge(service_provider_configuration: {}))

      expect(errors[:service_provider_configuration]).to include(/patch/)
    end

    # Neither document is wrong on its own; together they contradict.
    context 'when a resource type declares an extension /Schemas omits' do
      let(:extended) do
        resource_type_document.merge(
          schemaExtensions: [{ schema: 'urn:vendor:2.0:Thing', required: true }]
        )
      end
      let(:published) do
        { schemas: [Scim::Kit::V2::Schemas::SCHEMA],
          id: 'urn:vendor:2.0:Thing', name: 'Thing', attributes: [] }
      end
      let(:agreeing) do
        { service_provider_configuration: spc,
          schemas: envelope(schema_document, published),
          resource_types: envelope(extended) }
      end

      specify { expect(subject.discovery_errors(body(resource_types: extended))[:resource_types]).to include(/urn:vendor:2.0:Thing/) }
      specify { expect(subject.discovery_errors(agreeing)).to eql({}) }
    end
  end
end
