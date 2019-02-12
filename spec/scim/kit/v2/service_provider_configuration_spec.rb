# frozen_string_literal: true

RSpec.describe Scim::Kit::V2::ServiceProviderConfiguration do
  subject { described_class.new(location: location) }

  let(:location) { FFaker::Internet.uri('https') }
  let(:now) { Time.now }

  describe '#to_json' do
    let(:result) { JSON.parse(subject.to_json, symbolize_names: true) }

    specify { expect(result[:schemas]).to match_array(['urn:ietf:params:scim:schemas:core:2.0:ServiceProviderConfig']) }
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

    context 'with documentation uri' do
      before do
        subject.documentation_uri = FFaker::Internet.uri('https')
      end

      specify { expect(result[:documentationUri]).to eql(subject.documentation_uri) }
    end

    context 'with OAuth Bearer Token' do
      before { subject.add_authentication(:oauthbearertoken) }

      specify { expect(result[:authenticationSchemes][0][:name]).to eql('OAuth Bearer Token') }
      specify { expect(result[:authenticationSchemes][0][:description]).to eql('Authentication scheme using the OAuth Bearer Token Standard') }
      specify { expect(result[:authenticationSchemes][0][:specUri]).to eql('http://www.rfc-editor.org/info/rfc6750') }
      specify { expect(result[:authenticationSchemes][0][:documentationUri]).to eql('http://example.com/help/oauth.html') }
      specify { expect(result[:authenticationSchemes][0][:type]).to eql('oauthbearertoken') }
    end

    context 'with http basic' do
      before { subject.add_authentication(:httpbasic) }

      specify { expect(result[:authenticationSchemes][0][:name]).to eql('HTTP Basic') }
      specify { expect(result[:authenticationSchemes][0][:description]).to eql('Authentication scheme using the HTTP Basic Standard') }
      specify { expect(result[:authenticationSchemes][0][:specUri]).to eql('http://www.rfc-editor.org/info/rfc2617') }
      specify { expect(result[:authenticationSchemes][0][:documentationUri]).to eql('http://example.com/help/httpBasic.html') }
      specify { expect(result[:authenticationSchemes][0][:type]).to eql('httpbasic') }
    end

    context 'with multiple schemes' do
      before do
        subject.add_authentication(:oauthbearertoken, primary: true)
        subject.add_authentication(:httpbasic)
      end

      specify { expect(result[:authenticationSchemes][0][:name]).to eql('OAuth Bearer Token') }
      specify { expect(result[:authenticationSchemes][0][:description]).to eql('Authentication scheme using the OAuth Bearer Token Standard') }
      specify { expect(result[:authenticationSchemes][0][:specUri]).to eql('http://www.rfc-editor.org/info/rfc6750') }
      specify { expect(result[:authenticationSchemes][0][:documentationUri]).to eql('http://example.com/help/oauth.html') }
      specify { expect(result[:authenticationSchemes][0][:type]).to eql('oauthbearertoken') }
      specify { expect(result[:authenticationSchemes][0][:primary]).to be(true) }

      specify { expect(result[:authenticationSchemes][1][:name]).to eql('HTTP Basic') }
      specify { expect(result[:authenticationSchemes][1][:description]).to eql('Authentication scheme using the HTTP Basic Standard') }
      specify { expect(result[:authenticationSchemes][1][:specUri]).to eql('http://www.rfc-editor.org/info/rfc2617') }
      specify { expect(result[:authenticationSchemes][1][:documentationUri]).to eql('http://example.com/help/httpBasic.html') }
      specify { expect(result[:authenticationSchemes][1][:type]).to eql('httpbasic') }
    end

    context 'with custom scheme' do
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

    context 'with etag support' do
      before { subject.etag.supported = true }

      specify { expect(result[:etag][:supported]).to be(true) }
    end

    context 'with sort support' do
      before { subject.sort.supported = true }

      specify { expect(result[:sort][:supported]).to be(true) }
    end

    context 'with change_password support' do
      before { subject.change_password.supported = true }

      specify { expect(result[:changePassword][:supported]).to be(true) }
    end

    context 'with patch support' do
      before { subject.patch.supported = true }

      specify { expect(result[:patch][:supported]).to be(true) }
    end

    context 'with bulk support' do
      before do
        subject.bulk.supported = true
        subject.bulk.max_operations = 1000
        subject.bulk.max_payload_size = 1_048_576
      end

      specify { expect(result[:bulk][:supported]).to be(true) }
      specify { expect(result[:bulk][:maxOperations]).to be(1000) }
      specify { expect(result[:bulk][:maxPayloadSize]).to be(1_048_576) }
    end

    context 'with filter support' do
      before do
        subject.filter.supported = true
        subject.filter.max_results = 200
      end

      specify { expect(result[:filter][:supported]).to be(true) }
      specify { expect(result[:filter][:maxResults]).to be(200) }
    end
  end

  describe ".parse" do
    let(:result) { described_class.parse(subject.to_json) }

    before do
      #subject.add_authentication(:oauthbearertoken)
      subject.bulk.max_operations = 1000
      subject.bulk.max_payload_size = 1_048_576
      subject.bulk.supported = true
      subject.change_password.supported = true
      subject.documentation_uri = FFaker::Internet.uri('https')
      subject.etag.supported = true
      subject.filter.max_results = 200
      subject.filter.supported = true
      subject.patch.supported = true
      subject.sort.supported = true
    end

    specify { expect(result.meta.created.to_i).to eql(subject.meta.created.to_i) }
    specify { expect(result.meta.last_modified.to_i).to eql(subject.meta.last_modified.to_i) }
    specify { expect(result.meta.version).to eql(subject.meta.version) }
    specify { expect(result.meta.location).to eql(subject.meta.location) }
    specify { expect(result.meta.resource_type).to eql(subject.meta.resource_type) }
    specify { expect(result.to_json).to eql(subject.to_json) }
    specify { expect(result.to_h).to eql(subject.to_h) }
  end
end
