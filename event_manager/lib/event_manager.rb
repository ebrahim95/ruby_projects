require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

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

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row| 

  name = row[:first_name]
  id = row[0]
  zipcode = clean_zipcode(row[:zipcode])

  phone = clean_homephone(row[:homephone], name)
  puts phone
  legislators = legislators_by_zipcode(zipcode)
  
  personal_letter = erb_template.result(binding)
  save_thank_you_letter(id, personal_letter)
end 



