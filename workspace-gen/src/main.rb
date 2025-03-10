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

INDENT_SPACE = 3

# Functions
def generate(workspacePath)
    workspacePath = Pathname.new(workspacePath)
    
    # Generate content.xcworkspacedata file.
    workspace = ERB.new(File.read(WORKSPACE_DATA_TEMPLATE))
    content = generateContent(
        readComponents(workspacePath), 
        indent: INDENT_SPACE
    )
    
    # Write content.xcworkspace data file.
    File.write(
        workspacePath / Pathname.new(OUTPUT_FILE), 
        workspace.result(binding)
    )
end

def readComponents(workspacePath)
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
    components = (xcodeprojs + packages).sort do |lhs, rhs| 
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
            location = "#{path}/#{key}"
            
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
    begin
        # Get arguments.
        arguments = ArgumentParser.new().parse(argv)
        
        # Check arguments.
        workspacePath = arguments[:argv]&.first || Dir["*.xcworkspace"].first
        
        generate(workspacePath)
        puts "✅ Workspace content generation complete."
    rescue StandardError
        abort(
            <<~ERROR
                Error: #{$!}
                #{$@.join("\n    ")}

                usage: ruby run.rb [workspace path]
            ERROR
        )
    end
end
