# frozen_string_literal: true

RSpec.describe Scim::Kit::Cli::ResourceValidation do
  subject { described_class.new(resolver, reporter) }

  let(:reporter) { Scim::Kit::Cli::Reporter.new }
  let(:entry) { { name: 'User', schema: core_urn } }
  let(:core_urn) { 'urn:ietf:params:scim:schemas:core:2.0:User' }
  let(:schema) do
    {
      'type' => 'object',
      'properties' => { 'userName' => { 'type' => 'string' } },
      'required' => %w[schemas id userName]
    }
  end
  let(:resolver) do
    instance_double(
      Scim::Kit::Cli::ResourceSchemaResolver,
      schema_for: schema, undeclared_extensions: []
    )
  end
  let(:resource) { { schemas: [core_urn], id: '1', userName: 'mo' } }

  describe '#errors_for' do
    it 'is empty for a conforming resource' do
      expect(subject.errors_for(entry, resource)).to eql([])
    end

    it 'reports a schema violation' do
      expect(subject.errors_for(entry, resource.merge(userName: 42)))
        .to include(/userName.*is not of type: string/)
    end

    it 'applies the transform block to the schema' do
      errors = subject.errors_for(entry, { totalResults: 1 }) do |resource_schema|
        Scim::Kit::Cli::SchemaRegistry.list_response_with_items(resource_schema)
      end

      expect(errors).to include(/missing required keys.*schemas/)
    end

    context 'when sparse is set' do
      it 'does not demand attributes the server was not asked for' do
        errors = subject.errors_for(
          entry, { schemas: [core_urn], id: '1' }, sparse: true
        )

        expect(errors).to eql([])
      end

      it 'still demands the always-returned attributes' do
        expect(subject.errors_for(entry, { userName: 'mo' }, sparse: true))
          .to include(/missing required keys/)
      end
    end

    context 'when the schema cannot be resolved' do
      let(:resolver) do
        instance_double(
          Scim::Kit::Cli::ResourceSchemaResolver, schema_for: nil
        )
      end

      it 'returns nil so the caller can flag it as unvalidated' do
        allow($stderr).to receive(:puts)

        expect(subject.errors_for(entry, resource)).to be_nil
      end

      it 'warns naming the resource type' do
        expect { subject.errors_for(entry, resource) }
          .to output(/no schema found for resource type "User"/).to_stderr
      end
    end

    context 'when the resource type declares an undeclared extension' do
      let(:resolver) do
        instance_double(
          Scim::Kit::Cli::ResourceSchemaResolver,
          schema_for: schema, undeclared_extensions: ['urn:vendor:2.0:Thing']
        )
      end

      it 'warns naming the extension urn' do
        expect { subject.errors_for(entry, resource) }
          .to output(/urn:vendor:2.0:Thing/).to_stderr
      end

      it 'still validates the resource' do
        allow($stderr).to receive(:puts)

        expect(subject.errors_for(entry, resource)).to eql([])
      end
    end
  end
end
