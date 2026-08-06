# frozen_string_literal: true

RSpec.describe Scim::Kit::Validatable do
  subject { model.new }

  let(:model) do
    Class.new do
      include Scim::Kit::Validatable

      def self.name
        'Example'
      end

      validate { |x| x.errors.add(:name, 'is missing') }
    end
  end

  specify { expect(subject).to be_invalid }
  specify { expect(subject.tap(&:valid?).errors[:name]).to eql(['is missing']) }

  describe '#each_error' do
    it 'yields the attribute and the message' do
      subject.valid?

      expect { |b| subject.each_error(&b) }.to yield_with_args(:name, 'is missing')
    end
  end

  # The protocol a parent uses to re-attribute a child's errors onto itself.
  describe 'bubbling a child up to a parent' do
    let(:parent) do
      Class.new do
        include Scim::Kit::Validatable

        attr_accessor :child

        def self.name
          'Parent'
        end

        validate :must_have_a_valid_child

        def must_have_a_valid_child
          return if child.valid?

          child.each_error { |attribute, message| errors.add(attribute, message) }
        end
      end
    end

    specify { expect(parent.new.tap { |x| x.child = subject }).to be_invalid }

    it 'carries the child message onto the parent' do
      instance = parent.new
      instance.child = subject

      instance.valid?

      expect(instance.errors[:name]).to eql(['is missing'])
    end
  end
end
