# frozen_string_literal: true

RSpec.describe Scim::Kit::V2 do
  subject { described_class }

  describe ".configure" do
    specify do
      called = false
      subject.configure do |config|
        called = true
        expect(config).to be_instance_of(Scim::Kit::V2::Configuration::Builder)
      end

      expect(called).to be(true)
    end
  end
end
