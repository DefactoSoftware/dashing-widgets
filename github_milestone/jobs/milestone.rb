require 'rest-client'
require 'json'
require 'date'

def update_milestone(repository, token)
  next_milestone = {}

  uri = "https://api.github.com/repos/#{repository}/milestones?access_token=#{token}"
  response = RestClient.get uri
  milestones = JSON.parse(response.body, symbolize_names: true)

  # Remove all the milestones with no due date, or where all the issues are closed.
  milestones.select! { |milestone| !milestone[:due_on].nil? and (milestone[:open_issues] > 0) }

  if milestones.length > 0
    milestones.sort! { |a,b| a[:due_on] <=> b[:due_on] }

    next_milestone = milestones.first
    days_left = (Date.parse(next_milestone[:due_on]) - Date.today).to_i
    if days_left > 0
      due = "Due in #{days_left} days"
    elsif days_left == 0
      due = "Due today"
    else
      due = "Overdue by #{days_left.abs} days"
    end

    next_milestone = {
      milestone: "#{next_milestone[:title] || 'Unnamed Milestone'}",
      time: due,
      moreinfo: "#{next_milestone[:open_issues]}/#{next_milestone[:open_issues] + next_milestone[:closed_issues]} issues remain"
    }
  else
    # There are no milestones left with open issues.
    next_milestone = {
      milestone: "None",
      time: "",
      moreinfo: ""
    }
  end
  next_milestone
end

config_file = File.dirname(File.expand_path(__FILE__)) + '/../config/github.yml'
config = YAML::load(File.open(config_file))

SCHEDULER.every '10m', :first_in => 0 do |job|
  unless config["repositories"].nil?
    config["repositories"].each do |data_id, repository|
        send_event(data_id, update_milestone(repository, config["token"]))
    end
  else
    puts "No Github repositories found :("
  end
end
