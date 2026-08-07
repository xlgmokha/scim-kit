# frozen_string_literal: true

RSpec.describe Scim::Kit::V2::Configuration do
  subject do
    described_class.new do |x|
      x.service_provider_configuration(location: sp_location) do |y|
        y.add_authentication(:oauthbearertoken)
        y.change_password.supported = true
      end
      x.resource_type(id: 'User', location: user_type_location) do |y|
        y.schema = Scim::Kit::V2::Schemas::USER
      end
      x.resource_type(id: 'Group', location: group_type_location) do |y|
        y.schema = Scim::Kit::V2::Schemas::GROUP
      end
      x.schema(id: 'User', name: 'User', location: user_schema_location) do |y|
        y.add_attribute(name: 'userName')
      end
    end
  end

  let(:sp_location) { FFaker::Internet.uri('https') }
  let(:user_type_location) { FFaker::Internet.uri('https') }
  let(:group_type_location) { FFaker::Internet.uri('https') }
  let(:user_schema_location) { FFaker::Internet.uri('https') }

  specify { expect(subject.service_provider_configuration.meta.location).to eql(sp_location) }
  specify { expect(subject.service_provider_configuration.authentication_schemes[0].type).to be(:oauthbearertoken) }
  specify { expect(subject.service_provider_configuration.change_password.supported).to be(true) }

  specify { expect(subject.resource_types['User'].schema).to eql(Scim::Kit::V2::Schemas::USER) }
  specify { expect(subject.resource_types['User'].id).to eql('User') }
  specify { expect(subject.resource_types['Group'].schema).to eql(Scim::Kit::V2::Schemas::GROUP) }
  specify { expect(subject.resource_types['Group'].id).to eql('Group') }

  specify { expect(subject.schemas['User'].id).to eql('User') }
  specify { expect(subject.schemas['User'].name).to eql('User') }
  specify { expect(subject.schemas['User'].meta.location).to eql(user_schema_location) }
  specify { expect(subject.schemas['User'].attributes[0].name).to eql('user_name') }

  describe '#load_from' do
    let(:base_url) { FFaker::Internet.uri('https') }
    let(:service_provider_configuration) do
      Scim::Kit::V2::ServiceProviderConfiguration.new(location: FFaker::Internet.uri('https'))
    end
    let(:schema) do
      Scim::Kit::V2::Schema.new(id: 'User', name: 'User', location: FFaker::Internet.uri('https'))
    end
    let(:resource_type) do
      x = Scim::Kit::V2::ResourceType.new(location: FFaker::Internet.uri('https'))
      x.id = 'User'
      x
    end

    before do
      stub_request(:get, "#{base_url}/ServiceProviderConfig")
        .to_return(status: 200, body: service_provider_configuration.to_json)

      stub_request(:get, "#{base_url}/Schemas")
        .to_return(status: 200, body: [schema.to_h].to_json)

      stub_request(:get, "#{base_url}/ResourceTypes")
        .to_return(status: 200, body: [resource_type.to_h].to_json)

      subject.load_from(base_url)
    end

    specify { expect(subject.service_provider_configuration.to_h).to eql(service_provider_configuration.to_h) }
    specify { expect(subject.schemas[schema.id].to_h).to eql(schema.to_h) }
    specify { expect(subject.resource_types[resource_type.id].to_h).to eql(resource_type.to_h) }
  end

  describe 'lookups' do
    let(:base_url) { FFaker::Internet.uri('https') }
    let(:user_urn) { Scim::Kit::V2::Schemas::USER }
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

    before do
      subject.schemas[schema.id] = schema
      subject.resource_types[resource_type.id] = resource_type
    end

    # RFC 7643 2.1 makes attribute names case insensitive; the same courtesy
    # for a resource type name spares callers guessing the server's casing.
    specify { expect(subject.resource_type_for('User')).to eql(resource_type) }
    specify { expect(subject.resource_type_for('user')).to eql(resource_type) }
    specify { expect(subject.resource_type_for('USER')).to eql(resource_type) }
    specify { expect(subject.schema_for(user_urn)).to eql(schema) }
    specify { expect(subject.schema_for('urn:nope')).to be_nil }

    it 'names what it knows when a resource type is unknown' do
      expect { subject.resource_type_for('Nope') }
        .to raise_error(Scim::Kit::UnknownResourceType, /User/)
    end

    # A resource type declaring an extension that /Schemas never published
    # means the server's own discovery documents disagree.
    describe '#disagreements_for' do
      let(:extended) do
        Scim::Kit::V2::ResourceType.build(location: base_url) do |x|
          x.name = 'User'
          x.schema = user_urn
          x.add_schema_extension(schema: 'urn:vendor:2.0:Thing', required: true)
        end
      end

      specify { expect(subject.disagreements_for(resource_type)).to be_empty }
      specify { expect(subject.disagreements_for(extended)).to include(/urn:vendor:2.0:Thing/) }
      specify { expect(subject.disagreements_for(extended)).to include(%r{missing from /Schemas}) }

      it 'is empty once the extension is published' do
        subject.schemas['urn:vendor:2.0:Thing'] = Scim::Kit::V2::Schema.build(
          id: 'urn:vendor:2.0:Thing', name: 'Thing', location: base_url
        ) { |x| x.add_attribute(name: 'label') }

        expect(subject.disagreements_for(extended)).to be_empty
      end
    end

    describe '#json_schema_for' do
      let(:json_schema) { subject.json_schema_for(resource_type) }
      let(:resource) { { schemas: [user_urn], id: '1', userName: 'mo' } }

      let(:unknown_type) do
        Scim::Kit::V2::ResourceType.build(location: base_url) do |x|
          x.name = 'Nope'
          x.schema = 'urn:nope'
        end
      end

      specify { expect(json_schema.errors_for(resource)).to be_empty }
      specify { expect(json_schema.errors_for({ schemas: [user_urn], id: '1' })).to include(/userName/) }
      specify { expect(json_schema.errors_for({ schemas: [user_urn], userName: 'mo' })).to include(/id/) }
      specify { expect(json_schema.errors_for(resource.merge(schemas: ['urn:x']))).not_to be_empty }
      specify { expect(subject.json_schema_for(unknown_type)).to be_nil }

      it 'relaxes required attributes for a sparse response' do
        sparse = subject.json_schema_for(resource_type, sparse: true)

        expect(sparse.errors_for({ schemas: [user_urn], id: '1' })).to be_empty
      end
    end
  end

  # RFC 7644 4: /Schemas and /ResourceTypes SHALL use the ListResponse form,
  # though some servers return a bare array. Both are accepted.
  describe '#load_from with a ListResponse envelope' do
    let(:base_url) { FFaker::Internet.uri('https') }
    let(:schema) do
      Scim::Kit::V2::Schema.new(id: 'User', name: 'User', location: FFaker::Internet.uri('https'))
    end

    def envelope(*resources)
      { schemas: [Scim::Kit::V2::Messages::LIST_RESPONSE],
        totalResults: resources.length, Resources: resources }
    end

    before do
      stub_request(:get, "#{base_url}/ServiceProviderConfig")
        .to_return(status: 200, body: { schemas: [Scim::Kit::V2::Schemas::SERVICE_PROVIDER_CONFIGURATION] }.to_json)
      stub_request(:get, "#{base_url}/Schemas")
        .to_return(status: 200, body: envelope(schema.to_h).to_json)
      stub_request(:get, "#{base_url}/ResourceTypes")
        .to_return(status: 200, body: envelope.to_json)
    end

    specify { expect { subject.load_from(base_url) }.not_to raise_error }

    it 'reads the resources out of the envelope' do
      subject.load_from(base_url)

      expect(subject.schemas[schema.id].to_h).to eql(schema.to_h)
    end
  end

  describe '#load_from when the server fails' do
    let(:base_url) { FFaker::Internet.uri('https') }

    before do
      stub_request(:get, "#{base_url}/ServiceProviderConfig")
        .to_return(status: 500, body: { detail: 'boom' }.to_json)
    end

    # Silently leaving the configuration empty hides the failure.
    specify { expect { subject.load_from(base_url) }.to raise_error(Scim::Kit::RequestFailed) }
  end

  describe '#load_from with credentials' do
    let(:base_url) { FFaker::Internet.uri('https') }
    let(:headers) { { 'Authorization' => 'Bearer xyz' } }

    before do
      stub_request(:get, %r{#{base_url}/.*}).with(headers: headers)
        .to_return(status: 200, body: { schemas: ['urn:x'] }.to_json)
    end

    it 'forwards them to every discovery request' do
      subject.load_from(base_url, headers: headers)

      expect(a_request(:get, "#{base_url}/Schemas").with(headers: headers))
        .to have_been_made
    end
  end
end
