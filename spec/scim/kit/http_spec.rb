# frozen_string_literal: true

RSpec.describe Scim::Kit::Http do
  subject { described_class.new }

  let(:uri) { URI(FFaker::Internet.uri('https')) }

  describe 'request logging' do
    let(:log) { StringIO.new }
    let(:server) { TCPServer.new('127.0.0.1', 0) }

    around do |example|
      WebMock.disable!
      original = Scim::Kit.logger
      Scim::Kit.logger = Logger.new(log)
      described_class.instance_variable_set(:@default_driver, nil)
      example.run
      Scim::Kit.logger = original
      described_class.instance_variable_set(:@default_driver, nil)
      WebMock.enable!
      server.close
    end

    def respond_once
      Thread.new do
        socket = server.accept
        loop { break if socket.gets.to_s.strip.empty? }
        socket.print("HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\n{}")
        socket.close
      end
    end

    def fetch_with_credentials
      responder = respond_once
      described_class.new(retries: 0).fetch(
        URI("http://127.0.0.1:#{server.addr[1]}/Users"),
        headers: { 'Authorization' => 'Bearer s3cret' }
      )
      responder.join
    end

    it 'keeps credentials out of the log' do
      fetch_with_credentials

      expect(log.string).not_to include('s3cret')
    end
  end

  describe '#fetch' do
    context 'when the response is successful' do
      let(:body) { { id: '123' } }

      before { stub_request(:get, uri).to_return(status: 200, body: body.to_json) }

      specify { expect(subject.fetch(uri)).to be_ok }
      specify { expect(subject.fetch(uri).status).to be(200) }
      specify { expect(subject.fetch(uri).body).to eql(body) }
    end

    context 'when the response is a scim error' do
      let(:error_body) { { detail: 'Resource not found', status: '404' } }

      before { stub_request(:get, uri).to_return(status: 404, body: error_body.to_json) }

      specify { expect(subject.fetch(uri)).not_to be_ok }
      specify { expect(subject.fetch(uri).status).to be(404) }
      specify { expect(subject.fetch(uri).body).to eql(error_body) }
    end

    context 'when the response body is not json' do
      before { stub_request(:get, uri).to_return(status: 500, body: 'boom') }

      specify { expect(subject.fetch(uri)).not_to be_ok }
      specify { expect(subject.fetch(uri).body).to eql(detail: 'boom') }
    end

    context 'when the response has no body' do
      before { stub_request(:get, uri).to_return(status: 204, body: nil) }

      specify { expect(subject.fetch(uri)).to be_ok }
      specify { expect(subject.fetch(uri).body).to eql({}) }
    end

    context 'when the connection fails' do
      subject { described_class.new(retries: 0) }

      before { stub_request(:get, uri).to_raise(Errno::ECONNREFUSED) }

      specify { expect(subject.fetch(uri)).not_to be_ok }
      specify { expect(subject.fetch(uri).status).to be_nil }
      specify { expect(subject.fetch(uri).body[:detail]).to include('Connection refused') }
    end

    context 'when headers are provided' do
      before do
        stub_request(:get, uri)
          .with(headers: { 'X-Test' => 'value' })
          .to_return(status: 200, body: '{}')
      end

      specify { expect(subject.fetch(uri, headers: { 'X-Test' => 'value' })).to be_ok }
    end

    context 'when the response redirects to the same origin' do
      let(:credentials) { { 'Authorization' => 'Bearer xyz' } }
      let(:redirect_uri) { URI.join(uri, '/v2/Users') }

      before do
        stub_request(:get, uri)
          .to_return(status: 301, headers: { 'Location' => redirect_uri.to_s })
        stub_request(:get, redirect_uri)
          .with(headers: credentials).to_return(status: 200, body: '{}')
      end

      specify { expect(subject.fetch(uri, headers: credentials)).to be_ok }
    end

    context 'when the response redirects to another origin' do
      let(:credentials) { { 'Authorization' => 'Bearer xyz' } }
      let(:redirect_uri) { URI('https://elsewhere.example.com/Users') }

      before do
        stub_request(:get, uri)
          .to_return(status: 301, headers: { 'Location' => redirect_uri.to_s })
        stub_request(:get, redirect_uri).to_return(status: 200, body: '{}')
      end

      it 'does not forward the credentials' do
        subject.fetch(uri, headers: credentials)

        expect(a_request(:get, redirect_uri)
          .with(headers: credentials)).not_to have_been_made
      end
    end
  end
end
