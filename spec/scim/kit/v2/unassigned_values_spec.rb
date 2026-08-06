# frozen_string_literal: true

RSpec.describe Scim::Kit::V2::UnassignedValues do
  describe '.strip' do
    it { expect(described_class.strip('userName' => 'mo', 'externalId' => nil)).to eql('userName' => 'mo') }
    it { expect(described_class.strip('Resources' => [])).to eql('Resources' => []) }
    it { expect(described_class.strip('name' => { 'givenName' => nil })).to eql('name' => {}) }
    it { expect(described_class.strip('emails' => [{ 'type' => nil }])).to eql('emails' => [{}]) }
    it { expect(described_class.strip('emails' => [nil])).to eql('emails' => [nil]) }
    it { expect(described_class.strip('active' => false)).to eql('active' => false) }
    it { expect(described_class.strip('userName' => '')).to eql('userName' => '') }

    it 'leaves the original document untouched' do
      document = { 'externalId' => nil }

      described_class.strip(document)

      expect(document).to eql('externalId' => nil)
    end
  end
end
