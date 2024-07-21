#
#  api.rb
#
#
#  Created by JSilver on 2024/07/15.
#

require "net/http"
require "json"
require "ostruct"
require "pp"

# Spec
class Spec
    # Property
    attr_reader :url
    attr_reader :path
    attr_reader :method
    attr_reader :headers
    attr_reader :request
    attr_reader :result
    attr_reader :error

    # Initializer
    def initialize(options = {})
        @url = options[:url]
        @path = options[:path] || ""
        @method = options[:method]
        @headers = options[:headers] || []
        @request = options[:request] || NoneRequest.new()
        @result = options[:result]
        @error = options[:error]
    end

    # Public

    # Private
    private
end

# Request
module Request
    def make(method, url)
        raise NotImplementedError
    end
end

class NoneRequest
    include Request

    # Property
    
    # Initializer
    def make(url)
        URLRequest.new(url)
    end
end

class QueryRequest
    include Request

    # Property
    
    # Initializer
    def initialize(query)
        @query = query
    end

    def make(method, url)
        url.query = @query.map { |key, value| "#{key}=#{value}" }
            .join("&")

        return URLRequest.new(url)
    end
end

class BodyRequest
    include Request

    # Property
    
    # Initializer
    def initialize(object, encoder:)
        @object = object
        @encoder = encoder
    end

    def make(method, url)
        URLRequest.new(url, @encoder.encode(@object))
    end
end

module Encoder
    def encode(object)
        raise NotImplementedError
    end
end

class JSONEncoder
    include Encoder

    def encode(object)
        object.to_json
    end
end

# Mapper
class Mapper
    def initialize(scheme: {})
        @scheme = scheme
    end

    def map(data)
        raise NotImplementedError
    end

    def validate(hash, scheme, path = [])
        scheme.each { |key, value|
            currentPath = path + [key]
            operand = hash[key]

            if value.is_a?(Hash)
                if operand.is_a?(Hash)
                    validate(operand, value, currentPath)
                elsif operand.is_a?(Array)
                    operand.each { |element| validate(element, value, currentPath) }
                else
                    raise "Fail to parse. [#{currentPath.join("/")}]"
                end 
            else
                raise "Fail to parse. [#{currentPath.join("/")}]" if value == :required && operand.nil?
            end
        }
    end
end

class JSONMapper < Mapper
    # Property
    
    # Initializer

    # Public
    def map(data)
        data = data || "{}"

        validate(JSON.parse(data), @scheme)
        return JSON.parse(data, object_class: OpenStruct)
    end

    # Private
    private
end

# API
class API
    # Property
    attr_reader :default_headers
    attr_reader :responser
    
    # Initializer
    def initialize(headers = [], responser)
        @default_headers = headers
        @responser = responser
    end

    # Public
    def request(spec:)
        url = URI.join(spec.url, spec.path)
        
        # Make http request.
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        
        request = spec.request.make(spec.method, url)

        headers = makeHeaders(@default_headers, spec.headers)
        httpRequest = makeRequest(spec.method, request.url, headers)
        
        # Perform request.
        response = http.request(httpRequest, request.body)

        return responser.response(spec, response)
    end

    # Private
    private
    def makeHeaders(default_headers, spec_headers)
        headers = {}
        @default_headers.each { |header|
            if header.is_a?(Proc)
                headers.merge!(header.call())
            else
                headers.merge!(header)
            end
        }
        spec_headers.each { |header|
            if header.is_a?(Proc)
                headers.merge!(header.call())
            else
                headers.merge!(header)
            end
        }

        return headers
    end

    def makeRequest(method, url, headers)
        case method
        when :get
            Net::HTTP::Get.new(url, headers)

        when :post
            Net::HTTP::Post.new(url, headers)

        when :put
            Net::HTTP::Put.new(url, headers)

        when :delete
            Net::HTTP::Delete.new(url, headers)

        when :patch
            Net::HTTP::Patch.new(url, headers)

        else
            raise "Unsupported HTTP method: #{method}"
        end
    end
end

# URLRequest
class URLRequest
    # Property
    attr_reader :url
    attr_reader :body

    # Initializer
    def initialize(url, body = nil)
        @url = url
        @body = body
    end
    
    # Public
    
    # Private
    private
end

# Responser
module Responser
    def response(spec, response)
        raise NotImplementedError
    end
end