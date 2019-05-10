# frozen_string_literal: true
require 'parslet'

module Scim
  module Kit
    module V2
=begin
FILTER    = attrExp / logExp / valuePath / *1"not" "(" FILTER ")"

valuePath = attrPath "[" valFilter "]"
           ; FILTER uses sub-attributes of a parent attrPath

valFilter = attrExp / logExp / *1"not" "(" valFilter ")"

attrExp   = (attrPath SP "pr") /
           (attrPath SP compareOp SP compValue)

logExp    = FILTER SP ("and" / "or") SP FILTER

compValue = false / null / true / number / string
           ; rules from JSON (RFC 7159)

compareOp = "eq" / "ne" / "co" /
                  "sw" / "ew" /
                  "gt" / "lt" /
                  "ge" / "le"

attrPath  = [URI ":"] ATTRNAME *1subAttr
           ; SCIM attribute name
           ; URI is SCIM "schema" URI

ATTRNAME  = ALPHA *(nameChar)

nameChar  = "-" / "_" / DIGIT / ALPHA

subAttr   = "." ATTRNAME
           ; a sub-attribute of a complex attribute
=end
      class Parser < Parslet::Parser
        rule(:lparen) { str('(') >> space? }
        rule(:rparen) { str(')') >> space? }
        rule(:digit) { match(/\d/) }
        rule(:quote) { str('"') }
        rule(:single_quote) { str("'") }
        rule(:space) { match('\s') }
        rule(:space?) { space.maybe }
        rule(:alpha) { match('[a-zA-Z]') }
        rule(:dot) { str('.') }
        rule(:colon) { str(':') }
        rule(:hyphen) { str('-') }

        rule(:attribute) { uri | attribute_name }
        rule(:attribute_name) { alpha.repeat(1) | dot }
        rule(:uri) { (alpha | digit | dot | colon).repeat(1) }
        rule(:date) { (alpha | digit | dot | colon | hyphen).repeat(1) }
        rule(:string) { (alpha | single_quote).repeat(1) }

        rule(:operator) { equal | not_equal | contains | starts_with | ends_with | greater_than | less_than | less_than_equals | greater_than_equals }
        rule(:equal) { str("eq") }
        rule(:not_equal) { str("ne") }
        rule(:contains) { str("co") }
        rule(:starts_with) { str("sw") }
        rule(:ends_with) { str("ew") }
        rule(:greater_than) { str("gt") }
        rule(:less_than) { str("lt") }
        rule(:greater_than_equals) { str("ge") }
        rule(:less_than_equals) { str("le") }

        rule(:quoted_value) { quote >> value.as(:right) >> quote }
        rule(:value) { (string | date | uri).repeat(1) }

        rule(:filter) { attribute.as(:left) >> space >> operator.as(:operator) >> space >> quoted_value }
        root :filter

        def pretty_parse(*args)
          puts *args.inspect
          parse(*args)
        rescue Parslet::ParseFailed => error
          puts error.parse_failure_cause.ascii_tree
        end
      end
    end
  end
end
