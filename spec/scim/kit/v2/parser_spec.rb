# frozen_string_literal: true

RSpec.describe Scim::Kit::V2::Parser do
  subject { described_class.new }

  [
    'userName',
    #'name.familyName',
    #'urn:ietf:params:scim:schemas:core:2.0:User:userName',
    #'meta.lastModified',
    #'schemas',
  ].each do |attribute|
    [
      "eq",
      #"ne",
      #"co",
      #"sw",
      #"ew",
      #"gt",
      #"lt",
      #"ge",
      #"le"
    ].each do |operator|
      [
        #"bjensen",
        #"O'Malley",
        #"J",
        #"2011-05-13T04:42:34Z",
        "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User",
      ].each do |value|
        specify { expect(subject).to parse(%Q(#{attribute} #{operator} \"#{value}\")) }
      end
    end
  end

  specify { expect(subject).to parse(%Q(title pr and userType eq "Employee")) }

  [
    'emails[type eq "work" and value co "@example.com"]',
  ].each do |x|
    specify { expect(subject.valuePath).to parse(x) }
  end

  [
    'firstName eq "Tsuyoshi"',
    'firstName pr',
    'firstName eq "Tsuyoshi" and lastName eq "Garret"'
  ].each do |x|
    specify { expect(subject.valFilter).to parse(x) }
  end

  [
    'firstName eq "Tsuyoshi"',
    'firstName pr',
  ].each do |x|
    specify { expect(subject.attrExp).to parse(x) }
  end

  specify { expect(subject.attrExp).not_to parse('firstName eq "Tsuyoshi" and lastName eq "Garret"') }

  [
    'firstName eq "Tsuyoshi" and lastName eq "Garret"'
  ].each do |x|
    specify { expect(subject.logExp).to parse(x) }
  end

  ['false', 'null', 'true', '1', 'hello', "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User"].each do |x|
    specify { expect(subject.compValue).to parse(x) }
  end

  ['eq', 'ne', 'co', 'sw', 'ew', 'gt', 'lt', 'ge', 'le'].each do |x|
    specify { expect(subject.compareOp).to parse(x) }
  end

  [
    'userName',
    'user_name',
    'user-name',
    'username1',
    'name.familyName',
    'urn:ietf:params:scim:schemas:core:2.0:User:userName',
    'urn:ietf:params:scim:schemas:core:2.0:User:name.familyName',
    'meta.lastModified',
    'schemas',
  ].each do |x|
    specify { expect(subject.attrPath).to parse(x) }
  end

  [
    'userName',
    'user_name',
    'user-name',
    'username1',
    'schemas',
  ].each do |x|
    specify { expect(subject.attrname).to parse(x) }
  end
  ['-', '_', '0', 'a'].each { |x| specify { expect(subject.nameChar).to parse(x) } }
  specify { expect(subject.subAttr).to parse('.name') }
  specify { expect(subject.presence).to parse('pr') }
  specify { expect(subject.and_op).to parse('and') }
  specify { expect(subject.or_op).to parse('or') }
  specify { expect(subject.not_op).to parse('not') }
  specify { expect(subject.falsey).to parse('false') }
  specify { expect(subject.truthy).to parse('true') }
  specify { expect(subject.null).to parse('null') }
  1.upto(100).each { |n| specify { expect(subject.number).to parse(n.to_s) } }

  [
    'urn:ietf:params:scim:schemas:core:2.0:User:userName',
    'urn:ietf:params:scim:schemas:core:2.0:User:name.familyName',
  ].each do |x|
    specify { expect(subject.scim_schema_uri).to parse(x) }
  end

  [
    'title pr',
    'title pr and userType eq "Employee"',
    'title pr or userType eq "Intern"',
    '',
    'userType eq "Employee" and (emails co "example.com" or emails.value co "example.org")',
    'userType ne "Employee" and not (emails co "example.com" or emails.value co "example.org")',
    'userType eq "Employee" and (emails.type eq "work") ',
    'userType eq "Employee" and emails[type eq "work" and value co "@example.com"]',
    'emails[type eq "work" and value co "@example.com"] or ims[type eq "xmpp" and value co "@foo.com"]',
  ].each do |x|
    specify { expect(subject).to parse(x) }
  end
end
