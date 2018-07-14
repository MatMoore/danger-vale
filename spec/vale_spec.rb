require File.expand_path("../spec_helper", __FILE__)

module Danger
  describe Danger::DangerVale do
    it "should be a plugin" do
      expect(Danger::DangerVale.new(nil)).to be_a Danger::Plugin
    end

    describe "with Dangerfile" do
      before do
        @dangerfile = testing_dangerfile
        @vale = @dangerfile.vale

        allow(@dangerfile.git).to receive(:modified_files).and_return(["foo.md", "bar.md"])
        allow(@dangerfile.git).to receive(:added_files).and_return(["baz.md"])
      end

      it "runs vale with JSON output and supresses nonzero exit codes" do
        open3 = class_double("Open3").as_stubbed_const

        expect(open3).to receive(:capture3).with(
          "vale",
          "--output", "JSON",
          "--no-exit",
          "foo.md"
        ).and_return([
          "{}",
          "",
          instance_double("Process::Status", :success? => true)
        ])

        @vale.lint_files ["foo.md"]
      end

      it "defaults to linting added and modified files" do
        open3 = class_double("Open3").as_stubbed_const

        expect(open3).to receive(:capture3).with(
          "vale",
          "--output", "JSON",
          "--no-exit",
          "foo.md",
          "bar.md",
          "baz.md"
        ).and_return([
          "{}",
          "",
          instance_double("Process::Status", :success? => true)
        ])

        @vale.lint_files
      end

      it "throws an exception if the vale command doesn't exist" do
        open3 = class_double("Open3").as_stubbed_const

        allow(open3).to receive(:capture3).with(
          "vale",
          "--output", "JSON",
          "--no-exit",
          "foo.md"
        ).and_raise(Errno::ENOENT.new("vale"))

        expect { @vale.lint_files ["foo.md"] }.to raise_error(Errno::ENOENT)
      end

      context "given a line with a single warning and a single error" do
        let(:result) do
          {
            "foo.md" => [
              {
                "Check" => "vale.Editorializing",
                "Description" => "",
                "Line" => 1,
                "Link" => "",
                "Message" => "Consider removing 'very'",
                "Severity" => "warning",
                "Span" => [
                  11,
                  14
                ],
                "Hide" => false,
                "Match" => ""
              },
              {
                "Check": "vale.Repetition",
                "Description" => "",
                "Line" => 1,
                "Link" => "",
                "Message" => "'very' is repeated!",
                "Severity" => "error",
                "Span" => [
                  11,
                  19
                ],
                "Hide" => false,
                "Match" => ""
              }
            ]
          }
        end

        it "comments on the warning and the error" do
          allow(@vale).to receive(:run_valelint).and_return result

          @vale.lint_files ["foo.md"]

          expect(@dangerfile.status_report[:warnings]).to eq(["Consider removing 'very'"])
          expect(@dangerfile.status_report[:errors]).to eq(["'very' is repeated!"])
        end
      end

      context "given a line with two warnings" do
        let(:result) do
          {
            "foo.md" => [
              {
                "Check" => "vale.Editorializing",
                "Description" => "",
                "Line" => 5,
                "Link" => "",
                "Message" => "Consider removing 'very'",
                "Severity" => "warning",
                "Span" => [
                  11,
                  14
                ],
                "Hide" => false,
                "Match" => ""
              },
              {
                "Check": "vale.Repetition",
                "Description" => "",
                "Line" => 5,
                "Link" => "",
                "Message" => "'very' is repeated!",
                "Severity" => "warning",
                "Span" => [
                  11,
                  19
                ],
                "Hide" => false,
                "Match" => ""
              }
            ]
          }
        end

        it "comments with a list of the two warnings" do
          allow(@vale).to receive(:run_valelint).and_return result

          @vale.lint_files ["foo.md"]

          expect(@dangerfile.status_report[:warnings]).to eq(["- Consider removing 'very'\n- 'very' is repeated!"])
        end
      end

      context "given a warning that occurs on two lines" do
        let(:result) do
          {
            "foo.md" => [
              {
                "Check" => "vale.Editorializing",
                "Description" => "",
                "Line" => 5,
                "Link" => "",
                "Message" => "Consider removing 'very'",
                "Severity" => "warning",
                "Span" => [
                  11,
                  14
                ],
                "Hide" => false,
                "Match" => ""
              },
              {
                "Check" => "vale.Editorializing",
                "Description" => "",
                "Line" => 6,
                "Link" => "",
                "Message" => "Consider removing 'very'",
                "Severity" => "warning",
                "Span" => [
                  11,
                  14
                ],
                "Hide" => false,
                "Match" => ""
              },

            ]
          }
        end

        it "comments on both of them" do
          allow(@vale).to receive(:run_valelint).and_return result

          @vale.lint_files ["foo.md"]

          expect(@dangerfile.status_report[:warnings]).to eq(["Consider removing 'very'", "Consider removing 'very'"])
        end
      end

    end
  end
end
