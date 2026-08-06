# frozen_string_literal: true

RSpec.describe Scim::Kit::Cli::Discovery do
  subject { described_class.new(Scim::Kit::V2::Client.new(base_url)) }

  let(:base_url) { FFaker::Internet.uri('https') }
  let(:config) { { schemas: ['urn:x'], patch: { supported: true } } }
  let(:schemas) { { totalResults: 0, Resources: [] } }
  let(:resource_types) { { totalResults: 0, Resources: [] } }

  before do
    stub_request(:get, "#{base_url}/ServiceProviderConfig").to_return(status: 200, body: config.to_json)
    stub_request(:get, "#{base_url}/Schemas").to_return(status: 200, body: schemas.to_json)
    stub_request(:get, "#{base_url}/ResourceTypes").to_return(status: 200, body: resource_types.to_json)
  end

  describe '#fetch' do
    specify { expect(subject.fetch.body.keys).to eql(%i[service_provider_configuration schemas resource_types]) }
    specify { expect(subject.fetch).to be_ok }
    specify { expect(subject.fetch.body[:service_provider_configuration]).to eql(config) }

    context 'when a request fails' do
      before do
        stub_request(:get, "#{base_url}/ServiceProviderConfig").to_return(status: 500, body: { detail: 'boom' }.to_json)
      end

      specify { expect(subject.fetch).not_to be_ok }

      it 'stops before requesting the later documents' do
        subject.fetch

        expect(a_request(:get, "#{base_url}/Schemas")).not_to have_been_made
      end
    end
  end

  describe '#errors_for' do
    let(:valid_config) do
      {
        schemas: ['urn:ietf:params:scim:schemas:core:2.0:ServiceProviderConfig'],
        patch: { supported: true },
        bulk: { supported: false, maxOperations: 0, maxPayloadSize: 0 },
        filter: { supported: false, maxResults: 0 },
        changePassword: { supported: false }, sort: { supported: false },
        etag: { supported: false }, authenticationSchemes: []
      }
    end

    let(:valid_list) { { schemas: ['urn:ietf:params:scim:api:messages:2.0:ListResponse'], totalResults: 0, Resources: [] } }

    specify { expect(subject.errors_for({ service_provider_configuration: valid_config, schemas: valid_list, resource_types: valid_list })).to eql({}) }
    specify { expect(subject.errors_for(service_provider_configuration: {}).keys).to eql([:service_provider_configuration]) }

    it 'reports an empty schemas array, which RFC 7643 3.1 forbids' do
      errors = subject.errors_for(service_provider_configuration: valid_config.merge(schemas: []))

      expect(errors[:service_provider_configuration]).not_to be_empty
    end

    it 'reports schemas without the ServiceProviderConfig URI' do
      errors = subject.errors_for(
        service_provider_configuration: valid_config.merge(schemas: ['urn:x'])
      )

      expect(errors[:service_provider_configuration])
        .to include(%r{'/schemas' does not contain: ".*ServiceProviderConfig"})
    end

    it 'reports a Schema resource without the Schema URI' do
      resource = { schemas: ['urn:x'], id: 'urn:y', attributes: [] }
      errors = subject.errors_for(
        schemas: valid_list.merge(totalResults: 1, Resources: [resource])
      )

      expect(errors[:schemas]).not_to be_empty
    end

    it 'reports a meta.version that is not an entity-tag' do
      config = valid_config.merge(meta: { version: '1785781881' })
      errors = subject.errors_for(service_provider_configuration: config)

      expect(errors[:service_provider_configuration]).not_to be_empty
    end

    it 'reports a lowercase weakness indicator' do
      config = valid_config.merge(meta: { version: 'w/"abc"' })
      errors = subject.errors_for(service_provider_configuration: config)

      expect(errors[:service_provider_configuration]).not_to be_empty
    end

    it 'accepts a weak entity-tag' do
      config = valid_config.merge(meta: { version: 'W/"abc123"' })

      expect(subject.errors_for(service_provider_configuration: config)).to eql({})
    end

    it 'accepts a strong entity-tag' do
      config = valid_config.merge(meta: { version: '"abc123"' })

      expect(subject.errors_for(service_provider_configuration: config)).to eql({})
    end

    specify { expect(subject.errors_for({ schemas: valid_list, resource_types: {} }).keys).to eql([:resource_types]) }
  end
end
