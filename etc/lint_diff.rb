#  
#  lint_diff.rb
#  
#  
#  Created by JSilver on 2024/12/01.
#  

# Function
def getGitChanges()
    `git status -s | awk '{print $2}'`.split("\n")
        .filter { |filename| filename.end_with?(".swift") }
end

# Main
def main(argv)
    commandPath = argv[0]
    configPath = argv[1]
    configuration = argv[2]
    
    # Check if the configuration requires linting (Debug only)
    unless configuration.match(/\w*-[dD]ebug/)
        puts "info: #{configuration} doesn't need lint."
        return 0
    end
    
    # Check lint command available.
    unless system("command -v #{commandPath} > /dev/null 2>&1")
        puts "error: #{commandPath} command not found."
        return 1
    end
    
    files = getGitChanges()
    unless !files.empty?
        puts "info: No changes to lint."
        return 0
    end
    
    # Perform lint.
    warn `#{commandPath} lint --autocorrect --config #{configPath} #{files.join(" ")}`
end

# ruby lint_diff.rb command_path config_path configuration
main(ARGV)
