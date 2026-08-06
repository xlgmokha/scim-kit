# frozen_string_literal: true

RSpec.describe Scim::Kit::V2::Document do
  let(:documents) { Scim::Kit::V2::Documents }
  let(:location) { FFaker::Internet.uri('https') }

  describe '.to_scim_document' do
    # A SCIM document names its own type in "schemas" (RFC 7643 3.1), so the
    # payload decides the class.
    {
      Scim::Kit::V2::Schemas::SERVICE_PROVIDER_CONFIGURATION =>
        'ServiceProviderConfig',
      Scim::Kit::V2::Schemas::SCHEMA => 'Schema',
      Scim::Kit::V2::Schemas::RESOURCE_TYPE => 'ResourceType',
      Scim::Kit::V2::Messages::LIST_RESPONSE => 'ListResponse',
      Scim::Kit::V2::Messages::ERROR => 'Error'
    }.each do |urn, name|
      it "dispatches #{urn.split(':').last} to Documents::#{name}" do
        document = described_class.to_scim_document({ schemas: [urn] })

        expect(document).to be_instance_of(documents.const_get(name))
      end
    end

    # Never raises: garbage becomes an object that answers valid? == false.
    [nil, '', 'not json', '[]', [], {}, [{ id: '1' }], 42].each do |payload|
      context "with #{payload.inspect}" do
        let(:document) { described_class.to_scim_document(payload) }

        specify { expect { document }.not_to raise_error }
        specify { expect(document).to be_instance_of(documents::Invalid) }
        specify { expect(document).to be_invalid }
      end
    end

    it 'accepts a json string' do
      json = { schemas: [Scim::Kit::V2::Messages::ERROR] }.to_json

      expect(described_class.to_scim_document(json))
        .to be_instance_of(documents::Error)
    end

    it 'reports an unrecognised urn rather than guessing' do
      document = described_class.to_scim_document({ schemas: ['urn:nope'] })

      expect(document).to be_invalid
    end
  end

  # RFC 7644 3.4.2: a query returns a ListResponse whose Resources are
  # themselves SCIM documents, so each one validates as itself.
  describe Scim::Kit::V2::Documents::ListResponse do
    let(:list_urn) { Scim::Kit::V2::Messages::LIST_RESPONSE }
    let(:schema_urn) { Scim::Kit::V2::Schemas::SCHEMA }

    def list(*resources)
      Scim::Kit::V2::Document.to_scim_document(
        { schemas: [list_urn], totalResults: resources.length,
          Resources: resources }
      )
    end

    specify { expect(list).to be_valid }
    specify { expect(list({ schemas: [schema_urn], id: 'urn:x', attributes: [] })).to be_valid }

    it 'is invalid when a resource it carries is invalid' do
      expect(list({ schemas: [schema_urn], id: 'urn:x' })).to be_invalid
    end

    it 'says which resource failed' do
      document = list({ schemas: [schema_urn], id: 'urn:x' })

      document.valid?

      expect(document.errors[:base].join).to match(/Resources\[0\].*attributes/)
    end

    it 'is invalid when totalResults is missing' do
      document = described_class.new({ schemas: [list_urn] })

      expect(document).to be_invalid
    end
  end

  # Build -> serialize -> parse -> compare. Without this, the generating and
  # receiving halves can drift apart silently.
  describe '#to_model' do
    let(:resource_type) do
      Scim::Kit::V2::ResourceType.build(location: location) do |x|
        x.id = 'User'
        x.name = 'User'
        x.endpoint = '/Users'
        x.schema = Scim::Kit::V2::Schemas::USER
      end
    end

    def round_trip(built)
      described_class.to_scim_document(built.to_json)
    end

    it 'round-trips a ServiceProviderConfiguration' do
      built = Scim::Kit::V2::ServiceProviderConfiguration.new(location: location)

      expect(round_trip(built).to_model.to_h).to eql(built.to_h)
    end

    it 'round-trips a Schema' do
      built = Scim::Kit::V2::Schema.build(
        id: Scim::Kit::V2::Schemas::USER, name: 'User', location: location
      ) { |x| x.add_attribute(name: 'userName') { |y| y.required = true } }

      expect(round_trip(built).to_model.to_h).to eql(built.to_h)
    end

    it 'round-trips a ResourceType' do
      expect(round_trip(resource_type).to_model.to_h).to eql(resource_type.to_h)
    end
  end

  describe 'validity' do
    let(:payload) do
      { schemas: [Scim::Kit::V2::Schemas::SERVICE_PROVIDER_CONFIGURATION] }
    end

    it 'is valid when the document conforms' do
      built = Scim::Kit::V2::ServiceProviderConfiguration.new(location: location)

      expect(described_class.to_scim_document(built.to_json)).to be_valid
    end

    it 'is invalid when a required attribute is missing' do
      expect(described_class.to_scim_document(payload)).to be_invalid
    end

    it 'names the missing attribute' do
      document = described_class.to_scim_document(payload)

      document.valid?

      expect(document.errors[:base].join).to match(/missing required keys.*patch/)
    end
  end
end
