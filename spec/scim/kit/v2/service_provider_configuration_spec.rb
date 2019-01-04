# frozen_string_literal: true

RSpec.describe Scim::Kit::V2::ServiceProviderConfiguration do
  subject { described_class.new(location: location) }
  let(:location) { FFaker::Internet.uri('https') }
  let(:now) { Time.now }

  describe "#to_json" do
    let(:result) { JSON.parse(subject.to_json, symbolize_names: true) }

    specify { expect(result[:schemas]).to match_array(["urn:ietf:params:scim:schemas:core:2.0:ServiceProviderConfig"]) }
    specify { expect(result[:documentationUri]).to be_blank }
    specify { expect(result[:patch][:supported]).to be(false) }
    specify { expect(result[:bulk][:supported]).to be(false) }
    specify { expect(result[:filter][:supported]).to be(false) }
    specify { expect(result[:changePassword][:supported]).to be(false) }
    specify { expect(result[:sort][:supported]).to be(false) }
    specify { expect(result[:etag][:supported]).to be(false) }
    specify { expect(result[:authenticationSchemes]).to be_empty }
    specify { expect(result[:meta][:location]).to eql(location) }
    specify { expect(result[:meta][:resourceType]).to eql('ServiceProviderConfig') }
    specify { expect(result[:meta][:created]).to eql(now.iso8601) }
    specify { expect(result[:meta][:lastModified]).to eql(now.iso8601) }
    specify { expect(result[:meta][:version]).not_to be_nil }

    context "with documentation uri" do
      before do
        subject.documentation_uri = FFaker::Internet.uri('https')
      end

      specify { expect(result[:documentationUri]).to eql(subject.documentation_uri) }
    end
  end
end
