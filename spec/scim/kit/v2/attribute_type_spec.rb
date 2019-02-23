# frozen_string_literal: true

RSpec.describe Scim::Kit::V2::AttributeType do
  let(:image) { Base64.strict_encode64(raw_image) }
  let(:raw_image) { IO.read('./spec/fixtures/avatar.png', mode: 'rb') }

  specify { expect { described_class.new(name: 'displayName', type: :string) }.not_to raise_error }
  specify { expect { described_class.new(name: 'primary', type: :boolean) }.not_to raise_error }
  specify { expect { described_class.new(name: 'salary', type: :decimal) }.not_to raise_error }
  specify { expect { described_class.new(name: 'age', type: :integer) }.not_to raise_error }
  specify { expect { described_class.new(name: 'birthdate', type: :datetime) }.not_to raise_error }
  specify { expect { described_class.new(name: '$ref', type: :reference) }.not_to raise_error }
  specify { expect { described_class.new(name: 'emails', type: :complex) }.not_to raise_error }
  specify { expect { described_class.new(name: 'photo', type: :binary) }.not_to raise_error }
  specify { expect { described_class.new(name: 'invalid', type: :invalid) }.to raise_error(ArgumentError) }

  describe 'with a symbolic name' do
    subject { described_class.new(name: :display_name) }

    specify { expect(subject.to_h[:name]).to eql('displayName') }
    specify { expect(subject.to_h[:description]).to eql('displayName') }
  end

  describe 'String Attribute' do
    describe 'defaults' do
      subject { described_class.new(name: 'displayName') }

      specify { expect(subject.name).to eql('display_name') }
      specify { expect(subject.type).to be(:string) }
      specify { expect(subject.to_h[:name]).to eql('displayName') }
      specify { expect(subject.to_h[:type]).to eql('string') }
      specify { expect(subject.to_h[:multiValued]).to be(false) }
      specify { expect(subject.to_h[:description]).to eql('displayName') }
      specify { expect(subject.to_h[:required]).to be(false) }
      specify { expect(subject.to_h[:caseExact]).to be(false) }
      specify { expect(subject.to_h[:mutability]).to eql('readWrite') }
      specify { expect(subject.to_h[:returned]).to eql('default') }
      specify { expect(subject.to_h[:uniqueness]).to eql('none') }
    end

    describe 'overrides' do
      def build(overrides)
        x = described_class.new(name: 'displayName')
        overrides.each do |(key, value)|
          x.public_send("#{key}=".to_sym, value)
        end
        x
      end

      specify { expect(build(multi_valued: true).to_h[:multiValued]).to be(true) }
      specify { expect(build(description: 'hello').to_h[:description]).to eq('hello') }
      specify { expect(build(required: true).to_h[:required]).to be(true) }
      specify { expect(build(case_exact: true).to_h[:caseExact]).to be(true) }

      specify { expect(build(mutability: :read_only).to_h[:mutability]).to eql('readOnly') }
      specify { expect(build(mutability: :read_write).to_h[:mutability]).to eql('readWrite') }
      specify { expect(build(mutability: :immutable).to_h[:mutability]).to eql('immutable') }
      specify { expect(build(mutability: :write_only).to_h[:mutability]).to eql('writeOnly') }
      specify { expect { build(mutability: :invalid) }.to raise_error(ArgumentError) }

      specify { expect(build(returned: :always).to_h[:returned]).to eql('always') }
      specify { expect(build(returned: :never).to_h[:returned]).to eql('never') }
      specify { expect(build(returned: :default).to_h[:returned]).to eql('default') }
      specify { expect(build(returned: :request).to_h[:returned]).to eql('request') }
      specify { expect { build(returned: :invalid) }.to raise_error(ArgumentError) }

      specify { expect(build(uniqueness: :none).to_h[:uniqueness]).to eql('none') }
      specify { expect(build(uniqueness: :server).to_h[:uniqueness]).to eql('server') }
      specify { expect(build(uniqueness: :global).to_h[:uniqueness]).to eql('global') }
      specify { expect { build(uniqueness: :invalid) }.to raise_error(ArgumentError) }

      specify { expect(build(reference_types: %w[User Group]).to_h[:referenceTypes]).to match_array(%w[User Group]) }
      specify { expect(build(canonical_values: %w[User Group]).to_h[:canonicalValues]).to match_array(%w[User Group]) }
    end
  end

  describe '#valid?' do
    specify { expect(described_class.new(name: :x, type: :binary)).to be_valid(image) }
    specify { expect(described_class.new(name: :x, type: :binary)).not_to be_valid('hello') }
    specify { expect(described_class.new(name: :x, type: :binary)).not_to be_valid(1) }
    specify { expect(described_class.new(name: :x, type: :binary)).not_to be_valid([1]) }

    specify { expect(described_class.new(name: :x, type: :boolean)).to be_valid(true) }
    specify { expect(described_class.new(name: :x, type: :boolean)).to be_valid(false) }
    specify { expect(described_class.new(name: :x, type: :boolean)).not_to be_valid('false') }
    specify { expect(described_class.new(name: :x, type: :boolean)).not_to be_valid(1) }

    specify { expect(described_class.new(name: :x, type: :datetime)).to be_valid(DateTime.now) }
    specify { expect(described_class.new(name: :x, type: :datetime)).not_to be_valid(DateTime.now.iso8601) }
    specify { expect(described_class.new(name: :x, type: :datetime)).not_to be_valid(Time.now.to_i) }
    specify { expect(described_class.new(name: :x, type: :datetime)).not_to be_valid(Time.now) }

    specify { expect(described_class.new(name: :x, type: :decimal)).to be_valid(1.0) }
    specify { expect(described_class.new(name: :x, type: :decimal)).not_to be_valid(1) }
    specify { expect(described_class.new(name: :x, type: :decimal)).not_to be_valid('1.0') }

    specify { expect(described_class.new(name: :x, type: :integer)).to be_valid(1) }
    specify { expect(described_class.new(name: :x, type: :integer)).to be_valid(1_000) }
    specify { expect(described_class.new(name: :x, type: :integer)).not_to be_valid(10.0) }
    specify { expect(described_class.new(name: :x, type: :integer)).not_to be_valid('10') }
    specify { expect(described_class.new(name: :x, type: :integer)).not_to be_valid([]) }

    specify { expect(described_class.new(name: :x, type: :reference)).to be_valid(FFaker::Internet.uri('https')) }
    specify { expect(described_class.new(name: :x, type: :reference)).not_to be_valid('hello') }
    specify { expect(described_class.new(name: :x, type: :reference)).not_to be_valid(1) }
    specify { expect(described_class.new(name: :x, type: :reference)).not_to be_valid(['hello']) }

    specify { expect(described_class.new(name: :x, type: :string)).to be_valid('name') }
    specify { expect(described_class.new(name: :x, type: :string)).not_to be_valid(1) }
    specify { expect(described_class.new(name: :x, type: :string)).not_to be_valid(['string']) }

    context 'when multi valued string type' do
      subject { described_class.new(name: :emails, type: :string) }

      let(:email) { FFaker::Internet.email }

      before do
        subject.multi_valued = true
      end

      specify { expect(subject).to be_valid([email]) }
      specify { expect(subject).not_to be_valid([1]) }
      specify { expect(subject).not_to be_valid(email) }
    end

    context 'when single valued complex type' do
      subject { described_class.new(name: :location, type: :complex) }

      before do
        subject.multi_valued = false
        subject.add_attribute(name: :name, type: :string)
        subject.add_attribute(name: :latitude, type: :integer)
        subject.add_attribute(name: :longitude, type: :integer)
      end

      specify { expect(subject).to be_valid(name: 'work', latitude: 100, longitude: 100) }
      specify { expect(subject).not_to be_valid([name: 'work', latitude: 100, longitude: 100]) }
      specify { expect(subject).not_to be_valid(name: 'work', latitude: 'wrong', longitude: 100) }
    end

    context 'when multi valued complex type' do
      subject { described_class.new(name: :emails, type: :complex) }

      let(:email) { FFaker::Internet.email }
      let(:other_email) { FFaker::Internet.email }

      before do
        subject.multi_valued = true
        subject.add_attribute(name: 'value', type: :string)
        subject.add_attribute(name: 'primary', type: :boolean)
      end

      specify { expect(subject).to be_valid([value: email, primary: true]) }
      specify { expect(subject).to be_valid([{ value: email, primary: true }, { value: other_email, primary: false }]) }
      specify { expect(subject).not_to be_valid(email) }
      specify { expect(subject).not_to be_valid([email]) }
      specify { expect(subject).not_to be_valid([value: 1, primary: true]) }
      specify { expect(subject).not_to be_valid([value: email, primary: 'true']) }
    end
  end

  describe '#coerce' do
    let(:now) { DateTime.now }
    let(:uri) { FFaker::Internet.uri('https') }

    specify { expect(described_class.new(name: :x, type: :binary).coerce(raw_image)).to eql(image) }
    specify { expect(described_class.new(name: :x, type: :binary).coerce(image)).to eql(image) }

    specify { expect(described_class.new(name: :x, type: :boolean).coerce(true)).to be(true) }
    specify { expect(described_class.new(name: :x, type: :boolean).coerce('true')).to be(true) }
    specify { expect(described_class.new(name: :x, type: :boolean).coerce(false)).to be(false) }
    specify { expect(described_class.new(name: :x, type: :boolean).coerce('false')).to be(false) }
    specify { expect(described_class.new(name: :x, type: :boolean).coerce('invalid')).to eql('invalid') }

    specify { expect(described_class.new(name: :x, type: :datetime).coerce(now)).to eql(now) }
    specify { expect(described_class.new(name: :x, type: :datetime).coerce(now.iso8601)).to be_within(1).of(now) }

    specify { expect(described_class.new(name: :x, type: :decimal).coerce(1.0)).to be(1.0) }
    specify { expect(described_class.new(name: :x, type: :decimal).coerce(1)).to be(1.0) }
    specify { expect(described_class.new(name: :x, type: :decimal).coerce('1.0')).to be(1.0) }
    specify { expect(described_class.new(name: :x, type: :decimal).coerce('1')).to be(1.0) }

    specify { expect(described_class.new(name: :x, type: :integer).coerce(1)).to be(1) }
    specify { expect(described_class.new(name: :x, type: :integer).coerce(1.0)).to be(1) }
    specify { expect(described_class.new(name: :x, type: :integer).coerce('1.0')).to be(1) }
    specify { expect(described_class.new(name: :x, type: :integer).coerce('1')).to be(1) }

    specify { expect(described_class.new(name: :x, type: :reference).coerce(uri)).to eql(uri) }
    specify { expect(described_class.new(name: :x, type: :reference).coerce('hello')).to eql('hello') }

    specify { expect(described_class.new(name: :x, type: :string).coerce('name')).to eql('name') }
    specify { expect(described_class.new(name: :x, type: :string).coerce(1)).to eql('1') }

    context 'when multi valued string type' do
      subject do
        x = described_class.new(name: :x, type: :string)
        x.multi_valued = true
        x
      end

      specify { expect(subject.coerce(['1'])).to match_array(['1']) }
      specify { expect(subject.coerce([1])).to match_array(['1']) }
    end

    context 'when single valued complex type' do
      subject { described_class.new(name: :location, type: :complex) }

      before do
        subject.multi_valued = false
        subject.add_attribute(name: :name, type: :string)
        subject.add_attribute(name: :latitude, type: :integer)
        subject.add_attribute(name: :longitude, type: :integer)
      end

      specify { expect(subject.coerce(name: 'work', latitude: 100, longitude: 100)).to eql(name: 'work', latitude: 100, longitude: 100) }
    end

    context 'when multi valued complex type' do
      subject { described_class.new(name: :emails, type: :complex) }

      let(:email) { FFaker::Internet.email }
      let(:other_email) { FFaker::Internet.email }

      before do
        subject.multi_valued = true
        subject.add_attribute(name: 'value', type: :string)
        subject.add_attribute(name: 'primary', type: :boolean)
      end

      specify { expect(subject.coerce([value: email, primary: true])).to match_array([value: email, primary: true]) }
      specify { expect(subject.coerce([{ value: email, primary: true }, { value: other_email, primary: false }])).to match_array([{ value: email, primary: true }, { value: other_email, primary: false }]) }
    end
  end
end
