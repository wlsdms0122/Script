#
#  main.rb
#  
#
#  Created by JSilver on 2024/07/15.
#

require_relative "lib/api"
require_relative "lib/argument"
require "json"

class DefaultResponser
    include Responser

    def response(spec, response)
        spec.result.map(response.body)
    end
end

class CreateReleaseSpec < Spec
    def initialize(parameter)
        super({
            :url => "--your-jira-url--",
            :path => "/rest/api/3/version",
            :method => :post,
            :request => BodyRequest.new({
                "archived" => false,
                "name" => parameter["name"],
                "projectId" => parameter["projectID"],
                "releaseDate" => "#{parameter["releaseDate"]}",
                "released" => true
            }, encoder: JSONEncoder.new()),
            :result => JSONMapper.new(scheme: {
                "id" => :required
            })
        })
    end
end

class AddReleatedIssueSpec < Spec
    def initialize(parameter)
        super({
            :url => "--your-jira-url--",
            :path => "/rest/api/3/issue/#{parameter["key"]}",
            :method => :put,
            :request => BodyRequest.new({
                "update" => {
                    "fixVersions" => [
                        { 
                            "add" => { 
                                "id" => "#{parameter["releaseID"]}"
                            } 
                        }
                    ]
                }
            }, encoder: JSONEncoder.new()),
            :result => JSONMapper.new()
        })
    end
end

class SearchIssuesSpec < Spec
    def initialize(parameter)
        super({
            :url => "--your-jira-url--",
            :path => "/rest/api/3/search",
            :method => :get,
            :request => QueryRequest.new({
                "jql" => "issue in (#{parameter.join(", ")})"
            }),
            :result => JSONMapper.new(scheme: {
                "issues" => {
                    "key" => :required,
                    "fields" => {
                        "summary" => :required
                    }
                }
            })
        })
    end
end

# Method
def getIssueKeys(commitPattern, issueKeys)
    commitRegex = /#{commitPattern}/
    issueKeyRegex = /^(#{issueKeys})-\d+$/

    logs = `git log --format="%s" $(git describe --abbrev=0 --tags HEAD~1)..@`
    return logs.each_line.flat_map { |log|
        matchData = log.match(commitRegex)
        if matchData.nil?
            nil
        else
            matchData[0].split(", ")
                .filter { |log| issueKeyRegex.match?(log) }
        end
    }
        .compact
        .uniq
        .sort
end

def createRelease(keys, projectID, name, releaseDate)
    # Create relase
    release = $api.request(spec: CreateReleaseSpec.new({
        "projectID" => projectID,
        "name" => name,
        "releaseDate" => releaseDate.strftime("%Y-%m-%d")
    }))

    # Link releated issues
    threads = []
    keys.each { |key|
        threads << Thread.new {
            $api.request(spec: AddReleatedIssueSpec.new({
                "key" => key,
                "releaseID" => release.id
            }))
        }
    }

    threads.each(&:join)
end

def createChangeLogs(keys)
    if keys.empty?
        return
    end

    result = $api.request(spec: SearchIssuesSpec.new(keys))
    return result.issues.map { |issue| "[#{issue.key}] #{issue.fields.summary}" }
end

# Global
$api = API.new(
    [
        { 
            "Authorization" => "Basic --your-jira-api-token--",
            "Content-Type" => "application/json"
        }
    ], 
    DefaultResponser.new()
)

# Main
def main(argv)
    # Get arguments.
    arguments = ArgumentParser.new([
        Argument.new(command: "project", aliases: ["p"]),
        Argument.new(command: "commit", aliases: ["c"]),
        Argument.new(command: "key")
    ], min: 1)
        .parse(argv)
    
    projectID = arguments["project"].first
    commitPattern = arguments["commit"].first
    issueKeys = arguments["key"].first
    releaseName = arguments[:argv].first

    # Get relative issue keys.
    keys = getIssueKeys(commitPattern, issueKeys)
    
    # Create release.
    createRelease(keys, projectID, releaseName, Time.now)
end