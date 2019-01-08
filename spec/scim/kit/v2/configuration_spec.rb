# frozen_string_literal: true

RSpec.describe Scim::Kit::V2::Configuration do
  subject do
    described_class.new do |x|
      x.service_provider_configuration(location: sp_location) do |y|
        y.add_authentication(:oauthbearertoken)
        y.change_password.supported = true
      end
    end
  end

  let(:sp_location) { FFaker::Internet.uri('https') }

  specify { expect(subject.service_provider_configuration.meta.location).to eql(sp_location) }
  specify { expect(subject.service_provider_configuration.authentication_schemes[0].type).to be(:oauthbearertoken) }
  specify { expect(subject.service_provider_configuration.change_password.supported).to be(true) }
end
