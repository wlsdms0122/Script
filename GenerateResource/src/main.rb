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

require_relative "generator/none_generator"
require_relative "generator/color_asset_generator"
require_relative "generator/image_asset_generator"
require_relative "generator/strings_generator"
require_relative "generator/string_catalog_generator"

# Contant
CONFIG_PATH = ".resource.yaml".freeze
ROOT_PATH = Dir.pwd

# Method
def makeGenerator(type, rootPath, outputPath, templatePath, sourcePath)
    case type.to_sym
    when :strings
        StringsGenerator.new(rootPath, outputPath, templatePath, sourcePath)

    when :stringCatalog
        StringCatalogGenerator.new(rootPath, outputPath, templatePath, sourcePath)

    when :imageAsset
        ImageAssetGenerator.new(rootPath, outputPath, templatePath, sourcePath)

    when :colorAsset
        ColorAssetGenerator.new(rootPath, outputPath, templatePath, sourcePath)
    end
end

# Main
def main(argv)
    # Get arguments
    arguments = ArgumentParser.new([
        Argument.new(command: "config", aliases: ["c"], min: 0, max: 1),
        Argument.new(command: "root", aliases: ["r"], min: 0, max: 1)
    ])
        .parse(argv)

    # Arguments
    config = Config.new(
        arguments["config"]&.first || CONFIG_PATH,
        scheme: {
            outputPath: "./",
            resources: {
                string: {
                    type: :strings,
                    source: nil,
                    skip: nil
                },
                color: {
                    type: :colorAsset,
                    source: nil,
                    skip: nil
                },
                image: {
                    type: :imageAsset,
                    source: nil,
                    skip: nil
                },
                icon: {
                    type: :imageAsset,
                    source: nil,
                    skip: nil
                }
            }
        }
    )
    rootPath = Pathname.new(arguments["root"]&.first || ROOT_PATH)

    begin
        # Start generation
        outputPath = Pathname.new(config[:outputPath])
        templatePath = Pathname.new("#{__dir__}/../template")

        # Generate root `Resource` file.
        NoneGenerator.new(
            rootPath,
            outputPath + "Resource.swift",
            templatePath + "resource.erb",
            nil
        )
            .generate

        # Generate resources.
        config[:resources]
            .filter { |_, config| !(config[:skip] || false) }
            .map { |key, config|
                case key
                when :string
                    makeGenerator(
                        config[:type],
                        rootPath,
                        outputPath + "Resource+String.swift",
                        templatePath + "string.erb",
                        Pathname.new(config[:source])
                    )

                when :color
                    makeGenerator(
                        config[:type],
                        rootPath,
                        outputPath + "Resource+Color.swift",
                        templatePath + "color.erb",
                        Pathname.new(config[:source])
                    )

                when :image
                    makeGenerator(
                        config[:type],
                        rootPath,
                        outputPath + "Resource+Image.swift",
                        templatePath + "image.erb",
                        Pathname.new(config[:source])
                    )

                when :icon
                    makeGenerator(
                        config[:type],
                        rootPath,
                        outputPath + "Resource+Icon.swift",
                        templatePath + "icon.erb",
                        Pathname.new(config[:source])
                    )
                end
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
