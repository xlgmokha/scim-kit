RSpec.describe Scim::Kit::Resource do
  subject { described_class.new }

  before do
    #subject.id = "Group"
    #subject.meta.location = "https://www.example.org/scim/v2/resource_types/Group"
    #subject.description = "Group"
    #subject.endpoint = "https://www.example.org/scim/v2/groups"
    #subject.name = "Group"
    #subject.schema Scim::Kit::Schema::Group
    #subject.schema_extensions = []
  end

  let(:hash) { JSON.parse(subject.to_json, symbolize_names: true) }

  specify { expect(hash[:schemas]).to match_array([Scim::Kit::Schema::RESOURCE_TYPE]) }
end
