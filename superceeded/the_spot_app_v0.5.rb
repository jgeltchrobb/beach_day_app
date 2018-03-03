require 'open_weather'
require 'geokit'

Geokit::default_units = :kms
Geokit::Geocoders::request_timeout = 3
Geokit::Geocoders::GoogleGeocoder.api_key = 'AIzaSyDJC7s7rtUPQr18ymAqPm_CHeqxx-s8RIE'


beaches_coords = {
    noosa: {lat:-26.3980, lon: 153.0930},
    mooloolaba: {lat: -26.6820, lon: 153.1180},
    bribie: {lat: -26.9861, lon: 153.1325},
    suttons: {lat: -27.2360, lon: 153.1145},
    burleigh: {lat: -28.1040, lon: 153.4360},
    coolangatta: {lat: -28.1667, lon: 153.5333},
    byron: {lat: -28.6474, lon: 153.6020},
    ballina: {lat: -28.8380, lon: 153.5629},
    evans_head: {lat: -29.1086, lon: 153.4217},
    palmer_island: {lat: -29.4332, lon: 153.3406}
}
options = { units: "metric", APPID: "c60d3ad619a65ce0a4f912801a20afaf" }
descriptions = ["clear sky", "few clouds", "scattered clouds", "broken clouds", "shower rain", "rain", "thunderstorm", "snow", "mist"]

beaches = ["Tewantin QLD", "Mooloolaba QLD", "Donnybrook QLD", "Margate QLD", "Burleigh Heads QLD", "Bilinga QLD", "Byron Bay NSW", "Ballina NSW", "Evans Head NSW", "Palmer Island NSW"]
data_batch = []
formatted_data = {}
distances = []
others = []
spots = {}
spots_distances = []
beach_locations = []
surf_hash = {}
surf_results = []
surf_wind_max = 7
surf_swell_min = 0.5
kite_results = []
kite_hash = {}
kite_wind_min = 14
kite_wind_max = 36
kite_swell_max = 2.5
beachday_hash = {}
beachday_results = []
beachday_temp_min = 24
beachday_cloud_max = 80
beachday_wind_max = 15
wind_spd_kts = 1.94
name_count = 0
activity = nil

# Surf  method
def surf(surf_hash, beaches, formatted_data, descriptions, surf_results, surf_swell_min, surf_wind_max)
    beaches.each do |beach|
        if formatted_data[beach][:swell_height] > surf_swell_min && formatted_data[beach][:wind_spd_kts] < surf_wind_max && (formatted_data[beach][:description] == descriptions[0] || formatted_data[beach][:description] == descriptions[1] || formatted_data[beach][:description] == descriptions[2] || formatted_data[beach][:description] == descriptions[3] || formatted_data[beach][:description] == descriptions[4] || formatted_data[beach][:description] == descriptions[5])
            surf_results.push("Y")
        else
            surf_results.push("N")
        end
    end
end
# Kitesurf method
def kite(kite_hash, beaches, formatted_data, descriptions, kite_results, kite_swell_max, kite_wind_max, kite_wind_min)
    beaches.each do |beach|
        if formatted_data[beach][:swell_height] < kite_swell_max && formatted_data[beach][:wind_spd_kts] < kite_wind_max && formatted_data[beach][:wind_spd_kts] > kite_wind_min && (formatted_data[beach][:description] == descriptions[0] || formatted_data[beach][:description] == descriptions[1] || formatted_data[beach][:description] == descriptions[2] || formatted_data[beach][:description] == descriptions[3] || formatted_data[beach][:description] == descriptions[4])
            kite_results.push("Y")
        else
            kite_results.push("N")
        end
    end
end
# Beachday method
def beachday(beachday_hash, beaches, formatted_data, descriptions, beachday_results, beachday_cloud_max, beachday_temp_min, beachday_wind_max)
    beaches.each do |beach|
        if formatted_data[beach][:temp_max] > beachday_temp_min && formatted_data[beach][:cloud_coverage] < beachday_cloud_max && formatted_data[beach][:wind_spd_kts] < beachday_wind_max && (formatted_data[beach][:description] == descriptions[0] || formatted_data[beach][:description] == descriptions[1] || formatted_data[beach][:description] == descriptions[2] || formatted_data[beach][:description] == descriptions[3])
            beachday_results.push("Y")
        else
            beachday_results.push("N")
        end
    end
end
# Push api data to data_batch
beaches_coords.each do |key, value|
    data_batch.push(OpenWeather::Current.geocode(value[:lat], value[:lon], options))
end
# Format relevant data from data_batch into formatted_data
data_batch.each do |hash|
    swell_height = rand(1..6)/2.0
    hash["name"] = beaches[name_count]
    formatted_data[hash["name"]] = {"description": hash["weather"][0]["description"], "wind_spd_kts": hash["wind"]["speed"]* 1.94, "cloud_coverage": hash["clouds"]["all"], "temp_max": hash["main"]["temp_max"], "swell_height": swell_height}
    name_count += 1
end
# Parse beach names through geokit
beaches.each do |beach|
    beach_locations.push(Geokit::Geocoders::GoogleGeocoder.geocode(beach))
end
# User input loop
puts "Choose an activity:"
loop do
    activity = gets.chomp.capitalize
    if activity != "Surf" && activity != "Kite" && activity != "Beachday"
        system "clear"
        puts "Sorry, we currently only support 3 activities."
        puts ""
        sleep 1
        puts "Please choose from the following:" 
        puts "Surf / Kite / Beachday"           
    else
        system "clear"
        break
    end
end
# Parse users location through geokit
puts "Where are you now? e.g. brisbane QLD"
user_loc = Geokit::Geocoders::GoogleGeocoder.geocode(gets.chomp.capitalize)
beach_locations.each do |beach_loc|
    distances.push(user_loc.distance_to(beach_loc))
end
# Run the surf method and output related data
if activity == "Surf"
    system "clear"
    surf(surf_hash, beaches, formatted_data, descriptions, surf_results, surf_swell_min, surf_wind_max)
    count = 0
    #
    surf_results.each do |result|
      surf_hash[beaches[count]] = {suitable: result, distance: "#{('%.2f' % distances[count])} km"}
      count += 1
    end
    #
    surf_hash.each do |key, value|
      if value[:suitable] == "Y"
        spots[key] = value[:distance].to_f
      end
    end
    #
    spots.each do |key, value|
      spots_distances.push(value.to_f)
    end
    #
    spots.each do |key, value|
      if spots_distances.sort[0] == value
        puts ""
        puts "The closest suitable surfing spot is #{key} - #{value.to_i} kms"
        puts ""
        puts "... and the other suitable options are:"
        puts ""
      else
        others.push("#{key} - #{value.to_i} kms")
      end
    end
    # No suitable locations
    if spots.length == 0
        puts "Sorry, there are currently no locations suitable for this activity"
    end
    puts others
    puts ""
    puts ""
# Run the Kite method and output related data
elsif activity == "Kite"
    system "clear"
  kite(kite_hash, beaches, formatted_data, descriptions, kite_results, kite_swell_max, kite_wind_max, kite_wind_min)
  count = 0
  # !!Same as surf!!
  kite_results.each do |result|
    kite_hash[beaches[count]] = {suitable: result, distance: "#{('%.2f' % distances[count])} km"}
    count += 1
  end
  # !!Same as surf!!
  kite_hash.each do |key, value|
    if value[:suitable] == "Y"
      spots[key] = value[:distance].to_f
    end
  end
  # !!Same as surf!!
  spots.each do |key, value|
    spots_distances.push(value.to_f)
  end
  # !!Same as surf!!
  spots.each do |key, value|
    if spots_distances.sort[0] == value
      puts ""
      puts "The closest suitable kitesurf spot is #{key} - #{value.to_i} kms"
      puts ""
      puts "... and the other suitable options are:"
      puts ""
    else
      others.push("#{key} - #{value.to_i} kms")
    end
  end
  # No suitable locations
    if spots.length == 0
    puts "Sorry, there are currently no locations suitable for this activity"
    end
  puts others
  puts ""
  puts ""
# Run the Beachday method and output relevant data
elsif activity == "Beachday"
    system "clear"
  beachday(beachday_hash, beaches, formatted_data, descriptions, beachday_results, beachday_cloud_max, beachday_temp_min, beachday_wind_max)
  count = 0
  # !!Same as surf!!
  beachday_results.each do |result|
    beachday_hash[beaches[count]] = {suitable: result, distance: "#{('%.2f' % distances[count])} km"}
    count += 1
  end
  # !!Same as surf!!
  beachday_hash.each do |key, value|
    if value[:suitable] == "Y"
      spots[key] = value[:distance].to_f
    end
  end
  # !!Same as surf!!
  spots.each do |key, value|
    spots_distances.push(value.to_f)
  end
  # !!Same as surf!!
  spots.each do |key, value|
    if spots_distances.sort[0] == value
      puts ""
      puts "The closest suitable family beach day spot is #{key} - #{value.to_i} kms"
      puts ""
      puts "... and the other suitable options are:"
      puts ""
    else
      others.push("#{key} - #{value.to_i} kms")
    end
  end
  # No suitable locations
  if spots.length == 0
    puts "Sorry, there are currently no locations suitable for this activity"
    end
  puts others
  puts ""
  puts ""
end

# WRITE A CLASS TO REDUCE REPETITION ???????
