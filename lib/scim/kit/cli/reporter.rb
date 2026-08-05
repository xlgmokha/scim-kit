# frozen_string_literal: true

module Scim
  module Kit
    module Cli
      class Reporter
        SUCCESS = 0
        FAILURE = 1

        def initialize(out = $stdout, err = $stderr)
          @out = out
          @err = err
        end

        def report(result, errors = [])
          return success(result.body) if result.ok?

          say_error(result.body)
          say_error(validation_errors: errors) unless errors.empty?
          FAILURE
        end

        def report_validation(result, errors)
          out.puts(pretty(result.body))
          return SUCCESS if errors.empty?

          failure(validation_errors: errors)
        end

        # --validate was asked for and could not be carried out, so the
        # response is reported but the command still fails.
        def report_unvalidated(result)
          out.puts(pretty(result.body))
          FAILURE
        end

        def success(body)
          out.puts(pretty(body))
          SUCCESS
        end

        def failure(body)
          say_error(body)
          FAILURE
        end

        def warn(message)
          err.puts("warning: #{message}")
        end

        private

        attr_reader :out, :err

        def say_error(body)
          err.puts(pretty(body))
        end

        def pretty(body)
          JSON.pretty_generate(body)
        end
      end
    end
  end
end
