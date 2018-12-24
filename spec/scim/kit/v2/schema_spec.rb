# frozen_string_literal: true

RSpec.describe Scim::Kit::V2::Schema do
  subject { described_class.new(id: id, name: name, location: location) }

  let(:id) { 'Group' }
  let(:name) { 'Group' }
  let(:location) { FFaker::Internet.uri('https') }
  let(:description) { FFaker::Name.name }
  let(:result) { JSON.parse(subject.to_json, symbolize_names: true) }

  before do
    subject.description = description
  end

  specify { expect(result[:id]).to eql(id) }
  specify { expect(result[:name]).to eql(name) }
  specify { expect(result[:description]).to eql(description) }
  specify { expect(result[:meta][:resourceType]).to eql('Schema') }
  specify { expect(result[:meta][:location]).to eql(location) }

  context "with a single simple attribute" do
    before do
      subject.add_attribute(name: 'displayName')
    end

    specify { expect(result[:attributes][0][:name]).to eql('displayName') }
    specify { expect(result[:attributes][0][:type]).to eql('string') }
    specify { expect(result[:attributes][0][:multiValued]).to be(false) }
    specify { expect(result[:attributes][0][:description]).to eql('') }
    specify { expect(result[:attributes][0][:required]).to be(false) }
    specify { expect(result[:attributes][0][:caseExact]).to be(false) }
    specify { expect(result[:attributes][0][:mutability]).to eql('readWrite') }
    specify { expect(result[:attributes][0][:returned]).to eql('default') }
    specify { expect(result[:attributes][0][:uniqueness]).to eql('none') }
  end
end
