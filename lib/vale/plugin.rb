# frozen_string_literal: true

require "open3"
require "json"

module Danger
  # A plugin for danger which checks prose commited to git repositories.
  #
  # You need to install the vale command to use this plugin.
  # https://github.com/errata-ai/vale
  #
  # @example Lint all added and modified files
  #
  #          vale.lint_files
  #
  # @example Lint specific files
  #
  #          vale.lint_files ["README.md"]
  #
  # @see https://github.com/MatMoore/danger-vale Github repository for this plugin
  # @see https://github.com/dbgrandi/danger-prose A similar plugin which use proselint instead of vale
  # @tags prose, copy, text, blogging, blog, writing, jekyll, middleman, hugo, metalsmith, gatsby, express
  #
  class DangerVale < Plugin
    # Lints a list of files
    # @param   [String] files
    #          An array of filenames to lint (optional).
    #          If not specified, the plugin will use all modified and added files.
    # @return   [void]
    def lint_files(files = nil)
      files ||= (git.modified_files + git.added_files)
      files.select! { |line| line.end_with? ".markdown", ".md", ".erb.md" }

      results = run_valelint(files)

      results.each do |filename, checks|
        by_line = checks.group_by { |check| check["Line"] }

        by_line.each do |line, line_checks|
          line_checks.each do |line_check|
            message = line_check["Message"]
            severity = line_check["Severity"]
            if severity == "error"
              fail(message, file: filename, line: line)
            else
              warn(message, file: filename, line: line)
            end
          end
        end
      end
    end

    private

    def run_valelint(files)
      out, _err, status = Open3.capture3(
        "vale",
        "--output", "JSON",
        "--no-exit",
        *files
      )

      if status.success?
        return JSON.parse(out)
      else
        raise "Unable to parse vale output"
      end
    end
  end
end
