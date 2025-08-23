#
#  string_catalog_generator.rb
#
#
#  Created by JSilver on 2024/05/12.
#

require_relative "generator"

# Class
class StringCatalogGenerator < Generator
    # Property

    # Initializer

    # Public
    def parse(path)
        return [] if path.nil?

        JSON.load_file(path)["strings"]
            .map { |key, value|
                localization = value["localizations"].first.last
                value = localization.dig("stringUnit", "value")

                Resource.new(key.camelCase, key, value)
            }
    end

    # Private
end
