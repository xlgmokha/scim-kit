# frozen_string_literal: true

require 'bundler/setup'
require 'scim/kit'
require 'scim/kit/cli'
require 'ffaker'
require 'json'
require 'parslet/convenience'
require 'parslet/rig/rspec'
require 'webmock/rspec'

Scim::Kit.logger = Logger.new('/dev/null')

module ExitStatusHelper
  def exit_status
    yield
    nil
  rescue SystemExit => error
    error.status
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include ExitStatusHelper
end
