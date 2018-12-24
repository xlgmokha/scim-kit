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
end
