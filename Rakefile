# frozen_string_literal: true

require 'bundler/audit/task'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new(:rubocop)
Bundler::Audit::Task.new

task default: :spec
