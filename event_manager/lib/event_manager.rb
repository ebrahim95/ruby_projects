require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'
require 'time'

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)


def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_homephone(phone, name)
  number = phone.to_s.gsub(/[^0-9]/, '')

  if number.length == 10 
    number 
  elsif number.length == 11 && number[0] == '1' 
      number[1..10]
  else 
    "You have a invalid phone number, #{name}"
  end
end


def legislators_by_zipcode(zipcode) 

  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin 
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: [
        'legislatorUpperBody',
        'legislatorLowerBody'
      ]
    )

    legislators = legislators.officials
    legislators
  rescue 
    'You can find your respresentatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end 
end 

def save_thank_you_letter(id, form_letter)

  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end 


end

# compare hour and time

hour_of_the_day = []
day_of_the_week = []


template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row| 

  name = row[:first_name]
  id = row[0]
  zipcode = clean_zipcode(row[:zipcode])
  date_time = row[:regdate]
  parsed_date = Time.strptime(date_time, '%m/%d/%y %H:%M')
  hour_of_the_day.push(parsed_date.hour)
  day_of_the_week.push(parsed_date.wday)

  phone = clean_homephone(row[:homephone], name)

  legislators = legislators_by_zipcode(zipcode)
   
  personal_letter = erb_template.result(binding)
  save_thank_you_letter(id, personal_letter)
end 


calendar = ['Sunday', 'Monday', 'Tuesday','Wednesday', 'Thursday', 'Friday', 'Saturday']

puts "The most common hours were #{hour_of_the_day.max_by{ |x| hour_of_the_day.count(x)}}"
puts "The most common day was #{calendar[day_of_the_week.max_by{ |x| day_of_the_week.count(x)}]}"

