#
#  main.rb
#  
#
#  Created by JSilver on 2023/12/31.
#

require 'pathname'
require 'yaml'
require 'erb'
require_relative 'lib/util'
require_relative 'lib/argument'
require_relative 'lib/config'

# Contant
CONFIG_PATH = ".resource.yaml"
ROOT_PATH = Dir.pwd

Resource = Struct.new(:key, :value)

# Class
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
    def parse(path)
        raise NotImplementedError.new
    end
    
    def generate
        if @templatePath.nil?
            raise StandardError.new("Template file path not specified.")
        end

        if @outputPath.nil? || @output.nil?
            raise StandardError.new("Output file path not specified.")
        end

        resources = parse(@sourcePath)

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
    private
end

class NoneGenerator < Generator
    # Property

    # Initializer

    # Public
    def parse(path)
        []
    end

    private
    # Private
end

class StringsGenerator < Generator
    # Property

    # Initializer

    # Public
    def parse(path)
        if path.nil?
            return []
        end

        File.readlines(@rootPath + path)
            .filter { |line| line =~ /".*" ?= ?".*";/ }
            .map { |line| 
                key = line.split(/ ?= ?/).first
                    .gsub(/"/, "")
                
                Resource.new(key.camelCase, key)
            }
    end

    private
    # Private
end

class AssetsGenerator < Generator
    # Property

    # Initializer
    
    # Public
    def parse(path)
        if path.nil?
            return []
        end

        Dir["#{@rootPath + path}/**/*.imageset"].map { |path|
            key = File.basename(path).split(".").first
            
            Resource.new(key.camelCase, key)
        }
    end

    private
    # Private
end

# Method
def makeGenerator(type, rootPath, outputPath, output, templatePath, sourcePath)
    case type.to_sym
    when :none
        NoneGenerator.new(rootPath, outputPath, output, templatePath, sourcePath)

    when :strings
        StringsGenerator.new(rootPath, outputPath, output, templatePath, sourcePath)

    when :assets
        AssetsGenerator.new(rootPath, outputPath, output, templatePath, sourcePath)
    end
end

# Main
def main(argv)
    begin
        # Get arguments
        parser = ArgumentParser.new([
            Argument.new(command: "config", aliases: ["c"], min: 0, max: 1),
            Argument.new(command: "root", aliases: ["r"], min: 0, max: 1)
        ])

        arguments = parser.parse(argv)

        # Arguments
        config = Config.new(arguments["config"]&.first || CONFIG_PATH, scheme: {
            :outputPath => "./",
            :resources => {
                :root => {
                    :type => :none,
                    :source => nil,
                    :output => "Resource.swift",
                    :template => "#{__dir__}/../template/resource.erb",
                    :skip => false
                },
                :string => {
                    :type => :strings,
                    :source => nil,
                    :output => "Resource+Localizable.swift",
                    :template => "#{__dir__}/../template/localizable.erb",
                    :skip => false
                },
                :image => {
                    :type => :assets,
                    :source => nil,
                    :output => "Resource+Image.swift",
                    :template => "#{__dir__}/../template/image.erb",
                    :skip => false
                },
                :icon => {
                    :type => :assets,
                    :source => nil,
                    :output => "Resource+Icon.swift",
                    :template => "#{__dir__}/../template/icon.erb",
                    :skip => false
                }
            }
        })
        rootPath = Pathname.new(arguments["root"]&.first || ROOT_PATH)
        
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
            .each { |generator| generator.generate() }

        puts "✅ Complete generate resources."
    rescue
        abort(<<~ERROR
            Error: #{$!}
            #{$@.join("\n    ")}
            
            useage: ruby run.rb [-config config_file_path] [-root root_path]
            ERROR
        )
    end
end
