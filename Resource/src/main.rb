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

# Method
def parseResources(path, type)
    case type.to_sym
    when :strings
        resources = File.readlines(path)
            .filter { |line| line =~ /".*" ?= ?".*";/ }
            .map { |line| 
                key = line.split(/ ?= ?/).first
                    .gsub(/"/, "")
                
                Resource.new(key.camelCase, key)
            }
        resources

    when :assets
        Dir["#{path}/**/*.imageset"].map { |path|
            key = File.basename(path).split(".").first
            
            Resource.new(key.camelCase, key)
        }
    end
end

def generate(outputPath, templatePath, resources)
    templateERB = ERB.new(
        File.read(templatePath), 
        trim_mode: "-"
    )
    File.write(
        outputPath,
        templateERB.result(binding)
    )
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
                :localizable => {
                    :type => :strings,
                    :source => nil,
                    :output => "Resource+Localizable.swift",
                    :template => "#{__dir__}/../template/localizable.erb"
                },
                :image => {
                    :type => :assets,
                    :source => nil,
                    :output => "Resource+Image.swift",
                    :template => "#{__dir__}/../template/image.erb"
                },
                :icon => {
                    :type => :assets,
                    :source => nil,
                    :output => "Resource+Icon.swift",
                    :template => "#{__dir__}/../template/icon.erb"
                }
            }
        })
        rootPath = Pathname.new(arguments["root"]&.first || ROOT_PATH)
        
        # Start generate
        config[:resources].values
            .each { |resource|
                next if resource[:source].nil?
                
                resources = parseResources(
                    rootPath + Pathname.new(resource[:source]), 
                    resource[:type]
                )
                next if resources.empty?

                generate(
                    rootPath + Pathname.new(config[:outputPath]) + Pathname.new(resource[:output]),
                    resource[:template],
                    resources
                )
            }

        puts "✅ Complete generate resources."
    rescue
        abort("#{$!}\nuseage: ruby run.rb [-config config_file_path]")
    end
end
