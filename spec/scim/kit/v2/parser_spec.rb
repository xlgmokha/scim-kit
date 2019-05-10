# frozen_string_literal: true

RSpec.describe Scim::Kit::V2::Parser do
  subject { described_class.new }

  [
    'userName',
    'name.familyName',
    'urn:ietf:params:scim:schemas:core:2.0:User:userName',
    'meta.lastModified',
  ].each do |attribute|
    [
      "eq",
      "ne",
      "co",
      "sw",
      "ew",
      "gt",
      "lt",
      "ge",
      "le"
    ].each do |operator|
      [
        "bjensen",
        "O'Malley",
        "J",
        "2011-05-13T04:42:34Z",
      ].each do |value|
        context "#{attribute} #{operator} #{value}" do
          let(:result) { subject.pretty_parse(%Q(#{attribute} #{operator} \"#{value}\")) }

          specify { expect(result).to be_present }
          specify { expect(result[:left].to_s).to eql(attribute) }
          specify { expect(result[:operator].to_s).to eql(operator) }
          specify { expect(result[:right].to_s).to eql(value) }
        end
      end
    end
  end

  context "match uri" do
    specify { expect(subject.uri.parse("urn:ietf:params:scim:schemas:core:2.0:User:userName")).to be_present }
  end
end


=begin
filter=title pr

filter=title pr and userType eq "Employee"

filter=title pr or userType eq "Intern"

filter=
 schemas eq "urn:ietf:params:scim:schemas:extension:enterprise:2.0:User"

filter=userType eq "Employee" and (emails co "example.com" or
  emails.value co "example.org")

filter=userType ne "Employee" and not (emails co "example.com" or
  emails.value co "example.org")

filter=userType eq "Employee" and (emails.type eq "work")

filter=userType eq "Employee" and emails[type eq "work" and
  value co "@example.com"]

filter=emails[type eq "work" and value co "@example.com"] or
  ims[type eq "xmpp" and value co "@foo.com"]
=end
