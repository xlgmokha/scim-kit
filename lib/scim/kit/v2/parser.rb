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
        root :filter
        rule(:filter) { (attrExp | logExp | valuePath) | (not_op? >> lparen >> filter >> rparen) }
        rule(:valuePath) { attrPath >> lsquare_bracket >> valFilter >> rsquare_bracket }
        rule(:valFilter) { attrExp | logExp | (not_op? >> lparen >> valFilter >> rparen) }
        rule(:attrExp) { (attrPath >> space >> presence) | (attrPath >> space >> compareOp >> space >> quote >> compValue >> quote) }
        rule(:logExp) { filter >> space >> (and_op | or_op) >> space >> filter }
        rule(:compValue) { (falsey | null | truthy | number | string | scim_schema_uri).repeat(1) }
        rule(:compareOp) { equal | not_equal | contains | starts_with | ends_with | greater_than | less_than | less_than_equals | greater_than_equals }
        rule(:attrPath) { scim_schema_uri | attrname >> subAttr.maybe }
        rule(:attrname) { alpha >> nameChar.repeat(1) }
        rule(:nameChar) { hyphen | underscore | digit | alpha }
        rule(:subAttr) { dot >> attrname }
        rule(:presence) { str('pr') }
        rule(:and_op) { str('and') }
        rule(:or_op) { str('or') }
        rule(:not_op) { str('not') }
        rule(:not_op?) { not_op.maybe }
        rule(:falsey) { str('false') }
        rule(:truthy) { str('true') }
        rule(:null) { str('null') }
        rule(:number) { digit.repeat(1) }
        rule(:scim_schema_uri) { (alpha | digit | dot | colon).repeat(1) }
        rule(:equal) { str("eq") }
        rule(:not_equal) { str("ne") }
        rule(:contains) { str("co") }
        rule(:starts_with) { str("sw") }
        rule(:ends_with) { str("ew") }
        rule(:greater_than) { str("gt") }
        rule(:less_than) { str("lt") }
        rule(:greater_than_equals) { str("ge") }
        rule(:less_than_equals) { str("le") }
        rule(:string) { (alpha | single_quote).repeat(1) }
        rule(:lparen) { str('(') >> space? }
        rule(:rparen) { str(')') >> space? }
        rule(:lsquare_bracket) { str('[') >> space? }
        rule(:rsquare_bracket) { str(']') >> space? }
        rule(:digit) { match(/\d/) }
        rule(:quote) { str('"') }
        rule(:single_quote) { str("'") }
        rule(:space) { match('\s') }
        rule(:space?) { space.maybe }
        rule(:alpha) { match('[a-zA-Z]') }
        rule(:dot) { str('.') }
        rule(:colon) { str(':') }
        rule(:hyphen) { str('-') }
        rule(:underscore) { str('_') }
      end
    end
  end
end
