# frozen_string_literal: true

RSpec.describe Scim::Kit::V2::AttributeType do
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
        described_class.new(name: 'displayName', overrides: overrides)
      end

      specify { expect(build(multiValued: true).to_h[:multiValued]).to be(true) }
      specify { expect(build(description: 'hello').to_h[:description]).to eq('hello') }
      specify { expect(build(required: true).to_h[:required]).to be(true) }
      specify { expect(build(caseExact: true).to_h[:caseExact]).to be(true) }

      specify { expect(build(mutability: 'readOnly').to_h[:mutability]).to eql('readOnly') }
      specify { expect(build(mutability: 'readWrite').to_h[:mutability]).to eql('readWrite') }
      specify { expect(build(mutability: 'immutable').to_h[:mutability]).to eql('immutable') }
      specify { expect(build(mutability: 'writeOnly').to_h[:mutability]).to eql('writeOnly') }
      specify { expect { build(mutability: 'invalid') }.to raise_error(ArgumentError) }

      specify { expect(build(returned: 'always').to_h[:returned]).to eql('always') }
      specify { expect(build(returned: 'never').to_h[:returned]).to eql('never') }
      specify { expect(build(returned: 'default').to_h[:returned]).to eql('default') }
      specify { expect(build(returned: 'request').to_h[:returned]).to eql('request') }
      specify { expect { build(returned: 'invalid') }.to raise_error(ArgumentError) }

      specify { expect(build(uniqueness: 'none').to_h[:uniqueness]).to eql('none') }
      specify { expect(build(uniqueness: 'server').to_h[:uniqueness]).to eql('server') }
      specify { expect(build(uniqueness: 'global').to_h[:uniqueness]).to eql('global') }
      specify { expect { build(uniqueness: 'invalid') }.to raise_error(ArgumentError) }
    end
  end
end
