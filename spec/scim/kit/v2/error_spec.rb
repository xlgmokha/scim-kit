# frozen_string_literal: true

RSpec.describe Scim::Kit::V2::Error do
  subject { described_class.new }

  before do
    subject.scim_type = :invalidSyntax
    subject.detail = 'error'
    subject.status = 400
  end

  specify { expect(subject.to_h[:schemas]).to match_array([Scim::Kit::V2::Messages::ERROR]) }
  specify { expect(subject.to_h[:scimType]).to eql('invalidSyntax') }
  specify { expect(subject.to_h[:detail]).to eql('error') }
  specify { expect(subject.to_h[:status]).to eql('400') }
end
