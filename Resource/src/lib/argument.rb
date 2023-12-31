#
#  argument.rb
#  
#
#  Created by JSilver on 2023/12/31.
#

class Argument
    # Property
    attr_accessor :command
    attr_accessor :aliases
    attr_accessor :minCount
    attr_accessor :maxCount

    # Initializer
    def initialize(parameters = { })
        @command = parameters.fetch(:command)
        @aliases = parameters.fetch(:aliases, [])
        @minCount = parameters.fetch(:min, 1)
        @maxCount = parameters.fetch(:max)
    end

    # Public
    def isUnlimited?
        @maxCount < @minCount
    end

    def isSatisfied?(arguments)
        if arguments.count < @minCount
            return false
        end

        if !isUnlimited? && arguments.count > @maxCount
            return false
        end

        return true
    end

    # Private
    private
end

class ArgumentParser
    # Property

    # Initializer
    def initialize(arguments = [])
        @arguments = arguments.to_h { |argument| [argument.command, argument] }

        if @arguments[:argv].nil?
            @arguments[:argv] = Argument.new(command: :argv, min: 0, max: -1)
        end
    end

    # Public
    def parse(arguments)
        result = { }

        argument = @arguments[:argv]
        stack = []

        arguments.each { |argv|
            if argv.start_with?('-')
                # Command
                # Get command without '-' delimiter.
                command = argv[1, argv.length - 1]

                if argument == @arguments[:argv] && !stack.empty?
                    # If option command('-x') apper before arguments.
                    raise StandardError.new("InvalidOrder")
                end

                result[argument.command] = stack
                stack = []

                # Find argument that can handle command.
                argument = findArgument(command)
                
                if argument.nil?
                    # Not exist command parsed.
                    raise StandardError.new("UnknownCommand")
                end
            else
                # Argument
                if !argument.isUnlimited? && stack.count >= argument.maxCount
                    # Argument already fill through arguments.
                    result[argument.command] = stack
                    stack = []

                    argument = @arguments[:argv]
                end

                # Stack argument.
                stack << argv
            end
        }

        result[argument.command] = stack
        
        unsatisfiedArguments = @arguments.values
            .filter { |argument| !argument.isSatisfied?(result[argument.command] || []) }

        if !unsatisfiedArguments.empty?
            raise StandardError.new("UnsatisfiedArguments")
        end

        result
    end

    # Private
    private
    def findArgument(command)
        @arguments.values
            .filter { |argument| ([argument.command] + argument.aliases).include?(command) }
            .first
    end
end