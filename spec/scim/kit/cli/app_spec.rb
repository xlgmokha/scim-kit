# frozen_string_literal: true

RSpec.describe Scim::Kit::Cli::App do
  let(:base_url) { FFaker::Internet.uri('https') }
  let(:resource_types) { [{ id: 'User', name: 'User', endpoint: '/Users' }] }

  def app(options = {})
    described_class.new([], { 'url' => base_url }.merge(options))
  end

  before do
    stub_request(:get, "#{base_url}/ResourceTypes")
      .to_return(status: 200, body: resource_types.to_json)
  end

  shared_examples 'a resource-type-resolving command' do |call|
    context 'when the resource type is unknown' do
      it 'reports the unknown resource type' do
        expect { exit_status { call.call(app, 'Nope') } }.to output(/Nope/).to_stderr
      end

      it 'exits 1' do
        allow($stderr).to receive(:print)

        expect(exit_status { call.call(app, 'Nope') }).to eq(1)
      end
    end

    context 'when fetching ResourceTypes fails' do
      before do
        stub_request(:get, "#{base_url}/ResourceTypes")
          .to_return(status: 500, body: { detail: 'boom' }.to_json)
      end

      it 'reports the failure' do
        expect { exit_status { call.call(app, 'User') } }
          .to output("#{JSON.pretty_generate(detail: 'boom')}\n").to_stderr
      end
    end
  end

  describe '#discover' do
    let(:service_provider_configuration) { { patch: { supported: true } } }
    let(:schemas) { [{ id: 'User', name: 'User' }] }

    context 'when every request succeeds' do
      before do
        stub_request(:get, "#{base_url}/ServiceProviderConfig")
          .to_return(status: 200, body: service_provider_configuration.to_json)
        stub_request(:get, "#{base_url}/Schemas")
          .to_return(status: 200, body: schemas.to_json)
      end

      let(:expected_output) do
        JSON.pretty_generate(
          service_provider_configuration: service_provider_configuration,
          schemas: schemas,
          resource_types: resource_types
        )
      end

      it 'prints the combined configuration as pretty json' do
        expect { exit_status { app.discover } }
          .to output("#{expected_output}\n").to_stdout
      end

      it 'exits 0' do
        allow($stdout).to receive(:print)

        expect(exit_status { app.discover }).to eq(0)
      end
    end

    context 'when the ServiceProviderConfig request fails' do
      before do
        stub_request(:get, "#{base_url}/ServiceProviderConfig")
          .to_return(status: 500, body: { detail: 'boom' }.to_json)
      end

      it 'reports the failure without requesting Schemas' do
        allow($stderr).to receive(:print)
        exit_status { app.discover }

        expect(a_request(:get, "#{base_url}/Schemas")).not_to have_been_made
      end

      it 'exits 1' do
        allow($stderr).to receive(:print)

        expect(exit_status { app.discover }).to eq(1)
      end
    end
  end

  describe '#list' do
    include_examples 'a resource-type-resolving command', ->(a, type) { a.list(type) }

    context 'when the resource type and the list request both succeed' do
      let(:list_response) { { totalResults: 1, Resources: [{ id: '1' }] } }
      let(:instance) do
        app(
          'filter' => 'userName eq "bjensen"',
          'start_index' => 2,
          'count' => 10,
          'sort_by' => 'userName',
          'sort_order' => 'ascending',
          'attributes' => 'userName,emails'
        )
      end

      before do
        stub_request(:get, "#{base_url}/Users")
          .with(
            query: {
              'filter' => 'userName eq "bjensen"',
              'startIndex' => '2',
              'count' => '10',
              'sortBy' => 'userName',
              'sortOrder' => 'ascending',
              'attributes' => 'userName,emails'
            }
          )
          .to_return(status: 200, body: list_response.to_json)
      end

      it 'prints the list response as pretty json' do
        expect { exit_status { instance.list('User') } }
          .to output("#{JSON.pretty_generate(list_response)}\n").to_stdout
      end

      it 'exits 0' do
        allow($stdout).to receive(:print)

        expect(exit_status { instance.list('User') }).to eq(0)
      end
    end

    context 'when the list request fails' do
      before do
        stub_request(:get, "#{base_url}/Users")
          .to_return(status: 404, body: { detail: 'not found' }.to_json)
      end

      it 'reports the failure' do
        expect { exit_status { app.list('User') } }
          .to output("#{JSON.pretty_generate(detail: 'not found')}\n").to_stderr
      end

      it 'exits 1' do
        allow($stderr).to receive(:print)

        expect(exit_status { app.list('User') }).to eq(1)
      end
    end
  end

  describe '#get' do
    include_examples 'a resource-type-resolving command', ->(a, type) { a.get(type, '123') }

    context 'when the resource type and the get request both succeed' do
      let(:resource) { { id: '123', userName: 'bjensen' } }
      let(:instance) { app('attributes' => 'userName,emails') }

      before do
        stub_request(:get, "#{base_url}/Users/123")
          .with(query: { 'attributes' => 'userName,emails' })
          .to_return(status: 200, body: resource.to_json)
      end

      it 'prints the resource as pretty json' do
        expect { exit_status { instance.get('User', '123') } }
          .to output("#{JSON.pretty_generate(resource)}\n").to_stdout
      end

      it 'exits 0' do
        allow($stdout).to receive(:print)

        expect(exit_status { instance.get('User', '123') }).to eq(0)
      end
    end

    context 'when the get request fails' do
      before do
        stub_request(:get, "#{base_url}/Users/123")
          .to_return(status: 404, body: { detail: 'not found' }.to_json)
      end

      it 'reports the failure' do
        expect { exit_status { app.get('User', '123') } }
          .to output("#{JSON.pretty_generate(detail: 'not found')}\n").to_stderr
      end

      it 'exits 1' do
        allow($stderr).to receive(:print)

        expect(exit_status { app.get('User', '123') }).to eq(1)
      end
    end
  end

  describe 'header parsing' do
    before do
      stub_request(:get, "#{base_url}/ResourceTypes")
        .with(headers: { 'Authorization' => 'Bearer xyz', 'X-Test' => 'value' })
        .to_return(status: 200, body: resource_types.to_json)
      stub_request(:get, "#{base_url}/Users").to_return(status: 200, body: '{}')
    end

    it 'sends repeated --header flags as request headers' do
      allow($stdout).to receive(:print)
      instance = app('header' => ['Authorization: Bearer xyz', 'X-Test: value'])

      exit_status { instance.list('User') }

      expect(a_request(:get, "#{base_url}/Users")).to have_been_made
    end
  end

  describe 'CLI argv parsing via .start' do
    around do |example|
      original = ENV.fetch('SCIM_KIT_URL', nil)
      example.run
      ENV['SCIM_KIT_URL'] = original
    end

    before do
      ENV.delete('SCIM_KIT_URL')
      stub_request(:get, "#{base_url}/Users").to_return(status: 200, body: '{}')
    end

    it 'exits 1 with a usage message when RESOURCE_TYPE is missing' do
      allow($stderr).to receive(:print)

      expect { exit_status { described_class.start(['list', '--url', base_url]) } }
        .to output(/no arguments/).to_stderr
    end

    it 'exits 1 when --url is missing entirely' do
      allow($stderr).to receive(:puts)

      status = exit_status { described_class.start(%w[list User]) }

      expect(status).to eq(1)
    end

    it 'reads --url from SCIM_KIT_URL when --url is omitted' do
      ENV['SCIM_KIT_URL'] = base_url
      allow($stdout).to receive(:print)

      status = exit_status { described_class.start(%w[list User]) }

      expect(status).to eq(0)
    end

    it 'exits 1 with a usage message for a malformed --header' do
      allow($stderr).to receive(:print)
      argv = ['list', 'User', '--url', base_url, '--header', 'BearerXYZ']

      expect { exit_status { described_class.start(argv) } }
        .to output(/malformed --header/).to_stderr
    end
  end
end
