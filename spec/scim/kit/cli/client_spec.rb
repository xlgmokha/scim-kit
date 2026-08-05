# frozen_string_literal: true

RSpec.describe Scim::Kit::Cli::Client do
  let(:body) { { id: '1' }.to_json }

  let(:auth) { { 'Authorization' => 'Bearer xyz' } }

  def client(base_url, headers: {})
    described_class.new(base_url, headers: headers)
  end

  def off_origin
    yield.fetch('https://evil.test/Users')
  rescue Scim::Kit::Cli::OffOrigin
    nil
  end

  describe '#fetch' do
    it 'joins a base url without a trailing slash to a path' do
      stub = stub_request(:get, 'https://example.com/scim/v2/Users')
        .to_return(status: 200, body: body)

      client('https://example.com/scim/v2').fetch('Users')

      expect(stub).to have_been_requested
    end

    it 'joins a base url with a trailing slash to a path' do
      stub = stub_request(:get, 'https://example.com/scim/v2/Users')
        .to_return(status: 200, body: body)

      client('https://example.com/scim/v2/').fetch('Users')

      expect(stub).to have_been_requested
    end

    it 'joins a base url with multiple trailing slashes to a path' do
      stub = stub_request(:get, 'https://example.com/scim/v2/Users')
        .to_return(status: 200, body: body)

      client('https://example.com/scim/v2///').fetch('Users')

      expect(stub).to have_been_requested
    end

    it 'appends the query string' do
      stub = stub_request(:get, 'https://example.com/Users?count=2&filter=x')
        .to_return(status: 200, body: body)

      client('https://example.com')
        .fetch('Users', query: { 'filter' => 'x', 'count' => 2 })

      expect(stub).to have_been_requested
    end

    it 'refuses a path that leaves the base url origin' do
      expect { client('https://example.com').fetch('https://evil.test/Users') }
        .to raise_error(Scim::Kit::Cli::OffOrigin, /evil\.test/)
    end

    it 'allows an absolute path on the same origin' do
      stub = stub_request(:get, 'https://example.com/scim/Users')
        .to_return(status: 200, body: body)

      client('https://example.com').fetch('https://example.com/scim/Users')

      expect(stub).to have_been_requested
    end

    it 'does not send the headers off origin' do
      off_origin { client('https://example.com', headers: auth) }

      expect(a_request(:get, 'https://evil.test/Users')).not_to have_been_made
    end

    it 'percent-encodes spaces in query values' do
      http = instance_double(Scim::Kit::Http, fetch: nil)
      expected = URI('https://example.com/Users?filter=userName%20eq%20%22bj%22')

      described_class.new('https://example.com', http: http)
        .fetch('Users', query: { 'filter' => 'userName eq "bj"' })

      expect(http).to have_received(:fetch).with(expected, headers: {})
    end

    it 'omits blank query values' do
      stub = stub_request(:get, 'https://example.com/Users')
        .to_return(status: 200, body: body)

      client('https://example.com')
        .fetch('Users', query: { 'filter' => nil, 'count' => nil })

      expect(stub).to have_been_requested
    end

    it 'sends the configured headers' do
      auth = { 'Authorization' => 'Bearer xyz' }
      stub = stub_request(:get, 'https://example.com/Users')
        .with(headers: auth).to_return(status: 200, body: body)

      client('https://example.com', headers: auth).fetch('Users')

      expect(stub).to have_been_requested
    end

    it 'returns the parsed result' do
      stub_request(:get, 'https://example.com/Users')
        .to_return(status: 200, body: body)

      result = client('https://example.com').fetch('Users')

      expect(result.body).to eql(id: '1')
    end
  end
end
