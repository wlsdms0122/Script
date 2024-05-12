#
#  StringCatalogGenerator.rb
#
#
#  Created by JSilver on 2024/05/12.
#

require_relative "generator"

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
