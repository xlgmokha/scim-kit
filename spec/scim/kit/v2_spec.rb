# frozen_string_literal: true

RSpec.describe Scim::Kit::V2 do
  subject { described_class }

  describe '.configure' do
    specify do
      subject.configure do |config|
        expect(config).to be_instance_of(Scim::Kit::V2::Configuration::Builder)
      end
    end

    specify do
      called = false
      subject.configure { |_config| called = true }
      expect(called).to be(true)
    end
  end
end
