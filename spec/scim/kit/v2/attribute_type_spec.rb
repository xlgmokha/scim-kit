# frozen_string_literal: true

RSpec.describe Scim::Kit::V2::AttributeType do
  specify { expect { described_class.new(name: 'displayName', type: :string) }.not_to raise_error }
  specify { expect { described_class.new(name: 'primary', type: :boolean) }.not_to raise_error }
  specify { expect { described_class.new(name: 'salary', type: :decimal) }.not_to raise_error }
  specify { expect { described_class.new(name: 'age', type: :integer) }.not_to raise_error }
  specify { expect { described_class.new(name: 'birthdate', type: :datetime) }.not_to raise_error }
  specify { expect { described_class.new(name: '$ref', type: :reference) }.not_to raise_error }
  specify { expect { described_class.new(name: 'emails', type: :complex) }.not_to raise_error }
  specify { expect { described_class.new(name: 'photo', type: :binary) }.not_to raise_error }
  specify { expect { described_class.new(name: 'invalid', type: :invalid) }.to raise_error(ArgumentError) }

  describe 'String Attribute' do
    describe 'defaults' do
      subject { described_class.new(name: 'displayName') }

      specify { expect(subject.name).to eql('displayName') }
      specify { expect(subject.type).to be(:string) }
      specify { expect(subject.to_h[:name]).to eql('displayName') }
      specify { expect(subject.to_h[:type]).to eql('string') }
      specify { expect(subject.to_h[:multiValued]).to be(false) }
      specify { expect(subject.to_h[:description]).to eql('') }
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
    end
  end
end
