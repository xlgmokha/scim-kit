# frozen_string_literal: true

RSpec.describe Scim::Kit::Cli::Client do
  let(:body) { { id: '1' }.to_json }

  def client(base_url, headers: {})
    described_class.new(base_url, headers: headers)
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
