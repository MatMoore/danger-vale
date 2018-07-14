require 'open3'
require 'json'

module Danger
  # This is your plugin class. Any attributes or methods you expose here will
  # be available from within your Dangerfile.
  #
  # To be published on the Danger plugins site, you will need to have
  # the public interface documented. Danger uses [YARD](http://yardoc.org/)
  # for generating documentation from your plugin source, and you can verify
  # by running `danger plugins lint` or `bundle exec rake spec`.
  #
  # You should replace these comments with a public description of your library.
  #
  # @example Ensure people are well warned about merging on Mondays
  #
  #          my_plugin.warn_on_mondays
  #
  # @see  Mat Moore/danger-vale
  # @tags monday, weekends, time, rattata
  #
  class DangerVale < Plugin
    # An attribute that you can read/write from your Dangerfile
    #
    # @return   [Array<String>]
    attr_accessor :my_attribute

    # A method that you can call from your Dangerfile
    # @return   [Array<String>]
    #
    def lint_files(files)
      results = run_valelint(files)

      results.each do |filename, checks|
        by_line = checks.group_by { |check| [check["Line"], check["Severity"]] }

        by_line.each do |(line, severity), checks|
          message = parse_message(checks)

          if severity == "error"
            fail(message, file: filename, line: line)
          else
            warn(message, file: filename, line: line)
          end
        end
      end
    end

  private

    def run_valelint(files)
      out, err, status = Open3.capture3(
        'vale',
        '--output', 'JSON',
        '--no-exit',
        *files
      )

      if status.success?
        return JSON.parse(out)
      else
        raise "Unable to parse vale output"
      end
    end

    def parse_message(checks)
      if checks.length == 1
        checks.first["Message"]
      else
        checks.map { |check| "- " + check["Message"]}.uniq.join("\n")
      end
    end
  end
end
