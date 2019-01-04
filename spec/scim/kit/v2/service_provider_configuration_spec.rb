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

    context "with OAuth Bearer Token" do
      before { subject.add_authentication(:oauthbearertoken) }

      specify do
        expect(result[:authenticationSchemes]).to match_array([{
          name: 'OAuth Bearer Token',
          description: 'Authentication scheme using the OAuth Bearer Token Standard',
          specUri: 'http://www.rfc-editor.org/info/rfc6750',
          documentationUri: 'http://example.com/help/oauth.html',
          type: 'oauthbearertoken',
        }])
      end
    end

    context "with http basic" do
      before { subject.add_authentication(:httpbasic) }

      specify do
        expect(result[:authenticationSchemes]).to match_array([{
          name: 'HTTP Basic',
          description: 'Authentication scheme using the HTTP Basic Standard',
          specUri: 'http://www.rfc-editor.org/info/rfc2617',
          documentationUri: 'http://example.com/help/httpBasic.html',
          type: 'httpbasic',
        }])
      end
    end

    context "with custom scheme" do
      before do
        subject.add_authentication(:custom) do |x|
          x.name = 'custom'
          x.description = 'custom'
          x.spec_uri = 'http://www.rfc-editor.org/info/rfcXXXX'
          x.documentation_uri = 'http://example.com/help/custom.html'
        end
      end

      specify { expect(result[:authenticationSchemes][0][:name]).to eql('custom') }
      specify { expect(result[:authenticationSchemes][0][:description]).to eql('custom') }
      specify { expect(result[:authenticationSchemes][0][:specUri]).to eql('http://www.rfc-editor.org/info/rfcXXXX') }
      specify { expect(result[:authenticationSchemes][0][:documentationUri]).to eql('http://example.com/help/custom.html') }
      specify { expect(result[:authenticationSchemes][0][:type]).to eql('custom') }
    end
  end
end
