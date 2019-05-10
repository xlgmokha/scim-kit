# frozen_string_literal: true

RSpec.describe Scim::Kit::V2::Parser do
  subject { described_class.new }

  [ "eq", "ne", "co", "sw", "ew", "gt", "lt", "ge", "le" ].each do |operator|
    context "simple expression #{operator}" do
      let(:result) { subject.pretty_parse(%Q(userName #{operator} "bjensen")) }

      specify { expect(result).to be_present }
      specify { expect(result[:left].to_s).to eql('userName') }
      specify { expect(result[:operator].to_s).to eql(operator) }
      specify { expect(result[:right].to_s).to eql('bjensen') }
    end

    context "nested attribute #{operator}" do
      let(:result) { subject.pretty_parse(%Q(name.familyName #{operator} "O'Malley")) }

      specify { expect(result).to be_present }
      specify { expect(result[:left].to_s).to eql('name.familyName') }
      specify { expect(result[:operator].to_s).to eql(operator) }
      specify { expect(result[:right].to_s).to eql("O'Malley") }
    end
  end
end


=begin
filter=userName eq "bjensen"

filter=name.familyName co "O'Malley"

filter=userName sw "J"

filter=urn:ietf:params:scim:schemas:core:2.0:User:userName sw "J"

filter=title pr

filter=meta.lastModified gt "2011-05-13T04:42:34Z"

filter=meta.lastModified ge "2011-05-13T04:42:34Z"

filter=meta.lastModified lt "2011-05-13T04:42:34Z"

filter=meta.lastModified le "2011-05-13T04:42:34Z"

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
