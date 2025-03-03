#
#  ImageAssetGenerator.rb
#
#
#  Created by JSilver on 2024/05/12.
#

require_relative "generator"

class ImageAssetGenerator < Generator
    # Property

    # Initializer

    # Public
    def parse(path)
        return [] if path.nil?

        assetPath = @rootPath + path
        Dir["#{assetPath}/**/*.imageset"]
            .map { |path| Pathname.new(path) }
            .map { |path|
                puts path
                puts path.basename
                paths = namespaces(path, basePath: assetPath)
                    .append(path.basename.to_s.split(".").first)

                Resource.new(
                    paths.join("_").camelCase,
                    paths.join("/")
                )
            }
    end

    # Private
    def namespaces(path, basePath:)
        path = path.parent

        namespaces = []
        while path != basePath
            namespaces.append(path.basename) if isNamespace(path + "Contents.json")

            path = path.parent
        end

        namespaces.reverse
    end

    def isNamespace(path)
        JSON.load_file(path)
            .dig("properties", "provides-namespace") || false
    end
end
