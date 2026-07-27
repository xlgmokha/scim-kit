# frozen_string_literal: true

module Scim
  module Kit
    module Cli
      module Reporting
        def self.report(result, shell)
          if result.ok?
            shell.say(JSON.pretty_generate(result.body))
            exit(0)
          else
            shell.say_error(JSON.pretty_generate(result.body))
            exit(1)
          end
        end

        def self.report_error(message, shell)
          shell.say_error(JSON.pretty_generate(detail: message))
          exit(1)
        end

        def self.report_with_validation(result, shell, errors)
          shell.say(JSON.pretty_generate(result.body))
          if errors.empty?
            exit(0)
          else
            shell.say_error(
              JSON.pretty_generate(validation_errors: errors)
            )
            exit(1)
          end
        end

        def self.warn_unresolvable_schema(resource_type, shell)
          shell.say_error(
            'warning: no schema found for resource type ' \
            "#{resource_type.inspect}; skipping validation"
          )
        end

        def self.rescue_errors(shell)
          yield
        rescue RequestFailed => error
          report(error.result, shell)
        rescue UnknownResourceType, MissingEndpoint, InvalidResponse => error
          report_error(error.message, shell)
        end
      end
    end
  end
end
