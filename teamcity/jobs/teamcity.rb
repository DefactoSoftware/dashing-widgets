require 'teamcity'

def update_builds(build_id)
  builds = []

  build = TeamCity.build(id: TeamCity.builds(count: 1, buildType: build_id).first.id)
  date = DateTime.parse(build.startDate)

  build_info = {
    label: "Build #{build.number}",
    value: "#{build.status} on #{date.day}/#{date.month} at #{date.hour}:#{date.min}",
    state: build.status
  }
  builds << build_info

  builds
end

config_file = File.dirname(File.expand_path(__FILE__)) + '/../config/teamcity.yml'
config = YAML::load(File.open(config_file))

TeamCity.configure do |c|
  c.endpoint = config["api_url"]
  c.http_user = config["http_user"]
  c.http_password = config["http_password"]
end

SCHEDULER.every("10m", first_in: '1s') do
  unless config["repositories"].nil?
    config["repositories"].each do |data_id, build_id|
      send_event(data_id, { items: update_builds(build_id)})
    end
  else
    puts "No TeamCity repositories found :("
  end
end
