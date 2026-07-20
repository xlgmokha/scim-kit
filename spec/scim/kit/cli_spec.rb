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
end
