#
#  strings_generator.rb
#
#
#  Created by JSilver on 2024/05/12.
#

require_relative "generator"

# Class
class StringsGenerator < Generator
    # Property

    # Initializer

    # Public
    def parse(path)
        return [] if path.nil?

        File.readlines(path)
            .filter { |line| line =~ /".*" ?= ?".*";/ }
            .map { |line|
                components = line.split(/ ?= ?/)

                key = components[0].scan(/(?<=").*(?=")/).first
                content = components[1].scan(/(?<=").*(?=")/).first

                Resource.new(key.camelCase, key, content)
            }
    end

    # Private
end
