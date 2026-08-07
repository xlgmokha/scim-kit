# frozen_string_literal: true

RSpec.describe Scim::Kit::Cli::Settings do
  def settings(options, env: {})
    described_class.new(options, env: env)
  end

  describe '#url' do
    it 'prefers the --url option' do
      expect(settings({ url: 'https://a' }).url).to eql('https://a')
    end

    it 'falls back to SCIM_KIT_URL' do
      result = settings({}, env: { 'SCIM_KIT_URL' => 'https://b' })

      expect(result.url).to eql('https://b')
    end

    it 'raises when neither is given' do
      expect { settings({}).url }
        .to raise_error(Scim::Kit::Cli::InvalidOption, /--url is required/)
    end

    it 'raises when the url is blank' do
      expect { settings({ url: '' }).url }
        .to raise_error(Scim::Kit::Cli::InvalidOption, /--url is required/)
    end

    it 'raises when the url has no scheme' do
      expect { settings({ url: 'example.com/scim/v2' }).url }
        .to raise_error(Scim::Kit::Cli::InvalidOption, /--url must be an absolute http/)
    end

    it 'raises when the url scheme is not http(s)' do
      expect { settings({ url: 'ftp://example.com' }).url }
        .to raise_error(Scim::Kit::Cli::InvalidOption, /--url must be an absolute http/)
    end

    it 'raises when the url is unparseable' do
      expect { settings({ url: 'http://exa mple.com' }).url }
        .to raise_error(Scim::Kit::Cli::InvalidOption, /--url must be an absolute http/)
    end

    it 'accepts an http url' do
      expect(settings({ url: 'http://a' }).url).to eql('http://a')
    end
  end

  describe '#headers' do
    it 'parses a Name: Value pair' do
      result = settings({ header: ['Authorization: Bearer xyz'] })

      expect(result.headers).to eql('Authorization' => 'Bearer xyz')
    end

    it 'keeps colons in the value' do
      result = settings({ header: ['X-A: a:b'] })

      expect(result.headers).to eql('X-A' => 'a:b')
    end

    it 'parses repeated headers' do
      result = settings({ header: ['A: 1', 'B: 2'] })

      expect(result.headers).to eql('A' => '1', 'B' => '2')
    end

    it 'defaults to no headers' do
      expect(settings({}).headers).to eql({})
    end

    it 'raises on a header without a colon' do
      expect { settings({ header: ['nope'] }).headers }
        .to raise_error(Scim::Kit::Cli::InvalidOption, /malformed --header/)
    end
  end

  describe '#list_query' do
    let(:options) do
      { filter: 'a eq 1', start_index: 2, count: 3,
        sort_by: 'userName', sort_order: 'ascending', attributes: 'id' }
    end

    it 'maps options onto their SCIM parameter names' do
      expect(settings(options).list_query).to eql(
        'filter' => 'a eq 1', 'startIndex' => 2, 'count' => 3,
        'sortBy' => 'userName', 'sortOrder' => 'ascending', 'attributes' => 'id'
      )
    end

    it 'leaves absent options nil for the client to drop' do
      expect(settings({}).list_query.values).to all(be_nil)
    end
  end
end
