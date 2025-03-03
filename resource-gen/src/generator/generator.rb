#
#  Generator.rb
#
#
#  Created by JSilver on 2024/05/12.
#

# Class
class Resource
    include Comparable

    # Property
    attr_reader :key
    attr_reader :value
    attr_reader :content

    # Initializer
    def initialize(key, value, content = nil)
        @key = key
        @value = value
        @content = content
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
        templatePath,
        sourcePath
    )
        @rootPath = rootPath
        @outputPath = outputPath
        @templatePath = templatePath
        @sourcePath = sourcePath
    end

    # Public
    def parse(_path)
        raise NotImplementedError
    end

    def generate
        resources = parse(@sourcePath)
            .sort

        templateERB = ERB.new(
            File.read(@rootPath + @templatePath),
            trim_mode: "-"
        )
        File.write(
            @rootPath + @outputPath,
            templateERB.result(binding)
        )
    end

    # Private
end

# Method
