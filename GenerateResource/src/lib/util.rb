#
#  util.rb
#
#
#  Created by JSilver on 2023/12/31.
#

class String
    def camelCase
        split("_").inject { |m, p| m + p.capitalize }
    end
end
