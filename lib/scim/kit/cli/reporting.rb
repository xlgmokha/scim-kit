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
