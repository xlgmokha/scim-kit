# frozen_string_literal: true

RSpec.describe Scim::Kit::Cli::Reporting do
  let(:shell) { Thor::Shell::Basic.new }

  describe '.report' do
    context 'when the result is ok' do
      let(:result) { Scim::Kit::Http::Result.new(200, { id: '123' }) }

      it 'prints the body as pretty json to stdout' do
        expect { exit_status { described_class.report(result, shell) } }
          .to output("#{JSON.pretty_generate(id: '123')}\n").to_stdout
      end

      it 'exits 0' do
        allow($stdout).to receive(:print)

        expect(exit_status { described_class.report(result, shell) }).to eq(0)
      end
    end

    context 'when the result is not ok' do
      let(:result) { Scim::Kit::Http::Result.new(404, { detail: 'not found' }) }

      it 'prints the body as pretty json to stderr' do
        expect { exit_status { described_class.report(result, shell) } }
          .to output("#{JSON.pretty_generate(detail: 'not found')}\n").to_stderr
      end

      it 'exits 1' do
        allow($stderr).to receive(:print)

        expect(exit_status { described_class.report(result, shell) }).to eq(1)
      end
    end
  end

  describe '.report_error' do
    it 'prints a synthesized detail message as pretty json to stderr' do
      expect { exit_status { described_class.report_error('boom', shell) } }
        .to output("#{JSON.pretty_generate(detail: 'boom')}\n").to_stderr
    end

    it 'exits 1' do
      allow($stderr).to receive(:print)

      expect(exit_status { described_class.report_error('boom', shell) }).to eq(1)
    end
  end

  describe '.report_with_validation' do
    let(:result) { Scim::Kit::Http::Result.new(200, { id: '123' }) }

    context 'when there are no errors' do
      it 'prints the body as pretty json to stdout' do
        expect do
          exit_status do
            described_class.report_with_validation(result, shell, [])
          end
        end.to output("#{JSON.pretty_generate(id: '123')}\n").to_stdout
      end

      it 'exits 0' do
        allow($stdout).to receive(:print)

        status = exit_status do
          described_class.report_with_validation(result, shell, [])
        end

        expect(status).to eq(0)
      end
    end

    context 'when there are errors' do
      let(:errors) { ['root is missing required keys: userName'] }

      it 'prints the body to stdout and the errors to stderr' do
        allow($stdout).to receive(:print)

        expect { exit_status { described_class.report_with_validation(result, shell, errors) } }
          .to output("#{JSON.pretty_generate(validation_errors: errors)}\n").to_stderr
      end

      it 'exits 1' do
        allow($stdout).to receive(:print)
        allow($stderr).to receive(:print)

        status = exit_status { described_class.report_with_validation(result, shell, errors) }

        expect(status).to eq(1)
      end
    end
  end

  describe '.warn_unresolvable_schema' do
    it 'prints a warning mentioning the resource type to stderr' do
      expect { described_class.warn_unresolvable_schema('Foo', shell) }
        .to output(/no schema found for resource type "Foo"/).to_stderr
    end
  end

  describe '.rescue_errors' do
    it 'returns the value of the block when nothing is raised' do
      expect(described_class.rescue_errors(shell) { 'ok' }).to eq('ok')
    end

    context 'when the block raises Cli::RequestFailed' do
      let(:result) { Scim::Kit::Http::Result.new(500, { detail: 'boom' }) }
      let(:block) do
        -> { described_class.rescue_errors(shell) { raise Scim::Kit::Cli::RequestFailed, result } }
      end

      it 'reports the failed result' do
        expect { exit_status(&block) }
          .to output("#{JSON.pretty_generate(detail: 'boom')}\n").to_stderr
      end
    end

    context 'when the block raises Cli::UnknownResourceType' do
      let(:block) do
        lambda do
          described_class.rescue_errors(shell) do
            raise Scim::Kit::Cli::UnknownResourceType.new('Nope', ['User'])
          end
        end
      end

      it 'reports the error message' do
        expect { exit_status(&block) }.to output(/Nope/).to_stderr
      end
    end

    context 'when the block raises Cli::MissingEndpoint' do
      let(:block) do
        lambda do
          described_class.rescue_errors(shell) { raise Scim::Kit::Cli::MissingEndpoint, 'User' }
        end
      end

      it 'reports the error message' do
        expect { exit_status(&block) }.to output(/User/).to_stderr
      end
    end

    context 'when the block raises Cli::InvalidResponse' do
      let(:block) do
        lambda do
          described_class.rescue_errors(shell) { raise Scim::Kit::Cli::InvalidResponse, 'bad shape' }
        end
      end

      it 'reports the error message' do
        expect { exit_status(&block) }.to output(/bad shape/).to_stderr
      end
    end
  end
end
