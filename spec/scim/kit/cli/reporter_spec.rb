# frozen_string_literal: true

RSpec.describe Scim::Kit::Cli::Reporter do
  subject { described_class.new }

  let(:body) { { id: '123' } }
  let(:pretty) { JSON.pretty_generate(body) }

  describe '#report' do
    context 'when the result is ok' do
      let(:result) { Scim::Kit::Http::Result.new(200, body) }

      it 'prints the body as pretty json to stdout' do
        expect { subject.report(result) }.to output("#{pretty}\n").to_stdout
      end

      it 'returns a success status' do
        allow($stdout).to receive(:puts)

        expect(subject.report(result)).to eq(0)
      end
    end

    context 'when the result is not ok' do
      let(:result) { Scim::Kit::Http::Result.new(404, body) }

      it 'prints the body as pretty json to stderr' do
        expect { subject.report(result) }.to output("#{pretty}\n").to_stderr
      end

      it 'returns a failure status' do
        allow($stderr).to receive(:puts)

        expect(subject.report(result)).to eq(1)
      end
    end
  end

  describe '#report_validation' do
    let(:result) { Scim::Kit::Http::Result.new(200, body) }

    context 'without errors' do
      it 'prints the body to stdout' do
        expect { subject.report_validation(result, []) }
          .to output("#{pretty}\n").to_stdout
      end

      it 'returns a success status' do
        allow($stdout).to receive(:puts)

        expect(subject.report_validation(result, [])).to eq(0)
      end
    end

    context 'with errors' do
      let(:errors) { ['root is missing required keys: id'] }

      it 'prints the errors to stderr' do
        allow($stdout).to receive(:puts)

        expect { subject.report_validation(result, errors) }
          .to output(/validation_errors/).to_stderr
      end

      it 'still prints the body to stdout' do
        allow($stderr).to receive(:puts)

        expect { subject.report_validation(result, errors) }
          .to output(/#{pretty}/).to_stdout
      end

      it 'returns a failure status' do
        allow($stdout).to receive(:puts)
        allow($stderr).to receive(:puts)

        expect(subject.report_validation(result, errors)).to eq(1)
      end
    end
  end

  describe '#failure' do
    it 'prints the body as pretty json to stderr' do
      expect { subject.failure(detail: 'boom') }
        .to output("#{JSON.pretty_generate(detail: 'boom')}\n").to_stderr
    end

    it 'returns a failure status' do
      allow($stderr).to receive(:puts)

      expect(subject.failure(detail: 'boom')).to eq(1)
    end
  end

  describe '#success' do
    it 'prints the body as pretty json to stdout' do
      expect { subject.success(body) }.to output("#{pretty}\n").to_stdout
    end

    it 'returns a success status' do
      allow($stdout).to receive(:puts)

      expect(subject.success(body)).to eq(0)
    end
  end

  describe '#report_unvalidated' do
    let(:result) { Scim::Kit::Http::Result.new(200, body) }

    it 'prints the body to stdout' do
      expect { subject.report_unvalidated(result) }
        .to output("#{pretty}\n").to_stdout
    end

    it 'returns a failure status' do
      allow($stdout).to receive(:puts)

      expect(subject.report_unvalidated(result)).to eq(1)
    end
  end

  describe '#warn' do
    it 'prefixes the message and writes it to stderr' do
      expect { subject.warn('watch out') }
        .to output("warning: watch out\n").to_stderr
    end
  end
end
