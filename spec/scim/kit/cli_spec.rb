# frozen_string_literal: true

RSpec.describe Scim::Kit::Cli do
  describe '.join_uri' do
    it 'joins a base url without a trailing slash to a path' do
      uri = described_class.join_uri('https://example.com/scim/v2', 'Users')

      expect(uri.to_s).to eql('https://example.com/scim/v2/Users')
    end

    it 'joins a base url with a trailing slash to a path' do
      uri = described_class.join_uri('https://example.com/scim/v2/', 'Users')

      expect(uri.to_s).to eql('https://example.com/scim/v2/Users')
    end

    it 'joins a base url with multiple trailing slashes to a path' do
      uri = described_class.join_uri('https://example.com/scim/v2///', 'Users')

      expect(uri.to_s).to eql('https://example.com/scim/v2/Users')
    end
  end

  describe '.collection' do
    it 'returns a bare array unchanged' do
      expect(described_class.collection([{ id: '1' }])).to eql([{ id: '1' }])
    end

    it 'unwraps the Resources array from a ListResponse envelope' do
      body = { totalResults: 1, Resources: [{ id: '1' }] }

      expect(described_class.collection(body)).to eql([{ id: '1' }])
    end

    it 'returns nil for a hash without a Resources array' do
      expect(described_class.collection(detail: 'boom')).to be_nil
    end

    it 'returns nil for a scalar body' do
      expect(described_class.collection('nope')).to be_nil
    end
  end
end
