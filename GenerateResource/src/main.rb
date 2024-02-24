#
#  main.rb
#
#
#  Created by JSilver on 2023/12/31.
#

require "pathname"
require "yaml"
require "json"
require "erb"
require_relative "lib/util"
require_relative "lib/argument"
require_relative "lib/config"

# Contant
CONFIG_PATH = ".resource.yaml".freeze
ROOT_PATH = Dir.pwd

# Class
class Resource
    include Comparable

    # Property
    attr_reader :key
    attr_reader :value

    # Initializer
    def initialize(key, value)
        @key = key
        @value = value
    end

    # Public
    def <=>(other)
        @key <=> other.key
    end

    # Private
end

class Generator
    # Property

    # Initializer
    def initialize(
        rootPath,
        outputPath,
        output,
        templatePath,
        sourcePath
    )
        @rootPath = Pathname.new(rootPath)
        @outputPath = outputPath
        @output = output
        @templatePath = templatePath
        @sourcePath = sourcePath
    end

    # Public
    def parse(_path)
        raise NotImplementedError
    end

    def generate
        raise StandardError, "Template file path not specified." if @templatePath.nil?

        raise StandardError, "Output file path not specified." if @outputPath.nil? || @output.nil?

        resources = parse(@sourcePath)
            .sort

        templateERB = ERB.new(
            File.read(@rootPath + @templatePath),
            trim_mode: "-"
        )
        File.write(
            @rootPath + @outputPath + @output,
            templateERB.result(binding)
        )
    end

    # Private
end

class NoneGenerator < Generator
    # Property

    # Initializer

    # Public
    def parse(_path)
        []
    end

    # Private
end

class StringsGenerator < Generator
    # Property

    # Initializer

    # Public
    def parse(path)
        return [] if path.nil?

        File.readlines(@rootPath + path)
            .filter { |line| line =~ /".*" ?= ?".*";/ }
            .map { |line|
                key = line.split(/ ?= ?/).first
                    .gsub(/"/, "")

                Resource.new(key.camelCase, key)
            }
    end

    # Private
end

class StringCatalogGenerator < Generator
    # Property

    # Initializer

    # Public
    def parse(path)
        return [] if path.nil?

        JSON.load_file(path)["strings"]
            .keys
            .map { |key| Resource.new(key.camelCase, key) }
    end

    # Private
end

class AssetsGenerator < Generator
    # Property

    # Initializer

    # Public
    def parse(path)
        return [] if path.nil?

        Dir["#{@rootPath + path}/**/*.imageset"].map { |path|
            key = File.basename(path).split(".").first

            Resource.new(key.camelCase, key)
        }
    end

    # Private
end

# Method
def makeGenerator(type, rootPath, outputPath, output, templatePath, sourcePath)
    case type.to_sym
    when :none
        NoneGenerator.new(rootPath, outputPath, output, templatePath, sourcePath)

    when :strings
        StringsGenerator.new(rootPath, outputPath, output, templatePath, sourcePath)

    when :stringCatalog
        StringCatalogGenerator.new(rootPath, outputPath, output, templatePath, sourcePath)

    when :assets
        AssetsGenerator.new(rootPath, outputPath, output, templatePath, sourcePath)
    end
end

# Main
def main(argv)
    # Get arguments
    parser = ArgumentParser.new([
        Argument.new(command: "config", aliases: ["c"], min: 0, max: 1),
        Argument.new(command: "root", aliases: ["r"], min: 0, max: 1)
    ])
    arguments = parser.parse(argv)

    # Arguments
    config = Config.new(
        arguments["config"]&.first || CONFIG_PATH, scheme: {
            outputPath: "./",
            resources: {
                root: {
                    type: :none,
                    source: nil,
                    output: "Resource.swift",
                    template: "#{__dir__}/../template/resource.erb",
                    skip: false
                },
                string: {
                    type: :strings,
                    source: nil,
                    output: "Resource+Localizable.swift",
                    template: "#{__dir__}/../template/localizable.erb",
                    skip: false
                },
                image: {
                    type: :assets,
                    source: nil,
                    output: "Resource+Image.swift",
                    template: "#{__dir__}/../template/image.erb",
                    skip: false
                },
                icon: {
                    type: :assets,
                    source: nil,
                    output: "Resource+Icon.swift",
                    template: "#{__dir__}/../template/icon.erb",
                    skip: false
                }
            }
        }
    )
    rootPath = Pathname.new(arguments["root"]&.first || ROOT_PATH)

    begin
        # Start generate
        config[:resources].values
            .filter { |resource| !(resource[:skip] || false) }
            .map { |resource|
                makeGenerator(
                    resource[:type],
                    rootPath,
                    config[:outputPath],
                    resource[:output],
                    resource[:template],
                    resource[:source]
                )
            }
            .each { |generator| generator&.generate }

        puts "✅ Complete generate resources."
    rescue StandardError
        abort(
            <<~ERROR
                Error: #{$!}
                #{$@.join("\n    ")}

                usage: ruby run.rb [-config config_file_path] [-root root_path]
            ERROR
        )
    end
end
