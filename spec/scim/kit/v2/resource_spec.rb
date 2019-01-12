# frozen_string_literal: true

RSpec.describe Scim::Kit::V2::Resource do
  subject { described_class.new(schemas: schemas, location: resource_location) }

  let(:schemas) { [schema] }
  let(:schema) { Scim::Kit::V2::Schema.new(id: Scim::Kit::V2::Schemas::USER, name: 'User', location: FFaker::Internet.uri('https')) }
  let(:resource_location) { FFaker::Internet.uri('https') }

  context 'with common attributes' do
    let(:id) { SecureRandom.uuid }
    let(:external_id) { SecureRandom.uuid }
    let(:created_at) { Time.now }
    let(:updated_at) { Time.now }
    let(:version) { SecureRandom.uuid }

    before do
      subject.id = id
      subject.external_id = external_id
      subject.meta.created = created_at
      subject.meta.last_modified = updated_at
      subject.meta.version = version
    end

    specify { expect(subject.id).to eql(id) }
    specify { expect(subject.external_id).to eql(external_id) }
    specify { expect(subject.meta.resource_type).to eql('User') }
    specify { expect(subject.meta.location).to eql(resource_location) }
    specify { expect(subject.meta.created).to eql(created_at) }
    specify { expect(subject.meta.last_modified).to eql(updated_at) }
    specify { expect(subject.meta.version).to eql(version) }

    describe '#as_json' do
      specify { expect(subject.as_json[:schemas]).to match_array([schema.id]) }
      specify { expect(subject.as_json[:id]).to eql(id) }
      specify { expect(subject.as_json[:externalId]).to eql(external_id) }
      specify { expect(subject.as_json[:meta][:resourceType]).to eql('User') }
      specify { expect(subject.as_json[:meta][:location]).to eql(resource_location) }
      specify { expect(subject.as_json[:meta][:created]).to eql(created_at.iso8601) }
      specify { expect(subject.as_json[:meta][:lastModified]).to eql(updated_at.iso8601) }
      specify { expect(subject.as_json[:meta][:version]).to eql(version) }
    end
  end

  context 'with custom string attribute' do
    let(:user_name) { FFaker::Internet.user_name }

    before do
      schema.add_attribute(name: 'userName')
      subject.user_name = user_name
    end

    specify { expect(subject.user_name).to eql(user_name) }
  end

  context 'with attribute named "type"' do
    before do
      schema.add_attribute(name: 'type')
      subject.type = 'User'
    end

    specify { expect(subject.type).to eql('User') }
    specify { expect(subject.as_json[:type]).to eql('User') }
    specify { expect(subject.send(:attribute_for, :type).type).to be_instance_of(Scim::Kit::V2::AttributeType) }
  end

  context 'with a complex attribute' do
    before do
      schema.add_attribute(name: 'name') do |x|
        x.add_attribute(name: 'familyName')
        x.add_attribute(name: 'givenName')
      end
      subject.name.family_name = 'Garrett'
      subject.name.given_name = 'Tsuyoshi'
    end

    specify { expect(subject.name.family_name).to eql('Garrett') }
    specify { expect(subject.name.given_name).to eql('Tsuyoshi') }

    describe '#as_json' do
      specify { expect(subject.as_json[:name][:familyName]).to eql('Garrett') }
      specify { expect(subject.as_json[:name][:givenName]).to eql('Tsuyoshi') }
    end
  end

  context 'with a complex multi valued attribute' do
    let(:email) { FFaker::Internet.email }
    let(:other_email) { FFaker::Internet.email }

    before do
      schema.add_attribute(name: 'emails', type: :complex) do |x|
        x.multi_valued = true
        x.add_attribute(name: 'value')
        x.add_attribute(name: 'primary', type: :boolean)
      end
      subject.emails = [
        { value: email, primary: true },
        { value: other_email, primary: false }
      ]
    end

    specify { expect(subject.emails).to match_array([{ value: email, primary: true }, { value: other_email, primary: false }]) }
    specify { expect(subject.as_json[:emails]).to match_array([{ value: email, primary: true }, { value: other_email, primary: false }]) }
  end

  context 'with multiple schemas' do
    let(:schemas) { [schema, extension] }
    let(:extension) { Scim::Kit::V2::Schema.new(id: extension_id, name: 'Extension', location: FFaker::Internet.uri('https')) }
    let(:extension_id) { 'urn:ietf:params:scim:schemas:extension:enterprise:2.0:User' }

    before do
      extension.add_attribute(name: :department)
      subject.department = 'voltron'
    end

    specify { expect(subject.department).to eql('voltron') }
    specify { expect(subject.as_json[extension_id][:department]).to eql('voltron') }
  end

  describe '#valid?' do
    context 'when invalid' do
      before { subject.valid? }

      specify { expect(subject).not_to be_valid }
      specify { expect(subject.errors[:id]).to be_present }
    end

    context 'when valid' do
      before { subject.id = SecureRandom.uuid }

      specify { expect(subject).to be_valid }
    end

    context 'when a required simple attribute is blank' do
      before do
        schema.add_attribute(name: 'userName') do |x|
          x.required = true
        end
        subject.id = SecureRandom.uuid
        subject.valid?
      end

      specify { expect(subject).not_to be_valid }
      specify { expect(subject.errors[:user_name]).to be_present }
    end

    context 'when not matching a canonical value' do
      before do
        schema.add_attribute(name: 'hero') do |x|
          x.canonical_values = %w[batman robin]
        end
        subject.id = SecureRandom.uuid
        subject.hero = 'spiderman'
        subject.valid?
      end

      specify { expect(subject).not_to be_valid }
      specify { expect(subject.errors[:hero]).to be_present }
    end
  end

  context 'when submitting new record' do
    subject { described_class.new(schemas: schemas, location: nil) }

    specify { expect(subject.as_json.key?(:meta)).to be(false) }
    specify { expect(subject.as_json.key?(:id)).to be(false) }
    specify { expect(subject.as_json.key?(:externalId)).to be(false) }
  end
end
