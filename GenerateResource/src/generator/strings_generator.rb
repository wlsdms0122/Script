#
#  StringsGenerator.rb
#
#
#  Created by JSilver on 2024/05/12.
#

require_relative "generator"

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
