# frozen_string_literal: true

RSpec.describe Scim::Kit::Cli::ResourceTypeResolver do
  subject { described_class.new(Scim::Kit::Http.new, base_url, headers: headers) }

  let(:base_url) { FFaker::Internet.uri('https') }
  let(:headers) { {} }

  describe '#endpoint_for' do
    before do
      stub_request(:get, "#{base_url}/ResourceTypes").to_return(
        status: 200,
        body: [
          { id: 'User', name: 'User', endpoint: '/Users' },
          { id: 'Group', name: 'Group', endpoint: '/Groups' }
        ].to_json
      )
    end

    specify { expect(subject.endpoint_for('User')).to eql('/Users') }
    specify { expect(subject.endpoint_for('user')).to eql('/Users') }
    specify { expect(subject.endpoint_for('Group')).to eql('/Groups') }

    it 'raises when no resource type matches the given name' do
      expect { subject.endpoint_for('Nope') }.to raise_error(
        Scim::Kit::Cli::UnknownResourceType, /Nope/
      )
    end

    context 'with custom headers' do
      let(:headers) { { 'Authorization' => 'Bearer xyz' } }

      it 'forwards them to the ResourceTypes request' do
        subject.endpoint_for('User')

        expect(a_request(:get, "#{base_url}/ResourceTypes").with(headers: headers)).to have_been_made
      end
    end
  end

  context 'when the matched resource type has no endpoint' do
    before do
      stub_request(:get, "#{base_url}/ResourceTypes").to_return(
        status: 200,
        body: [{ id: 'User', name: 'User' }].to_json
      )
    end

    it 'raises MissingEndpoint' do
      expect { subject.endpoint_for('User') }.to raise_error(
        Scim::Kit::Cli::MissingEndpoint, /User/
      )
    end
  end

  context 'when the request fails' do
    before { stub_request(:get, "#{base_url}/ResourceTypes").to_return(status: 500, body: '{}') }

    it 'raises' do
      expect { subject.endpoint_for('User') }.to raise_error(Scim::Kit::Cli::RequestFailed)
    end
  end

  context 'when the response body is not a list' do
    before do
      stub_request(:get, "#{base_url}/ResourceTypes").to_return(
        status: 200,
        body: { Resources: [] }.to_json
      )
    end

    it 'raises InvalidResponse' do
      expect { subject.endpoint_for('User') }.to raise_error(Scim::Kit::Cli::InvalidResponse)
    end
  end
end
