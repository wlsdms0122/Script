#
#  resource.rb
#
#
#  Created by JSilver on 2025/08/23.
#

# Class
class Resource
    include Comparable

    # Property
    attr_reader :key
    attr_reader :value, :content

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
