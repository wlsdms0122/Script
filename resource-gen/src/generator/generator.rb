#
#  generator.rb
#
#
#  Created by JSilver on 2024/05/12.
#

# Class
class Generator
    # Property

    # Initializer
    def initialize(
        name,
        templatePath,
        sourcePath,
        outputPath
    )
        @name = name
        @templatePath = templatePath
        @sourcePath = sourcePath
        @outputPath = outputPath
    end

    # Public
    def self.make(type, name, templatePath, sourcePath, outputPath)
        fileName = name.nil? ? "Resource.swift" : "Resource+#{name}.swift"

        case type.to_sym
        when :none
            require_relative "none_generator"

            NoneGenerator.new(
                name,
                templatePath + "resource.erb",
                sourcePath,
                outputPath + fileName
            )

        when :strings
            require_relative "strings_generator"

            StringsGenerator.new(
                name,
                templatePath + "string.erb",
                sourcePath,
                outputPath + fileName
            )

        when :stringCatalog
            require_relative "string_catalog_generator"

            StringCatalogGenerator.new(
                name,
                templatePath + "string.erb",
                sourcePath,
                outputPath + fileName
            )

        when :imageCatalog
            require_relative "image_catalog_generator"

            ImageCatalogGenerator.new(
                name,
                templatePath + "image.erb",
                sourcePath,
                outputPath + fileName
            )

        when :glyphCatalog
            require_relative "image_catalog_generator"

            ImageCatalogGenerator.new(
                name,
                templatePath + "glyph.erb",
                sourcePath,
                outputPath + fileName
            )

        when :colorCatalog
            require_relative "color_catalog_generator"

            ColorCatalogGenerator.new(
                name,
                templatePath + "color.erb",
                sourcePath,
                outputPath + fileName
            )
        end
    end

    def parse(_path)
        raise NotImplementedError
    end

    def generate
        require_relative "resource"

        # Define properties for binding.
        name = @name
        resources = parse(@sourcePath).sort

        # Generate resources from ERB template.
        templateERB = ERB.new(
            File.read(@templatePath),
            trim_mode: "-"
        )
        File.write(
            @outputPath,
            templateERB.result(binding)
        )
    end

    # Private
end

# Method
