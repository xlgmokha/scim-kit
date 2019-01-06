# frozen_string_literal: true

RSpec.describe Scim::Kit::V2::Attribute do
  subject { described_class.new(type: type) }

  context 'with custom string attribute' do
    let(:type) { Scim::Kit::V2::AttributeType.new(name: 'userName', type: :string) }
    let(:user_name) { FFaker::Internet.user_name }

    before { subject.value = user_name }

    specify { expect(subject.value).to eql(user_name) }
  end
end
