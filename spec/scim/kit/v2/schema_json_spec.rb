# frozen_string_literal: true

# Every document this gem renders is validated against the bundled
# lib/scim/kit/v2/schema.json, so generated output cannot drift from the RFC.
RSpec.describe 'lib/scim/kit/v2/schema.json' do
  let(:location) { FFaker::Internet.uri('https') }
  let(:user_urn) { Scim::Kit::V2::Schemas::USER }

  def errors_for(definition, document)
    Scim::Kit::V2::JsonSchema.entry_point(definition).errors_for(
      JSON.parse(document.to_json, symbolize_names: true)
    )
  end

  describe 'Meta' do
    specify { expect(errors_for('meta', Scim::Kit::V2::Meta.new('User', location))).to be_empty }
  end

  describe 'AttributeType' do
    specify { expect(errors_for('attribute', Scim::Kit::V2::AttributeType.new(name: 'userName'))).to be_empty }
  end

  describe 'Supportable' do
    specify { expect(errors_for('supported', Scim::Kit::V2::Supportable.new)).to be_empty }
    specify { expect(errors_for('supported', Scim::Kit::V2::Supportable.new(:max_results))).to be_empty }
  end

  describe 'AuthenticationScheme' do
    specify { expect(errors_for('authenticationScheme', Scim::Kit::V2::AuthenticationScheme.build_for(:oauthbearertoken))).to be_empty }
    specify { expect(errors_for('authenticationScheme', Scim::Kit::V2::AuthenticationScheme.build_for(:httpbasic))).to be_empty }
  end

  describe 'ServiceProviderConfiguration' do
    subject { Scim::Kit::V2::ServiceProviderConfiguration.new(location: location) }

    specify { expect(errors_for('serviceProviderConfig', subject)).to be_empty }

    it 'validates with an authentication scheme added' do
      subject.add_authentication(:oauthbearertoken)

      expect(errors_for('serviceProviderConfig', subject)).to be_empty
    end
  end

  describe 'Schema' do
    subject do
      Scim::Kit::V2::Schema.build(id: user_urn, name: 'User', location: location) do |x|
        x.add_attribute(name: 'userName') { |y| y.required = true }
        x.add_attribute(name: 'emails') do |y|
          y.multi_valued = true
          y.add_attribute(name: 'value')
        end
      end
    end

    specify { expect(errors_for('schema', subject)).to be_empty }
  end

  describe 'ResourceType' do
    subject do
      Scim::Kit::V2::ResourceType.build(location: location) do |x|
        x.id = 'User'
        x.name = 'User'
        x.endpoint = '/Users'
        x.schema = user_urn
        x.add_schema_extension(schema: 'urn:x:Staff', required: true)
      end
    end

    specify { expect(errors_for('resourceType', subject)).to be_empty }
  end

  # A resource has no fixed shape, so it is checked against the JSON Schema
  # derived from the very Schema resource it was built from.
  describe 'Resource' do
    let(:schema) do
      Scim::Kit::V2::Schema.build(id: user_urn, name: 'User', location: location) do |x|
        x.add_attribute(name: 'userName') { |y| y.required = true }
      end
    end
    let(:resource) do
      Scim::Kit::V2::Resource.new(schemas: [schema], location: location).tap do |x|
        x.id = SecureRandom.uuid
        x.user_name = 'mo'
      end
    end
    let(:derived) { Scim::Kit::V2::JsonSchema.new(schema.to_json_schema) }

    specify { expect(derived.errors_for(JSON.parse(resource.to_json, symbolize_names: true))).to be_empty }
  end

  describe 'coverage' do
    let(:templated) do
      Dir[File.expand_path('../../../../lib/scim/kit/v2/templates/*.json.jbuilder', __dir__)]
        .map { |path| File.basename(path, '.json.jbuilder').camelize }
        .reject { |name| name == 'NilClass' }
    end
    # Attribute renders one attribute of a resource, so it has no document of
    # its own and is covered by the Resource example above.
    let(:described_here) do
      %w[Meta AttributeType Supportable AuthenticationScheme
         ServiceProviderConfiguration Schema ResourceType Resource Attribute]
    end

    specify { expect(templated - described_here).to be_empty }
  end
end
