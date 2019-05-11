# frozen_string_literal: true

RSpec.describe Scim::Kit::V2::Parser do
  subject { described_class.new }

  [
    'userName',
    'name.familyName',
    'urn:ietf:params:scim:schemas:core:2.0:User:userName',
    'meta.lastModified',
    'schemas'
  ].each do |attribute|
    %w[
      eq
      ne
      co
      sw
      ew
      gt
      lt
      ge
      le
    ].each do |operator|
      [
        'bjensen',
        "O'Malley",
        'J',
        '2011-05-13T04:42:34Z',
        'urn:ietf:params:scim:schemas:extension:enterprise:2.0:User'
      ].each do |value|
        specify { expect(subject.parse_with_debug(%(#{attribute} #{operator} \"#{value}\"))).to be_truthy }
      end
    end
  end

  specify { expect(subject.parse_with_debug('userName eq "jeramy@ziemann.biz"')).to be_truthy }
  xspecify { expect(subject.parse_with_debug(%(title pr and userType eq "Employee"))).to be_truthy }
  specify { expect(subject.attribute_expression.parse_with_debug(%(title pr and userType eq "Employee"))).not_to be_truthy }
  specify { expect(subject.logical_expression.parse_with_debug(%(title pr and userType eq "Employee"))).to be_truthy }
  specify { expect(subject.value_path.parse_with_debug(%(title pr and userType eq "Employee"))).not_to be_truthy }

  [
    'emails[type eq "work" and value co "@example.com"]'
  ].each do |x|
    xspecify { expect(subject.value_path).to parse(x) }
  end

  [
    'firstName eq "Tsuyoshi"',
    'firstName pr'
    # 'firstName eq "Tsuyoshi" and lastName eq "Garret"'
  ].each do |x|
    specify { expect(subject.value_filter).to parse(x) }
  end

  [
    'firstName eq "Tsuyoshi"',
    'firstName pr'
  ].each do |x|
    specify { expect(subject.attribute_expression).to parse(x) }
  end

  [
    'firstName eq "Tsuyoshi" and lastName eq "Garret"',
    'firstName eq "Tsuyoshi" or lastName eq "Garret"',
    'title pr and userType eq "Employee"',
    'title pr or userType eq "Employee"'
  ].each do |x|
    specify { expect(subject.logical_expression).to parse(x) }
  end

  ['false', 'null', 'true', '1', 'hello', 'urn:ietf:params:scim:schemas:extension:enterprise:2.0:User', 'Garrett'].each do |x|
    specify { expect(subject.comparison_value).to parse(x) }
  end

  %w[eq ne co sw ew gt lt ge le].each do |x|
    specify { expect(subject.comparison_operator).to parse(x) }
  end

  [
    'userName',
    'user_name',
    'user-name',
    'username1',
    'meta.lastModified',
    'schemas',
    'name.familyName',
    'urn:ietf:params:scim:schemas:core:2.0:User:userName',
    'urn:ietf:params:scim:schemas:core:2.0:User:name.familyName',
  ].each do |x|
    specify { expect(subject.attribute_path.parse_with_debug(x)).to be_truthy }
  end

  [
    'userName',
    'user_name',
    'user-name',
    'username1',
    'schemas'
  ].each do |x|
    specify { expect(subject.attribute_name).to parse(x) }
  end

  ['-', '_', '0', 'a'].each { |x| specify { expect(subject.name_character).to parse(x) } }
  specify { expect(subject.sub_attribute).to parse('.name') }
  specify { expect(subject.presence).to parse('pr') }
  specify { expect(subject.and_op).to parse('and') }
  specify { expect(subject.or_op).to parse('or') }
  specify { expect(subject.not_op).to parse('not') }
  specify { expect(subject.not_op).to parse('') }
  specify { expect(subject.not_op).not_to parse('not not') }
  specify { expect(subject.falsey).to parse('false') }
  specify { expect(subject.truthy).to parse('true') }
  specify { expect(subject.null).to parse('null') }
  1.upto(100).each { |n| specify { expect(subject.number).to parse(n.to_s) } }

  [
    'urn:ietf:params:scim:schemas:core:2.0:User',
    'urn:ietf:params:scim:schemas:core:2.0:Group',
    'urn:ietf:params:scim:schemas:extension:altean:2.0:User',
  ].each do |x|
    specify { expect(subject.uri).to parse(x) }
  end

  [
    'title pr'
    # 'title pr and userType eq "Employee"',
    # 'title pr or userType eq "Intern"',
    # '',
    # 'userType eq "Employee" and (emails co "example.com" or emails.value co "example.org")',
    # 'userType ne "Employee" and not (emails co "example.com" or emails.value co "example.org")',
    # 'userType eq "Employee" and (emails.type eq "work") ',
    # 'userType eq "Employee" and emails[type eq "work" and value co "@example.com"]',
    # 'emails[type eq "work" and value co "@example.com"] or ims[type eq "xmpp" and value co "@foo.com"]'
  ].each do |x|
    specify { expect(subject).to parse(x) }
  end

  [
    'Tsuyoshi',
    'hello@example.org',
    '2011-05-13T04:42:34Z'
  ].each do |x|
    specify { expect(subject.string).to parse(x) }
  end

  specify { expect(subject.hyphen).to parse("-") }
  specify { expect(subject.underscore).to parse("_") }
  (0..9).each { |x| specify { expect(subject.digit).to parse(x.to_s) } }
  ('A'..'Z').each { |x| specify { expect(subject.alpha).to parse(x) } }
  ('a'..'z').each { |x| specify { expect(subject.alpha).to parse(x) } }
  specify { expect(subject.colon).to parse(":") }
  specify { expect(subject.version).to parse("2.0") }
  specify { expect(subject.version).to parse("1.0") }
end
