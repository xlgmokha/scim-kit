# frozen_string_literal: true

RSpec.describe Scim::Kit::V2::Schema do
  subject { described_class.new(id: id, name: name, location: location) }

  let(:id) { 'Group' }
  let(:name) { 'Group' }
  let(:location) { FFaker::Internet.uri('https') }
  let(:description) { FFaker::Name.name }
  let(:result) { JSON.parse(subject.to_json, symbolize_names: true) }

  specify { expect(result[:id]).to eql(id) }
  specify { expect(result[:name]).to eql(name) }
  specify { expect(result[:description]).to eql(name) }
  specify { expect(result[:meta][:resourceType]).to eql('Schema') }
  specify { expect(result[:meta][:location]).to eql(location) }

  context 'with a description' do
    before do
      subject.description = description
    end

    specify { expect(result[:description]).to eql(description) }
  end

  context 'with a single simple attribute' do
    before do
      subject.add_attribute(name: 'displayName')
    end

    specify { expect(result[:attributes][0][:name]).to eql('displayName') }
    specify { expect(result[:attributes][0][:type]).to eql('string') }
    specify { expect(result[:attributes][0][:multiValued]).to be(false) }
    specify { expect(result[:attributes][0][:description]).to eql('displayName') }
    specify { expect(result[:attributes][0][:required]).to be(false) }
    specify { expect(result[:attributes][0][:caseExact]).to be(false) }
    specify { expect(result[:attributes][0][:mutability]).to eql('readWrite') }
    specify { expect(result[:attributes][0][:returned]).to eql('default') }
    specify { expect(result[:attributes][0][:uniqueness]).to eql('none') }

    context 'with a description' do
      before do
        subject.add_attribute(name: 'userName') do |x|
          x.description = 'my description'
        end
      end

      specify { expect(result[:attributes][1][:description]).to eql('my description') }
    end
  end

  context 'with a complex attribute' do
    before do
      subject.add_attribute(name: 'emails') do |x|
        x.multi_valued = true
        x.add_attribute(name: 'value')
        x.add_attribute(name: 'primary', type: 'boolean')
      end
    end

    specify { expect(result[:attributes][0][:name]).to eql('emails') }
    specify { expect(result[:attributes][0][:type]).to eql('complex') }
    specify { expect(result[:attributes][0][:multiValued]).to be(true) }
    specify { expect(result[:attributes][0][:description]).to eql('emails') }
    specify { expect(result[:attributes][0][:required]).to be(false) }
    specify { expect(result[:attributes][0].key?(:caseExact)).to be(false) }
    specify { expect(result[:attributes][0][:mutability]).to eql('readWrite') }
    specify { expect(result[:attributes][0][:returned]).to eql('default') }
    specify { expect(result[:attributes][0][:uniqueness]).to eql('none') }

    specify { expect(result[:attributes][0][:subAttributes][0][:name]).to eql('value') }
    specify { expect(result[:attributes][0][:subAttributes][0][:type]).to eql('string') }
    specify { expect(result[:attributes][0][:subAttributes][0][:multiValued]).to be(false) }
    specify { expect(result[:attributes][0][:subAttributes][0][:description]).to eql('value') }
    specify { expect(result[:attributes][0][:subAttributes][0][:required]).to be(false) }
    specify { expect(result[:attributes][0][:subAttributes][0][:caseExact]).to be(false) }
    specify { expect(result[:attributes][0][:subAttributes][0][:mutability]).to eql('readWrite') }
    specify { expect(result[:attributes][0][:subAttributes][0][:returned]).to eql('default') }
    specify { expect(result[:attributes][0][:subAttributes][0][:uniqueness]).to eql('none') }

    specify { expect(result[:attributes][0][:subAttributes][1][:name]).to eql('primary') }
    specify { expect(result[:attributes][0][:subAttributes][1][:type]).to eql('boolean') }
    specify { expect(result[:attributes][0][:subAttributes][1][:multiValued]).to be(false) }
    specify { expect(result[:attributes][0][:subAttributes][1][:description]).to eql('primary') }
    specify { expect(result[:attributes][0][:subAttributes][1][:required]).to be(false) }
    specify { expect(result[:attributes][0][:subAttributes][1].key?(:caseExact)).to be(false) }
    specify { expect(result[:attributes][0][:subAttributes][1][:mutability]).to eql('readWrite') }
    specify { expect(result[:attributes][0][:subAttributes][1][:returned]).to eql('default') }
    specify { expect(result[:attributes][0][:subAttributes][1][:uniqueness]).to eql('none') }
  end

  context 'with a reference attribute' do
    before do
      subject.add_attribute(name: '$ref', type: 'reference') do |x|
        x.reference_types = %w[User Group]
        x.mutability = :read_only
      end
    end

    specify { expect(result[:attributes][0][:name]).to eql('$ref') }
    specify { expect(result[:attributes][0][:type]).to eql('reference') }
    specify { expect(result[:attributes][0][:referenceTypes]).to match_array(%w[User Group]) }
    specify { expect(result[:attributes][0][:multiValued]).to be(false) }
    specify { expect(result[:attributes][0][:description]).to eql('$ref') }
    specify { expect(result[:attributes][0][:required]).to be(false) }
    specify { expect(result[:attributes][0][:caseExact]).to be(false) }
    specify { expect(result[:attributes][0][:mutability]).to eql('readOnly') }
    specify { expect(result[:attributes][0][:returned]).to eql('default') }
    specify { expect(result[:attributes][0][:uniqueness]).to eql('none') }
  end

  describe '.build' do
    subject do
      described_class.build(id: id, name: name, location: location) do |x|
        x.description = description
      end
    end

    specify { expect(result[:id]).to eql(id) }
    specify { expect(result[:name]).to eql(name) }
    specify { expect(result[:description]).to eql(description) }
    specify { expect(result[:meta][:resourceType]).to eql('Schema') }
    specify { expect(result[:meta][:location]).to eql(location) }
  end

  describe '.parse' do
    let(:result) { described_class.parse(subject.to_json) }

    context "with reference attribute type" do
      before do
        subject.add_attribute(name: :display_name) do |x|
          x.multi_valued = true
          x.required = true
          x.case_exact = true
          x.mutability = :read_only
          x.returned = :never
          x.uniqueness = :server
          x.canonical_values = ['honerva']
          x.reference_types = %w[User Group]
        end
      end

      specify { expect(result.id).to eql(subject.id) }
      specify { expect(result.name).to eql(subject.name) }
      specify { expect(result.description).to eql(subject.description) }
      specify { expect(result.meta.created).to eql(subject.meta.created) }
      specify { expect(result.meta.last_modified).to eql(subject.meta.last_modified) }
      specify { expect(result.meta.version).to eql(subject.meta.version) }
      specify { expect(result.meta.location).to eql(subject.meta.location) }
      specify { expect(result.meta.resource_type).to eql(subject.meta.resource_type) }
      specify { expect(result.attributes.size).to eql(1) }
      specify { expect(result.attributes.first.to_h).to eql(subject.attributes.first.to_h) }
      specify { expect(result.to_json).to eql(subject.to_json) }
      specify { expect(result.to_h).to eql(subject.to_h) }
    end

    context "with complex attribute type" do
      before do
        subject.add_attribute(name: :name) do |x|
          x.add_attribute(name: :family_name)
          x.add_attribute(name: :given_name)
        end
      end

      specify { expect(result.id).to eql(subject.id) }
      specify { expect(result.name).to eql(subject.name) }
      specify { expect(result.description).to eql(subject.description) }
      specify { expect(result.meta.created).to eql(subject.meta.created) }
      specify { expect(result.meta.last_modified).to eql(subject.meta.last_modified) }
      specify { expect(result.meta.version).to eql(subject.meta.version) }
      specify { expect(result.meta.location).to eql(subject.meta.location) }
      specify { expect(result.meta.resource_type).to eql(subject.meta.resource_type) }
      specify { expect(result.attributes.size).to eql(1) }
      specify { expect(result.attributes.first.to_h).to eql(subject.attributes.first.to_h) }
      specify { expect(result.to_json).to eql(subject.to_json) }
      specify { expect(result.to_h).to eql(subject.to_h) }
    end
  end
end
