# frozen_string_literal: true

module Scim
  module Kit
    module Cli
      class Reporter
        SUCCESS = 0
        FAILURE = 1

        def initialize(shell)
          @shell = shell
        end

        def report(result)
          result.ok? ? success(result.body) : failure(result.body)
        end

        def report_validation(result, errors)
          shell.say(pretty(result.body))
          return SUCCESS if errors.empty?

          failure(validation_errors: errors)
        end

        def success(body)
          shell.say(pretty(body))
          SUCCESS
        end

        def failure(body)
          shell.say_error(pretty(body))
          FAILURE
        end

        def warn(message)
          shell.say_error("warning: #{message}")
        end

        private

        attr_reader :shell

        def pretty(body)
          JSON.pretty_generate(body)
        end
      end
    end
  end
end
