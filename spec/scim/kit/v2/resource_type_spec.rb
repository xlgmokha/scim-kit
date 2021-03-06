# frozen_string_literal: true

RSpec.describe Scim::Kit::V2::ResourceType do
  subject do
    described_class.build(location: location) do |x|
      x.id = 'Group'
      x.description = 'Group'
      x.endpoint = 'https://www.example.org/scim/v2/groups'
      x.name = 'Group'
      x.schema = Scim::Kit::V2::Schemas::GROUP
    end
  end

  let(:location) { FFaker::Internet.uri('https') }

  specify { expect(subject.to_h[:meta][:location]).to eql(location) }
  specify { expect(subject.to_h[:meta][:resourceType]).to eql('ResourceType') }
  specify { expect(subject.to_h[:schemas]).to match_array([Scim::Kit::V2::Schemas::RESOURCE_TYPE]) }
  specify { expect(subject.to_h[:id]).to eql('Group') }
  specify { expect(subject.to_h[:description]).to eql(subject.description) }
  specify { expect(subject.to_h[:endpoint]).to eql(subject.endpoint) }
  specify { expect(subject.to_h[:name]).to eql(subject.name) }
  specify { expect(subject.to_h[:schema]).to eql(subject.schema) }
  specify { expect(subject.to_h[:schemaExtensions]).to match_array([]) }

  context 'with a schema extension' do
    let(:extension) { 'urn:ietf:params:scim:schemas:extension:enterprise:2.0:User' }

    before { subject.add_schema_extension(schema: extension, required: false) }

    specify { expect(subject.to_h[:schemaExtensions]).to match_array([{ schema: extension, required: false }]) }
  end

  describe '.parse' do
    let(:extension) { 'urn:ietf:params:scim:schemas:extension:enterprise:2.0:User' }
    let(:result) { described_class.parse(subject.to_json) }

    before { subject.add_schema_extension(schema: extension, required: false) }

    specify { expect(result.id).to eql(subject.id) }
    specify { expect(result.name).to eql(subject.name) }
    specify { expect(result.description).to eql(subject.description) }
    specify { expect(result.endpoint).to eql(subject.endpoint) }
    specify { expect(result.schema).to eql(subject.schema) }
    specify { expect(result.schema_extensions).to eql(subject.schema_extensions) }
    specify { expect(result.to_h).to eql(subject.to_h) }
    specify { expect(result.to_json).to eql(subject.to_json) }
  end
end
