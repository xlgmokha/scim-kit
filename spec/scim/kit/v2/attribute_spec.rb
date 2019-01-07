# frozen_string_literal: true

RSpec.describe Scim::Kit::V2::Attribute do
  subject { described_class.new(type: type) }

  context 'with strings' do
    let(:type) { Scim::Kit::V2::AttributeType.new(name: 'userName', type: :string) }

    context 'when valid' do
      let(:user_name) { FFaker::Internet.user_name }

      before { subject.value = user_name }

      specify { expect(subject.value).to eql(user_name) }
    end

    context 'when integer' do
      let(:number) { rand(100) }

      before { subject.value = number }

      specify { expect(subject.value).to eql(number.to_s) }
    end

    context 'when datetime' do
      let(:datetime) { DateTime.now }

      before { subject.value = datetime }

      specify { expect(subject.value).to eql(datetime.to_s) }
    end

    context 'when not matching a canonical value' do
      before { type.canonical_values = %w[batman robin] }

      specify { expect { subject.value = 'spider man' }.to raise_error(ArgumentError) }
    end

    context 'when canonical value is given' do
      before do
        type.canonical_values = %w[batman robin]
        subject.value = 'batman'
      end

      specify { expect(subject.value).to eql('batman') }
    end
  end

  context 'with boolean' do
    let(:type) { Scim::Kit::V2::AttributeType.new(name: 'hungry', type: :boolean) }

    context 'when true' do
      before { subject.value = true }

      specify { expect(subject.value).to be(true) }
    end

    context 'when false' do
      before { subject.value = false }

      specify { expect(subject.value).to be(false) }
    end

    context 'when string' do
      specify { expect { subject.value = 'hello' }.to raise_error(ArgumentError) }
    end
  end

  context 'with decimal' do
    let(:type) { Scim::Kit::V2::AttributeType.new(name: 'measurement', type: :decimal) }

    context 'when given float' do
      before { subject.value = Math::PI }

      specify { expect(subject.value).to eql(Math::PI) }
    end

    context 'when given an integer' do
      before { subject.value = 42 }

      specify { expect(subject.value).to eql(42.to_f) }
    end
  end

  context 'with integer' do
    let(:type) { Scim::Kit::V2::AttributeType.new(name: 'age', type: :integer) }

    context 'when given integer' do
      before { subject.value = 34 }

      specify { expect(subject.value).to be(34) }
    end

    context 'when given float' do
      before { subject.value = Math::PI }

      specify { expect(subject.value).to eql(Math::PI.to_i) }
    end
  end

  context 'with datetime' do
    let(:type) { Scim::Kit::V2::AttributeType.new(name: 'birthdate', type: :datetime) }
    let(:datetime) { DateTime.new(2019, 0o1, 0o6, 12, 35, 0o0) }

    context 'when given a date time' do
      before { subject.value = datetime }

      specify { expect(subject.value).to eql(datetime) }
    end

    context 'when given a string' do
      before { subject.value = datetime.to_s }

      specify { expect(subject.value).to eql(datetime) }
    end
  end

  context 'with binary' do
    let(:type) { Scim::Kit::V2::AttributeType.new(name: 'photo', type: :binary) }
    let(:photo) { IO.read('./spec/fixtures/avatar.png', mode: 'rb') }

    context 'when given a .png' do
      before { subject.value = photo }

      specify { expect(subject.value).to eql(Base64.strict_encode64(photo)) }
    end
  end

  context 'with reference' do
    let(:type) { Scim::Kit::V2::AttributeType.new(name: 'group', type: :reference) }
    let(:uri) { FFaker::Internet.uri('https') }

    before { subject.value = uri }

    specify { expect(subject.value).to eql(uri) }
  end
end
