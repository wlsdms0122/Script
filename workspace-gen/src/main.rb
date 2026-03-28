#  
#  main.rb
#  
#  
#  Created by JSilver on 2023/04/25.
#  

require 'pathname'
require 'yaml'
require 'erb'
require_relative 'lib/argument'
require_relative 'lib/config'

# Constants
WORKSPACE_DATA_TEMPLATE = File.expand_path("../template/contents.xcworkspacedata.erb", __dir__)
FILE_TEMPLATE = File.expand_path("../template/file.erb", __dir__)
GROUP_TEMPLATE = File.expand_path("../template/group.erb", __dir__)

OUTPUT_FILE = "contents.xcworkspacedata"

CONFIG_FILE = ".workspace-gen.yaml"
CONFIG_SEARCH_PATHS = [
    File.expand_path(CONFIG_FILE),
    File.expand_path("../#{CONFIG_FILE}", __dir__)
]

INDENT_SPACE = 3

# Functions
def generate(workspacePath, folders: [])
    workspacePath = Pathname.new(workspacePath)

    # Generate content.xcworkspacedata file.
    workspace = ERB.new(File.read(WORKSPACE_DATA_TEMPLATE))
    content = generateContent(
        readComponents(workspacePath, folders: folders),
        indent: INDENT_SPACE
    )

    # Write content.xcworkspace data file.
    File.write(
        workspacePath / Pathname.new(OUTPUT_FILE),
        workspace.result(binding)
    )
end

def readComponents(workspacePath, folders: [])
    # Read package & projects.
    xcodeprojs =  Dir["**/*.xcodeproj"].map do |xcodeproj|
        path = Pathname.new(xcodeproj)
        path.realpath.relative_path_from(workspacePath.parent.realpath).to_s
    end

    packages = Dir["**/*/Package.swift"].map do |package|
        path = Pathname.new(package).parent
        path.realpath.relative_path_from(workspacePath.parent.realpath).to_s
    end

    # Sort by prioirty.
    components = (xcodeprojs + packages + folders).sort do |lhs, rhs|
        comparePath(lhs, rhs)
    end

    # Convert components to tree structure.
    return toTree(components)
end

def comparePath(lhs, rhs)
    lhsComponents = lhs.split("/")
    rhsComponents = rhs.split("/")
    
    minLength = [lhsComponents.length, rhsComponents.length].min
    
    (0...minLength).each do |i|
        next if lhsComponents[i] == rhsComponents[i]
        
        if i < minLength - 1 || lhsComponents.length == rhsComponents.length
            return lhsComponents[i] <=> rhsComponents[i]
        else
            return rhsComponents.length <=> lhsComponents.length
        end
    end
    
    lhs <=> rhs
end

def toTree(paths)
    tree = {}
    
    paths.each do |path|
        pathComponents = path.split('/')
        
        node = tree
        pathComponents.each do |component|
            node[component] ||= {}
            node = node[component]
        end
    end
    
    return tree
end

def generateContent(components, path: "", indent:)
    content = ""
    indentString = " " * indent
    
    components.each do | key, value |
        if value.empty?
            # File
            template = ERB.new(File.read(FILE_TEMPLATE))
            location = path.empty? ? key : "#{path}/#{key}"
            
            content += template.result(binding)
        else
            # Directory
            template = ERB.new(File.read(GROUP_TEMPLATE))
            name = key
            children = generateContent(
                value, 
                path: path.empty? ? key : "#{path}/#{key}", 
                indent: indent + INDENT_SPACE
            )
            
            content += template.result(binding)
        end
        
        content += "\n"
    end
    
    # Remove last '\n' character.
    return content.chomp
end
  
# Main
def main(argv)
    # Parse arguments.
    arguments = ArgumentParser.new([
        Argument.new(command: "config", aliases: ["c"], min: 0, max: 1)
    ]).parse(argv)

    # Resolve config path.
    configPath = if arguments["config"]&.first
        File.expand_path(arguments["config"].first)
    else
        CONFIG_SEARCH_PATHS.find { |path| File.exist?(path) }
    end

    # Load config.
    config = Config.new(configPath, scheme: {
        workspace: nil,
        folders: []
    })

    # Check arguments.
    workspacePath = config[:workspace] || Dir["*.xcworkspace"].first
    folders = config[:folders]

    generate(workspacePath, folders: folders)
    puts "✅ Workspace content generation complete."
rescue StandardError => e
    abort(
        <<~ERROR
            Error: #{e.message}
            #{e.backtrace.join("\n    ")}

            usage: ruby run.rb [--config <config_path>]

            Options:
              --config, -c    Path to config file (optional)
                              Search priority:
                                1. CLI --config path
                                2. .workspace-gen.yaml in current directory
                                3. Default config in script module
        ERROR
    )
end
