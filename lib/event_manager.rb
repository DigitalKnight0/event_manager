require "csv"
require "google/apis/civicinfo_v2"
require "erb"
require "date"

puts "Event manager initialized!"
template = File.read("form_letter.erb")
erb_template = ERB.new template


#contents = File.read("event_attendees.csv")
#puts contents

#lines = File.readlines("event_attendees.csv")

#lines.each  do |l|
#    col = l.split(",")
#    name = col[2]
#    p name
#end

#lines.each_with_index do |a ,ind|
#    next if ind == 0
#    col = a.split(",")
#    name = col[2]
#    p name
#end

#contents = CSV.open("event_attendees.csv" , headers: true)

def clean_zip(zip)
    zip.to_s.rjust(5 , "0")[0..4]
end

def find_legislators(zip)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

    begin  
        legislators = civic_info.representative_info_by_address(
            address: zip,
            levels: "country",
            roles: ["legislatorUpperBody" , "legislatorLowerBody"]
        )
    
        legislators = legislators.officials 
       
    
       rescue
        'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
       end
    end

    def form_creater(id , form)
        Dir.mkdir("output") unless Dir.exist?("output")

        filename = "output/thanks#{id}.html"

        File.open(filename , "w") do |file|
            file.puts form
        end
    end

    def clean_num(num)
        num = num.to_s
        num.gsub!(/[-()]/, "")
        if num.length == 11 && num[0] == 1
            num[1..10]
        elsif num.length == 10
            num
        else
            "Invalid Number"
        end
    end

    def clean_datentimes(data)
        identifier = "%m/%d/%y %k:%M"
        data.each_with_index do |x , idx|
            regdate = DateTime.strptime(x , identifier)
            data[idx] = regdate
        end
        data
    end

    def peak_hours(times)
        hours = []
        times.each do |x|
         hours.push(x.hour)
        end
        
        hash = hours.reduce({}) do |hr , num|
            hr[num] = hours.count(num)
            hr
        end

        puts "The Peak times were as follows"
        hash.each do |k,v|
          puts "#{v} people registered at #{k}:00 Hours"
        end
    end

    def peak_days(times)
        days = []
        times.each do |x|
         currentDay = x.strftime("%A")
         days.push(currentDay)
        end
        
        hash = days.reduce({}) do |day , num|
            day[num] = days.count(num)
            day
        end

        puts "The peak days were as follows"
        hash.each do |k,v|
          puts "#{v} people registered on #{k}"
        end
    end




contents = CSV.open(
    "event_attendees.csv",
    headers: true,
    header_converters: :symbol
)
  datentime = []
contents.each do |line|
    id = line[0]
    name = line[:first_name]
    zip = line[:zipcode]
    number = line[:homephone]
    datentime.push(line[:regdate])
     # if the zip code is exactly five digits, assume that it is ok
  # if the zip code is more than five digits, truncate it to the first five digits
  # if the zip code is less than five digits, add zeros to the front until it becomes five digits
    zip = clean_zip(zip)
    num = clean_num(number)
    legislators = find_legislators(zip)
    
    personal_letter = erb_template.result(binding)
    
    #form_creater(id , personal_letter)

end
cleandates = clean_datentimes(datentime)
peak_hours(cleandates)
peak_days(cleandates)

