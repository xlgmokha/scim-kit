# frozen_string_literal: true

RSpec.describe Scim::Kit do
  specify { expect(Scim::Kit::VERSION).not_to be_nil }
end
