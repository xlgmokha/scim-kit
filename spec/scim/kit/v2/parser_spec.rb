# frozen_string_literal: true

RSpec.describe Scim::Kit::V2::Parser do
  subject { described_class.new }

  context "simple expression" do
    let(:expression) { %Q(userName eq "bjensen") }
    let(:result) { subject.pretty_parse(expression) }

    specify { expect(result).to be_present }
    specify { expect(result[:left].to_s).to eql('userName') }
    specify { expect(result[:operator].to_s).to eql('eq') }
    specify { expect(result[:right].to_s).to eql('bjensen') }
  end
end
