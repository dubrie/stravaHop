require 'optparse'      # Parses command line options
require 'strava/api/v3'
require 'logger'
require 'yaml'          # Parses configuration files

api = YAML.load_file("config.yaml")[:strava_api]

DEBUG = false
DATE_FORMAT = "%Y-%m-%d"

# Parse the command line options
options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: stravaHop.rb [options]"

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
    DEBUG = true
  end

  opts.on("-d", "--date_override #{DATE_FORMAT}", "Override the current date, defaults to current system date.") do |d|
    options[:cur_date] = DateTime.now
    if d 
        if DEBUG
            puts "date override provided: #{d}"
        end
        options[:cur_date] = DateTime.strptime("#{d}", DATE_FORMAT)
    end
  end

end.parse!

if DEBUG
    p options
end

cur_date = options[:cur_date] || DateTime.now

@client = Strava::Api::V3::Client.new(:access_token => api['token'])

first_activity = @client.list_athlete_activities({:after => 0, :per_page => 1})
first_activity_date = DateTime.parse(first_activity[0]['start_date'])
first_activity_year = first_activity_date.strftime("%Y").to_i
current_year = cur_date.year.to_i
current_month = cur_date.strftime("%m")
current_day = cur_date.strftime("%d")
current_month_day = "#{current_month} #{current_day}"

puts "first activity date: #{first_activity_date}"
puts "first activity year: #{first_activity_year}"
puts "current year: #{current_year}"

hopped_activities = []

current_year -= 1
while current_year >= first_activity_year
	puts "Checking for #{current_month_day}, #{current_year}"
	t  = DateTime.new(current_year, current_month.to_i, current_day.to_i).strftime('%s')
	if DEBUG
		puts "    time: #{t.to_i}"
	end
	activities = @client.list_athlete_activities({:after => t.to_i, :per_page => 5})
	activities.each do |activity|
		activity_date = DateTime.parse(activity['start_date'])
		activity_month_day = activity_date.strftime("%m %d")
		if DEBUG
			puts "    Activity month day: #{activity_month_day}"
		end
		if activity_month_day == current_month_day
			puts "#{activity['start_date']} - #{activity['name']}"
			hopped_activities << activity
		else
			if DEBUG
				puts "      skipping #{activity['start_date']}"
			end
		end
	end
	current_year -= 1
end

puts "Hopped activities: #{hopped_activities.length}"
puts "#{hopped_activities}"
