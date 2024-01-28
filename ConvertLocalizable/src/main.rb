#
#  main.rb
#
#
#  Created by JSilver on 2023/12/31.
#

require "pathname"
require "json"
require_relative "lib/argument"
require_relative "lib/config"

# Contant

# Class
class Catalog
    # Property
    attr_reader :sourceLanguage
    attr_reader :strings, :version

    # Initializer
    def initialize(sourceLanguage, strings, version = "1.0")
        @sourceLanguage = sourceLanguage
        @strings = strings
        @version = version
    end

    # Public
    def to_json(*options)
        {
            "sourceLanguage": sourceLanguage,
            "strings": strings[sourceLanguage].keys
                .to_h { |key|
                    [
                        key,
                        {
                            "extractionState" => "manual",
                            "localizations" => strings.to_h { |languageCode, strings|
                                if strings[key].nil?
                                    [languageCode, nil]
                                else
                                    [
                                        languageCode,
                                        {
                                            "stringUnit" => {
                                                "state" => "translated",
                                                "value" => strings[key]
                                            }
                                        }
                                    ]
                                end
                            }
                                .compact
                        }
                    ]
                },
            "version": version
        }
            .to_json(*options)
    end

    # Private
end

# Method

# Main
def main(argv)
    # Get arguments
    parser = ArgumentParser.new([
        Argument.new(command: "default", aliases: ["d"], min: 0, max: 1)
    ])

    arguments = parser.parse(argv)

    defaultLanguageCode = arguments["default"]&.first || "ko"
    inputPath = arguments[:argv][0]
    outputPath = arguments[:argv][1]

    begin
        # Check arguments.
        raise "Invalid Arguments" if inputPath.nil? || outputPath.nil?

        # Make string catalog.
        catalog = Catalog.new(
            defaultLanguageCode,
            Dir["#{inputPath}/**/*.strings"]
                .to_h { |path|
                    [
                        Pathname.new(path).parent
                            .basename
                            .to_s
                            .sub(".lproj", ""),
                        File.readlines(path)
                            .filter { |line| line =~ /".*" ?= ?".*";/ }
                            .map { |string| string.strip.split(/ ?= ?/) }
                            .to_h { |value| [value.first.gsub(/^"|"$/, ""), value.last.gsub(/^"|";$/, "")] }
                    ]
                }
        )

        # Save xcstrings file.
        File.write(
            outputPath,
            JSON.pretty_generate(catalog)
        )
    rescue StandardError
        abort(<<~ERROR
            Error: #{$!}
            #{$@.join("\n    ")}

            usage: ruby run.rb [-default default_language_code] <input_path> <output_path>
        ERROR
             )
    end
end
