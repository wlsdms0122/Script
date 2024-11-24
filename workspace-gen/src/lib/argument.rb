#
#  argument.rb
#
#
#  Created by JSilver on 2023/12/31.
#

class Argument
    # Property
    attr_accessor :command
    attr_accessor :aliases, :minCount, :maxCount

    # Initializer
    def initialize(parameters = {})
        @command = parameters.fetch(:command)
        @aliases = parameters.fetch(:aliases, [])
        @minCount = parameters.fetch(:min, 1)
        @maxCount = parameters.fetch(:max, 1)
    end

    # Public
    def isUnlimited?
        @maxCount < @minCount
    end

    def isSatisfied?(arguments)
        return false if arguments.count < @minCount

        return false if !isUnlimited? && arguments.count > @maxCount

        true
    end

    # Private
end

class ArgumentParser
    # Property

    # Initializer
    def initialize(arguments = [], min: nil, max: nil)
        @arguments = arguments.to_h { |argument| [argument.command, argument] }

        return unless @arguments[:argv].nil?

        @arguments[:argv] = Argument.new(command: :argv, min: min || 0, max: max || min || -1)
    end

    # Public
    def parse(arguments)
        result = {}

        argument = @arguments[:argv]
        stack = []

        arguments.each { |argv|
            if argv.start_with?("-") || argv.start_with?("--")
                # Command
                # Get command without '-' delimiter.
                command = argv.sub(/^--?/, '')

                if argument == @arguments[:argv] && !stack.empty?
                    # If option command('-x') apper before arguments.
                    raise StandardError, "InvalidOrder"
                end

                result[argument.command] = stack
                stack = []

                # Find argument that can handle command.
                argument = findArgument(command)

                if argument.nil?
                    # Not exist command parsed.
                    raise StandardError, "UnknownCommand"
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

        raise StandardError, "UnsatisfiedArguments" unless unsatisfiedArguments.empty?

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
