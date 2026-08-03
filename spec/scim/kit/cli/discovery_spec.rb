# frozen_string_literal: true

RSpec.describe Scim::Kit::Cli::Discovery do
  subject { described_class.new(Scim::Kit::Cli::Client.new(base_url)) }

  let(:base_url) { FFaker::Internet.uri('https') }
  let(:config) { { schemas: ['urn:x'], patch: { supported: true } } }
  let(:schemas) { { totalResults: 0, Resources: [] } }
  let(:resource_types) { { totalResults: 0, Resources: [] } }

  before do
    stub_request(:get, "#{base_url}/ServiceProviderConfig")
      .to_return(status: 200, body: config.to_json)
    stub_request(:get, "#{base_url}/Schemas")
      .to_return(status: 200, body: schemas.to_json)
    stub_request(:get, "#{base_url}/ResourceTypes")
      .to_return(status: 200, body: resource_types.to_json)
  end

  describe '#fetch' do
    it 'keys each document by its resource name' do
      expect(subject.fetch.body.keys)
        .to eql(%i[service_provider_configuration schemas resource_types])
    end

    it 'returns an ok result when every request succeeds' do
      expect(subject.fetch).to be_ok
    end

    it 'collects each document body' do
      expect(subject.fetch.body[:service_provider_configuration])
        .to eql(config)
    end

    context 'when a request fails' do
      before do
        stub_request(:get, "#{base_url}/ServiceProviderConfig")
          .to_return(status: 500, body: { detail: 'boom' }.to_json)
      end

      it 'returns the failed result' do
        expect(subject.fetch).not_to be_ok
      end

      it 'stops before requesting the later documents' do
        subject.fetch

        expect(a_request(:get, "#{base_url}/Schemas")).not_to have_been_made
      end
    end
  end

  describe '#errors_for' do
    it 'is empty when every document conforms' do
      documents = subject.fetch.body
      documents[:service_provider_configuration] = valid_config
      documents[:schemas] = valid_list
      documents[:resource_types] = valid_list

      expect(subject.errors_for(documents)).to eql({})
    end

    it 'keys errors by the document that failed' do
      errors = subject.errors_for(service_provider_configuration: {})

      expect(errors.keys).to eql([:service_provider_configuration])
    end

    it 'omits documents that conform' do
      documents = { schemas: valid_list, resource_types: {} }

      expect(subject.errors_for(documents).keys).to eql([:resource_types])
    end
  end

  def valid_config
    {
      schemas: ['urn:ietf:params:scim:schemas:core:2.0:ServiceProviderConfig'],
      patch: { supported: true },
      bulk: { supported: false, maxOperations: 0, maxPayloadSize: 0 },
      filter: { supported: false, maxResults: 0 },
      changePassword: { supported: false }, sort: { supported: false },
      etag: { supported: false }, authenticationSchemes: []
    }
  end

  def valid_list
    {
      schemas: ['urn:ietf:params:scim:api:messages:2.0:ListResponse'],
      totalResults: 0, Resources: []
    }
  end
end
