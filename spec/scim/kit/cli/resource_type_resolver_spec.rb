# frozen_string_literal: true

RSpec.describe Scim::Kit::Cli::ResourceTypeResolver do
  subject do
    described_class.new(
      Scim::Kit::Cli::Client.new(base_url, headers: headers)
    )
  end

  let(:base_url) { FFaker::Internet.uri('https') }
  let(:headers) { {} }

  describe '#resource_type_for' do
    before do
      stub_request(:get, "#{base_url}/ResourceTypes").to_return(
        status: 200,
        body: [
          { id: 'User', name: 'User', endpoint: '/Users',
            schema: 'urn:ietf:params:scim:schemas:core:2.0:User' },
          { id: 'Group', name: 'Group', endpoint: '/Groups' }
        ].to_json
      )
    end

    it 'returns the full matched resource type entry' do
      expect(subject.resource_type_for('User')).to include(
        endpoint: '/Users',
        schema: 'urn:ietf:params:scim:schemas:core:2.0:User'
      )
    end

    it 'matches case-insensitively' do
      expect(subject.resource_type_for('user')).to include(endpoint: '/Users')
    end

    it 'resolves each name independently' do
      subject.resource_type_for('User')

      expect(subject.resource_type_for('Group')).to include(endpoint: '/Groups')
    end

    it 'fetches ResourceTypes once across repeated lookups' do
      subject.resource_type_for('User')
      subject.resource_type_for('Group')

      expect(a_request(:get, "#{base_url}/ResourceTypes")).to have_been_made.once
    end

    it 'raises when no resource type matches the given name' do
      expect { subject.resource_type_for('Nope') }.to raise_error(
        Scim::Kit::Cli::UnknownResourceType, /Nope/
      )
    end

    context 'with custom headers' do
      let(:headers) { { 'Authorization' => 'Bearer xyz' } }

      it 'forwards them to the ResourceTypes request' do
        subject.resource_type_for('User')

        expect(a_request(:get, "#{base_url}/ResourceTypes").with(headers: headers)).to have_been_made
      end
    end

    context 'when /ResourceTypes returns a ListResponse envelope' do
      before do
        stub_request(:get, "#{base_url}/ResourceTypes").to_return(
          status: 200,
          body: {
            schemas: ['urn:ietf:params:scim:api:messages:2.0:ListResponse'],
            totalResults: 1,
            Resources: [{ id: 'User', name: 'User', endpoint: '/Users' }]
          }.to_json
        )
      end

      it 'resolves the entry from the Resources array' do
        expect(subject.resource_type_for('User')).to include(endpoint: '/Users')
      end
    end
  end

  context 'when the request fails' do
    before { stub_request(:get, "#{base_url}/ResourceTypes").to_return(status: 500, body: '{}') }

    it 'raises' do
      expect { subject.resource_type_for('User') }.to raise_error(Scim::Kit::Cli::RequestFailed)
    end
  end

  context 'when the response body is neither a list nor a ListResponse' do
    before do
      stub_request(:get, "#{base_url}/ResourceTypes").to_return(
        status: 200,
        body: { detail: 'not a collection' }.to_json
      )
    end

    it 'raises InvalidResponse' do
      expect { subject.resource_type_for('User') }.to raise_error(Scim::Kit::Cli::InvalidResponse)
    end
  end
end
