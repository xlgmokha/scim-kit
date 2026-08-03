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

    context 'when the matched resource type has no endpoint' do
      let(:resource_types) { [{ id: 'User', name: 'User' }] }

      it 'reports a MissingEndpoint error' do
        expect { exit_status { call.call(app, 'User') } }
          .to output(/User/).to_stderr
      end

      it 'exits 1' do
        allow($stderr).to receive(:print)

        expect(exit_status { call.call(app, 'User') }).to eq(1)
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

    context 'when --validate is set and every document is valid' do
      let(:service_provider_configuration) do
        {
          schemas: [
            'urn:ietf:params:scim:schemas:core:2.0:ServiceProviderConfig'
          ],
          patch: { supported: true },
          bulk: { supported: false, maxOperations: 0, maxPayloadSize: 0 },
          filter: { supported: true, maxResults: 200 },
          changePassword: { supported: false },
          sort: { supported: false },
          etag: { supported: false },
          authenticationSchemes: [
            {
              type: 'httpbasic', name: 'HTTP Basic',
              description: 'basic auth'
            }
          ]
        }
      end
      let(:schemas) do
        {
          schemas: ['urn:ietf:params:scim:api:messages:2.0:ListResponse'],
          totalResults: 1,
          Resources: [
            {
              id: 'urn:ietf:params:scim:schemas:core:2.0:User',
              schemas: ['urn:ietf:params:scim:schemas:core:2.0:Schema'],
              attributes: [
                { name: 'userName', type: 'string', required: true }
              ]
            }
          ]
        }
      end
      let(:resource_types) do
        {
          schemas: ['urn:ietf:params:scim:api:messages:2.0:ListResponse'],
          totalResults: 1,
          Resources: [
            {
              schemas: ['urn:ietf:params:scim:schemas:core:2.0:ResourceType'],
              name: 'User', endpoint: '/Users',
              schema: 'urn:ietf:params:scim:schemas:core:2.0:User'
            }
          ]
        }
      end

      before do
        stub_request(:get, "#{base_url}/ServiceProviderConfig").to_return(
          status: 200, body: service_provider_configuration.to_json
        )
        stub_request(:get, "#{base_url}/Schemas")
          .to_return(status: 200, body: schemas.to_json)
        stub_request(:get, "#{base_url}/ResourceTypes")
          .to_return(status: 200, body: resource_types.to_json)
      end

      it 'exits 0' do
        allow($stdout).to receive(:print)
        instance = app('validate' => true)

        expect(exit_status { instance.discover }).to eq(0)
      end
    end

    context 'when --validate is set and a collection is a bare array' do
      let(:schemas) do
        [
          {
            id: 'urn:ietf:params:scim:schemas:core:2.0:User',
            schemas: ['urn:ietf:params:scim:schemas:core:2.0:Schema'],
            attributes: [{ name: 'userName', type: 'string' }]
          }
        ]
      end

      before do
        stub_request(:get, "#{base_url}/ServiceProviderConfig").to_return(
          status: 200, body: service_provider_configuration.to_json
        )
        stub_request(:get, "#{base_url}/Schemas")
          .to_return(status: 200, body: schemas.to_json)
      end

      it 'flags the bare array as non-compliant with ListResponse format' do
        allow($stdout).to receive(:print)
        instance = app('validate' => true)

        expect { exit_status { instance.discover } }
          .to output(/root is not of type: object/).to_stderr
      end
    end

    context 'when --validate is set and a document is invalid' do
      let(:service_provider_configuration) { { patch: { supported: true } } }
      let(:schemas) { [{ id: 'User', name: 'User' }] }

      before do
        stub_request(:get, "#{base_url}/ServiceProviderConfig").to_return(
          status: 200, body: service_provider_configuration.to_json
        )
        stub_request(:get, "#{base_url}/Schemas")
          .to_return(status: 200, body: schemas.to_json)
      end

      it 'prints validation errors to stderr' do
        allow($stdout).to receive(:print)
        instance = app('validate' => true)

        expect { exit_status { instance.discover } }
          .to output(/validation_errors/).to_stderr
      end

      it 'exits 1' do
        allow($stdout).to receive(:print)
        allow($stderr).to receive(:print)
        instance = app('validate' => true)

        expect(exit_status { instance.discover }).to eq(1)
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

    context 'when --validate is set' do
      let(:core_urn) { 'urn:ietf:params:scim:schemas:core:2.0:User' }
      let(:resource_types) do
        [{ id: 'User', name: 'User', endpoint: '/Users', schema: core_urn }]
      end
      let(:schemas_response) do
        [
          {
            id: core_urn,
            attributes: [
              { name: 'userName', type: 'string', required: true }
            ]
          }
        ]
      end

      before do
        stub_request(:get, "#{base_url}/Schemas")
          .to_return(status: 200, body: schemas_response.to_json)
      end

      context 'when the list response is valid' do
        let(:list_response) do
          {
            schemas: ['urn:ietf:params:scim:api:messages:2.0:ListResponse'],
            totalResults: 1,
            Resources: [
              { schemas: [core_urn], id: '1', userName: 'bjensen' }
            ]
          }
        end

        before do
          stub_request(:get, "#{base_url}/Users")
            .to_return(status: 200, body: list_response.to_json)
        end

        it 'exits 0' do
          allow($stdout).to receive(:print)
          instance = app('validate' => true)

          expect(exit_status { instance.list('User') }).to eq(0)
        end
      end

      context 'when --attributes narrows the response' do
        before do
          stub_request(:get, "#{base_url}/Users?attributes=id")
            .to_return(
              status: 200,
              body: {
                schemas: ['urn:ietf:params:scim:api:messages:2.0:ListResponse'],
                totalResults: 1,
                Resources: [{ schemas: [core_urn], id: '1' }]
              }.to_json
            )
        end

        it 'exits 0 without demanding attributes the server was not asked for' do
          allow($stdout).to receive(:print)
          instance = app('validate' => true, 'attributes' => 'id')

          expect(exit_status { instance.list('User') }).to eq(0)
        end
      end

      context 'when the resource type declares an extension /Schemas omits' do
        let(:extension_urn) { 'urn:vendor:2.0:Thing' }
        let(:resource_types) do
          [{
            id: 'User', name: 'User', endpoint: '/Users', schema: core_urn,
            schemaExtensions: [{ schema: extension_urn, required: true }]
          }]
        end

        before do
          stub_request(:get, "#{base_url}/Users").to_return(
            status: 200,
            body: {
              schemas: ['urn:ietf:params:scim:api:messages:2.0:ListResponse'],
              totalResults: 1,
              Resources: [
                { schemas: [core_urn], id: '1', userName: 'bjensen' }
              ]
            }.to_json
          )
        end

        it 'warns about the undeclared extension' do
          allow($stdout).to receive(:print)
          instance = app('validate' => true)

          expect { exit_status { instance.list('User') } }
            .to output(/#{Regexp.escape(extension_urn)}/).to_stderr
        end

        it 'still exits 0' do
          allow($stdout).to receive(:print)
          allow($stderr).to receive(:print)
          instance = app('validate' => true)

          expect(exit_status { instance.list('User') }).to eq(0)
        end
      end

      context 'when a resource in the list response is invalid' do
        let(:list_response) do
          {
            schemas: ['urn:ietf:params:scim:api:messages:2.0:ListResponse'],
            totalResults: 1, Resources: [{ id: '1', userName: 42 }]
          }
        end

        before do
          stub_request(:get, "#{base_url}/Users")
            .to_return(status: 200, body: list_response.to_json)
        end

        it 'prints validation errors to stderr' do
          allow($stdout).to receive(:print)
          instance = app('validate' => true)

          expect { exit_status { instance.list('User') } }
            .to output(/validation_errors/).to_stderr
        end

        it 'exits 1' do
          allow($stdout).to receive(:print)
          allow($stderr).to receive(:print)
          instance = app('validate' => true)

          expect(exit_status { instance.list('User') }).to eq(1)
        end
      end

      context 'when the resource type has no resolvable schema' do
        let(:resource_types) do
          [
            { id: 'User', name: 'User', endpoint: '/Users',
              schema: 'urn:example:Unresolvable' }
          ]
        end

        before do
          stub_request(:get, "#{base_url}/Users")
            .to_return(status: 200, body: { totalResults: 0 }.to_json)
        end

        it 'warns and exits 0' do
          allow($stdout).to receive(:print)
          instance = app('validate' => true)

          expect { exit_status { instance.list('User') } }
            .to output(/no schema found/).to_stderr
        end

        it 'exits 0' do
          allow($stdout).to receive(:print)
          allow($stderr).to receive(:print)
          instance = app('validate' => true)

          expect(exit_status { instance.list('User') }).to eq(0)
        end
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

    context 'when the id needs escaping' do
      it 'escapes a space rather than raising URI::InvalidURIError' do
        stub = stub_request(:get, "#{base_url}/Users/mo%20khan")
          .to_return(status: 200, body: {}.to_json)
        allow($stdout).to receive(:print)

        exit_status { app.get('User', 'mo khan') }

        expect(stub).to have_been_requested
      end

      it 'escapes separators so an id cannot traverse the endpoint' do
        stub = stub_request(:get, "#{base_url}/Users/..%2Fadmin%23x%3Fy")
          .to_return(status: 200, body: {}.to_json)
        allow($stdout).to receive(:print)

        exit_status { app.get('User', '../admin#x?y') }

        expect(stub).to have_been_requested
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

    context 'when --validate is set' do
      let(:core_urn) { 'urn:ietf:params:scim:schemas:core:2.0:User' }
      let(:resource_types) do
        [{ id: 'User', name: 'User', endpoint: '/Users', schema: core_urn }]
      end
      let(:schemas_response) do
        [
          {
            id: core_urn,
            attributes: [
              { name: 'userName', type: 'string', required: true }
            ]
          }
        ]
      end

      before do
        stub_request(:get, "#{base_url}/Schemas")
          .to_return(status: 200, body: schemas_response.to_json)
      end

      context 'when the resource is valid' do
        before do
          stub_request(:get, "#{base_url}/Users/123").to_return(
            status: 200,
            body: {
              schemas: [core_urn], id: '123', userName: 'bjensen'
            }.to_json
          )
        end

        it 'exits 0' do
          allow($stdout).to receive(:print)
          instance = app('validate' => true)

          expect(exit_status { instance.get('User', '123') }).to eq(0)
        end
      end

      context 'when the resource is invalid' do
        before do
          stub_request(:get, "#{base_url}/Users/123").to_return(
            status: 200, body: { id: '123', userName: 42 }.to_json
          )
        end

        it 'prints validation errors to stderr' do
          allow($stdout).to receive(:print)
          instance = app('validate' => true)

          expect { exit_status { instance.get('User', '123') } }
            .to output(/validation_errors/).to_stderr
        end

        it 'exits 1' do
          allow($stdout).to receive(:print)
          allow($stderr).to receive(:print)
          instance = app('validate' => true)

          expect(exit_status { instance.get('User', '123') }).to eq(1)
        end
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
