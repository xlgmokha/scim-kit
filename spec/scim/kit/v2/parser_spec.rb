# frozen_string_literal: true

RSpec.describe Scim::Kit::V2::Parser do
  subject { described_class.new }

  [ "eq", "ne", "co", "sw", "ew", "gt", "lt", "ge", "le" ].each do |operator|
    context "simple expression #{operator}" do
      let(:expression) { %Q(userName #{operator} "bjensen") }
      let(:result) { subject.pretty_parse(expression) }

      specify { expect(result).to be_present }
      specify { expect(result[:left].to_s).to eql('userName') }
      specify { expect(result[:operator].to_s).to eql(operator) }
      specify { expect(result[:right].to_s).to eql('bjensen') }
    end
  end
end
