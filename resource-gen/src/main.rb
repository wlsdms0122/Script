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
require_relative "lib/log"

require_relative "generator/generator"

# Contant
CONFIG_FILENAME = ".resource.yaml".freeze

# Method

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
        arguments["config"]&.first || CONFIG_FILENAME,
        scheme: {
            outputPath: "./",
            resources: [
                {
                    name: nil,
                    type: nil,
                    source: nil
                }
            ]
        }
    )
    rootPath = Pathname.new(arguments["root"]&.first || ".")

    # Start generation
    templatePath = Pathname.new("#{__dir__}/../template")
    outputPath = rootPath + Pathname.new(config[:outputPath])

    # Generate root `Resource` file.
    Log.info("Start genenrating resources.")
    Log.info("  -> Output : #{outputPath}")
    Log.info("Generate root resource file. (Resource.swift)")
    Generator.make(:none, nil, templatePath, nil, outputPath)
        .generate

    # Generate resources.
    config[:resources].map { |config|
        sourcePath = rootPath + Pathname.new(config[:source])
        
        Log.info("  -> Generate [#{config[:type]}] type resource. (Resource-#{config[:name]}.swift)")
        Generator.make(
            config[:type],
            config[:name],
            templatePath,
            sourcePath,
            outputPath
        )
    }
        .each { |generator| generator&.generate }

    Log.info("Complete resource generating.")
rescue StandardError
    abort(
        <<~ERROR
            Error: #{$!}
            #{$@.join("\n    ")}

            usage: ruby run.rb [-config config file path] [-root root path]
        ERROR
    )
end
