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
      specify { expect(subject.as_json[:externalId]).to be_nil } # only render in client mode
      specify { expect(subject.as_json[:meta][:resourceType]).to eql('User') }
      specify { expect(subject.as_json[:meta][:location]).to eql(resource_location) }
      specify { expect(subject.as_json[:meta][:created]).to eql(created_at.iso8601) }
      specify { expect(subject.as_json[:meta][:lastModified]).to eql(updated_at.iso8601) }
      specify { expect(subject.as_json[:meta][:version]).to eql(version) }
    end
  end

  context 'with attribute named "type"' do
    before do
      schema.add_attribute(name: 'members') do |attribute|
        attribute.mutability = :read_only
        attribute.multi_valued = true
        attribute.add_attribute(name: 'value') do |z|
          z.mutability = :immutable
        end
        attribute.add_attribute(name: '$ref') do |z|
          z.reference_types = %w[User Group]
          z.mutability = :immutable
        end
        attribute.add_attribute(name: 'type') do |z|
          z.canonical_values = %w[User Group]
          z.mutability = :immutable
        end
      end
      subject.members << { value: SecureRandom.uuid, '$ref' => FFaker::Internet.uri('https'), type: 'User' }
    end

    specify { expect(subject.members[0][:type]).to eql('User') }
    specify { expect(subject.as_json[:members][0][:type]).to eql('User') }
    specify { expect(subject.to_h[:members][0][:type]).to eql('User') }
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
    specify { expect(subject.send(:attribute_for, :type)._type).to be_instance_of(Scim::Kit::V2::AttributeType) }
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
      schema.add_attribute(name: :country)
      extension.add_attribute(name: :province)
      subject.country = 'canada'
      subject.province = 'alberta'
    end

    specify { expect(subject.country).to eql('canada') }
    specify { expect(subject.province).to eql('alberta') }
    specify { expect(subject.as_json[:country]).to eql('canada') }
    specify { expect(subject.as_json[extension_id][:province]).to eql('alberta') }
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

  context 'when building a new resource' do
    subject { described_class.new(schemas: schemas) }

    before do
      schema.add_attribute(name: 'userName') do |attribute|
        attribute.required = true
        attribute.uniqueness = :server
      end
      schema.add_attribute(name: 'name') do |attribute|
        attribute.add_attribute(name: 'formatted') do |x|
          x.mutability = :read_only
        end
        attribute.add_attribute(name: 'familyName')
        attribute.add_attribute(name: 'givenName')
      end
      schema.add_attribute(name: 'displayName') do |attribute|
        attribute.mutability = :read_only
      end
      schema.add_attribute(name: 'locale')
      schema.add_attribute(name: 'timezone')
      schema.add_attribute(name: 'active', type: :boolean)
      schema.add_attribute(name: 'password') do |attribute|
        attribute.mutability = :write_only
        attribute.returned = :never
      end
      schema.add_attribute(name: 'emails') do |attribute|
        attribute.multi_valued = true
        attribute.add_attribute(name: 'value')
        attribute.add_attribute(name: 'primary', type: :boolean)
      end
      schema.add_attribute(name: 'groups') do |attribute|
        attribute.multi_valued = true
        attribute.mutability = :read_only
        attribute.add_attribute(name: 'value') do |x|
          x.mutability = :read_only
        end
        attribute.add_attribute(name: '$ref') do |x|
          x.reference_types = %w[User Group]
          x.mutability = :read_only
        end
        attribute.add_attribute(name: 'display') do |x|
          x.mutability = :read_only
        end
      end
    end

    specify { expect(subject.as_json.key?(:meta)).to be(false) }
    specify { expect(subject.as_json.key?(:id)).to be(false) }
    specify { expect(subject.as_json.key?(:externalId)).to be(false) }

    context 'when using a simplified API' do
      let(:user_name) { FFaker::Internet.user_name }
      let(:resource) do
        described_class.new(schemas: schemas) do |x|
          x.user_name = user_name
          x.name.given_name = 'Barbara'
          x.name.family_name = 'Jensen'
          x.emails = [
            { value: FFaker::Internet.email, primary: true },
            { value: FFaker::Internet.email, primary: false }
          ]
          x.locale = 'en'
          x.timezone = 'Etc/UTC'
        end
      end

      specify { expect(resource.user_name).to eql(user_name) }
      specify { expect(resource.name.given_name).to eql('Barbara') }
      specify { expect(resource.name.family_name).to eql('Jensen') }
      specify { expect(resource.emails[0][:value]).to be_present }
      specify { expect(resource.emails[0][:primary]).to be(true) }
      specify { expect(resource.emails[1][:value]).to be_present }
      specify { expect(resource.emails[1][:primary]).to be(false) }
      specify { expect(resource.locale).to eql('en') }
      specify { expect(resource.timezone).to eql('Etc/UTC') }

      specify { expect(resource.to_h[:userName]).to eql(user_name) }
      specify { expect(resource.to_h[:name][:givenName]).to eql('Barbara') }
      specify { expect(resource.to_h[:name][:familyName]).to eql('Jensen') }
      specify { expect(resource.to_h[:emails][0][:value]).to be_present }
      specify { expect(resource.to_h[:emails][0][:primary]).to be(true) }
      specify { expect(resource.to_h[:emails][1][:value]).to be_present }
      specify { expect(resource.to_h[:emails][1][:primary]).to be(false) }
      specify { expect(resource.to_h[:locale]).to eql('en') }
      specify { expect(resource.to_h[:timezone]).to eql('Etc/UTC') }
      specify { expect(resource.to_h.key?(:meta)).to be(false) }
      specify { expect(resource.to_h.key?(:id)).to be(false) }
      specify { expect(resource.to_h.key?(:external_id)).to be(false) }
    end

    context 'when building in client mode' do
      subject { described_class.new(schemas: schemas) }

      let(:external_id) { SecureRandom.uuid }

      before do
        subject.password = FFaker::Internet.password
        subject.external_id = external_id
      end

      specify { expect(subject.to_h.key?(:id)).to be(false) }
      specify { expect(subject.to_h.key?(:externalId)).to be(true) }
      specify { expect(subject.to_h[:externalId]).to eql(external_id) }
      specify { expect(subject.to_h.key?(:meta)).to be(false) }
      specify { expect(subject.to_h.key?(:userName)).to be(true) }
      specify { expect(subject.to_h[:name].key?(:formatted)).to be(false) }
      specify { expect(subject.to_h[:name].key?(:familyName)).to be(true) }
      specify { expect(subject.to_h[:name].key?(:givenName)).to be(true) }
      specify { expect(subject.to_h.key?(:displayName)).to be(false) }
      specify { expect(subject.to_h.key?(:locale)).to be(true) }
      specify { expect(subject.to_h.key?(:timezone)).to be(true) }
      specify { expect(subject.to_h.key?(:active)).to be(true) }
      specify { expect(subject.to_h.key?(:password)).to be(true) }
      specify { expect(subject.to_h.key?(:emails)).to be(true) }
      specify { expect(subject.to_h.key?(:groups)).to be(false) }
    end

    context 'when building in server mode' do
      subject { described_class.new(schemas: schemas, location: resource_location) }

      before do
        subject.external_id = SecureRandom.uuid
      end

      specify { expect(subject.to_h.key?(:id)).to be(true) }
      specify { expect(subject.to_h.key?(:externalId)).to be(false) }
      specify { expect(subject.to_h.key?(:meta)).to be(true) }
      specify { expect(subject.to_h.key?(:userName)).to be(true) }
      specify { expect(subject.to_h[:name].key?(:formatted)).to be(true) }
      specify { expect(subject.to_h[:name].key?(:familyName)).to be(true) }
      specify { expect(subject.to_h[:name].key?(:givenName)).to be(true) }
      specify { expect(subject.to_h.key?(:displayName)).to be(true) }
      specify { expect(subject.to_h.key?(:locale)).to be(true) }
      specify { expect(subject.to_h.key?(:timezone)).to be(true) }
      specify { expect(subject.to_h.key?(:active)).to be(true) }
      specify { expect(subject.to_h.key?(:password)).to be(false) }
      specify { expect(subject.to_h.key?(:emails)).to be(true) }
      specify { expect(subject.to_h.key?(:groups)).to be(true) }
    end
  end

  describe '#mode?' do
    context 'when server mode' do
      subject { described_class.new(schemas: schemas, location: resource_location) }

      specify { expect(subject).to be_mode(:server) }
      specify { expect(subject).not_to be_mode(:client) }
    end

    context 'when client mode' do
      subject { described_class.new(schemas: schemas) }

      specify { expect(subject).not_to be_mode(:server) }
      specify { expect(subject).to be_mode(:client) }
    end
  end

  describe '#assign_attributes' do
    context 'with a simple string attribute' do
      let(:user_name) { FFaker::Internet.user_name }

      before do
        schema.add_attribute(name: 'userName')
        subject.assign_attributes(userName: user_name)
      end

      specify { expect(subject.user_name).to eql(user_name) }
    end

    context 'with a simple integer attribute' do
      before do
        schema.add_attribute(name: 'age', type: :integer)
        subject.assign_attributes(age: 34)
      end

      specify { expect(subject.age).to be(34) }
    end

    context 'with a multi-valued simple string attribute' do
      before do
        schema.add_attribute(name: 'colours', type: :string) do |x|
          x.multi_valued = true
        end
        subject.assign_attributes(colours: ['red', 'green', :blue])
      end

      specify { expect(subject.colours).to match_array(%w[red green blue]) }
    end

    context 'with a single complex attribute' do
      before do
        schema.add_attribute(name: :name) do |x|
          x.add_attribute(name: :given_name)
          x.add_attribute(name: :family_name)
        end
        subject.assign_attributes(name: { givenName: 'Tsuyoshi', familyName: 'Garrett' })
      end

      specify { expect(subject.name.given_name).to eql('Tsuyoshi') }
      specify { expect(subject.name.family_name).to eql('Garrett') }
    end

    context 'with a multi-valued complex attribute' do
      let(:email) { FFaker::Internet.email }
      let(:other_email) { FFaker::Internet.email }

      before do
        schema.add_attribute(name: :emails) do |x|
          x.multi_valued = true
          x.add_attribute(name: :value)
          x.add_attribute(name: :primary, type: :boolean)
        end
        subject.assign_attributes(emails: [
                                    { value: email, primary: true },
                                    { value: other_email, primary: false }
                                  ])
      end

      specify do
        expect(subject.emails).to match_array([
                                                { value: email, primary: true },
                                                { value: other_email, primary: false }
                                              ])
      end

      specify { expect(subject.emails[0][:value]).to eql(email) }
      specify { expect(subject.emails[0][:primary]).to be(true) }
      specify { expect(subject.emails[1][:value]).to eql(other_email) }
      specify { expect(subject.emails[1][:primary]).to be(false) }
    end

    context 'with an extension schema' do
      let(:schemas) { [schema, extension] }
      let(:extension) { Scim::Kit::V2::Schema.new(id: extension_id, name: 'Extension', location: FFaker::Internet.uri('https')) }
      let(:extension_id) { Scim::Kit::V2::Schemas::ENTERPRISE_USER }

      before do
        extension.add_attribute(name: :preferred_name)
        subject.assign_attributes(
          extension_id => { preferredName: 'hunk' }
        )
      end

      specify { expect(subject.preferred_name).to eql('hunk') }
    end
  end
end
