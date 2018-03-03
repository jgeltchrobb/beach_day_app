require 'open_weather'
require 'geokit'

Geokit::default_units = :kms
Geokit::Geocoders::request_timeout = 3
Geokit::Geocoders::GoogleGeocoder.api_key = 'AIzaSyAukwxtdEcmLeSsBTCTbeG-ODyz6rC5sZM' 


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
options = { units: "metric", APPID: "0d9a30cbcb91b1b90fcf974a61b6ee2f" }
descriptions = ["clear sky", "few clouds", "scattered clouds", "broken clouds", "overcast clouds", "light rain", "shower rain", "rain", "thunderstorm", "snow", "mist"]

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
kite_wind_min = 12
kite_wind_max = 36
kite_swell_max = 3
beachday_hash = {}
beachday_results = []
beachday_temp_min = 24
beachday_cloud_max = 75
beachday_wind_max = 15
wind_spd_kts = 1.94
name_count = 0
activity = nil

# Surf  method
def surf(surf_hash, beaches, formatted_data, descriptions, surf_results, surf_swell_min, surf_wind_max)
    beaches.each do |beach|
        if formatted_data[beach][:swell_height] > surf_swell_min && formatted_data[beach][:wind_spd_kts] < surf_wind_max && (formatted_data[beach][:description] == descriptions[0] || formatted_data[beach][:description] == descriptions[1] || formatted_data[beach][:description] == descriptions[2] || formatted_data[beach][:description] == descriptions[3] || formatted_data[beach][:description] == descriptions[4] || formatted_data[beach][:description] == descriptions[5] || formatted_data[beach][:description] == descriptions[6])
            surf_results.push("Y")
        else
            surf_results.push("N")
        end
    end
end
# Kitesurf method
def kite(kite_hash, beaches, formatted_data, descriptions, kite_results, kite_swell_max, kite_wind_max, kite_wind_min)
    beaches.each do |beach|
        if formatted_data[beach][:swell_height] < kite_swell_max && formatted_data[beach][:wind_spd_kts] < kite_wind_max && formatted_data[beach][:wind_spd_kts] > kite_wind_min && (formatted_data[beach][:description] == descriptions[0] || formatted_data[beach][:description] == descriptions[1] || formatted_data[beach][:description] == descriptions[2] || formatted_data[beach][:description] == descriptions[3] || formatted_data[beach][:description] == descriptions[4] || formatted_data[beach][:description] == descriptions[5] || formatted_data[beach][:description] == descriptions[6])
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
# Format and push relevant data from data_batch into formatted_data
# Add swell height and convert wind to knots
data_batch.each do |hash|
    swell_height = rand(1..6)/2.0
    hash["name"] = beaches[name_count]
    formatted_data[hash["name"]] = {"description": hash["weather"][0]["description"], "wind_spd_kts": hash["wind"]["speed"]* wind_spd_kts, "cloud_coverage": hash["clouds"]["all"], "temp_max": hash["main"]["temp_max"], "swell_height": swell_height}
    name_count += 1
end
# Parse beach names through geokit to generate beach_locations
beaches.each do |beach|
    beach_locations.push(Geokit::Geocoders::GoogleGeocoder.geocode(beach))
end
# User input loop to finalise input
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
user_loc = ""
user_coords = ""
# Parse users location through geokit to generate distances array
puts "Where are you now? e.g. brisbane QLD"
loop do
  user_loc = Geokit::Geocoders::GoogleGeocoder.geocode(gets.chomp.capitalize)
  user_coords = user_loc.ll
  if user_coords =~ /\d/         # Calling String's =~ method.
    # puts "The String #{user_coords} has a number in it."
    break
  else
    # puts "The String #{user_coords} does not have a number in it."
    puts "Please enter a valid location"
  end
end
beach_locations.each do |beach_loc|
    distances.push(user_loc.distance_to(beach_loc))
end
# Run the surf method to determine results and return final outputs
if activity == "Surf"
    system "clear"
    surf(surf_hash, beaches, formatted_data, descriptions, surf_results, surf_swell_min, surf_wind_max)
    count = 0
    # Generate surf_hash relating all locations to their respective result ("Y" or "N") and distance from user
    surf_results.each do |result|
      surf_hash[beaches[count]] = {suitable: result, distance: "#{('%.2f' % distances[count])} km"}
      count += 1
    end
    # Generate spots hash with only suitable places (aka 'spots') and their distance from user
    surf_hash.each do |key, value|
      if value[:suitable] == "Y"
        spots[key] = value[:distance].to_f
      end
    end
    # Generate spots_distances array with distance to user for each 'spot' (suitable place)
    spots.each do |key, value|
      spots_distances.push(value.to_f)
    end
    # Sort spots_distances array and compare smallest distance to distances stored in spots hash to determine corresponding location name.
    # Output closest location name and then all other 'spots' (suitable locations)
    spots.each do |key, value|
      if spots_distances.sort[0] == value
        puts ""
        puts "The closest suitable surfing spot is #{key} - #{value.to_i} kms"
        puts ""
        if spots_distances.length != 1
          puts "... and the other suitable options are:"
          puts ""
        end
      else
        others.push("#{key} - #{value.to_i} kms")
      end
      # if others.length == 0
      # end
    end
    # If there are no suitable locations - Outpout
    if spots.length == 0
        puts "Sorry, there are currently no locations suitable for this activity"
        puts "Try again later"
    end
    puts others
    puts ""
    puts ""
# Run the Kite method to determine results and return final outputs
elsif activity == "Kite"
    system "clear"
  kite(kite_hash, beaches, formatted_data, descriptions, kite_results, kite_swell_max, kite_wind_max, kite_wind_min)
  count = 0
  # Generate surf_hash relating all locations to their respective result ("Y" or "N") and distance from user
  kite_results.each do |result|
    kite_hash[beaches[count]] = {suitable: result, distance: "#{('%.2f' % distances[count])} km"}
    count += 1
  end
  # Generate spots hash with only suitable places (aka 'spots') and their distance from user
  kite_hash.each do |key, value|
    if value[:suitable] == "Y"
      spots[key] = value[:distance].to_f
    end
  end
  # Generate spots_distances array with distance to user for each 'spot' (suitable place)
  spots.each do |key, value|
    spots_distances.push(value.to_f)
  end
  # Sort spots_distances array and compare smallest distance to distances stored in spots hash to determine corresponding location name.
  # Output closest location name and then all other 'spots' (suitable locations)
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
    # If there are no suitable locations - Outpout
    if spots.length == 0
    puts "Sorry, there are currently no locations suitable for this activity"
    puts "Try again later"
    end
  puts others
  puts ""
  puts ""
# Run the Beachday method to determine results and return final outputs
elsif activity == "Beachday"
    system "clear"
  beachday(beachday_hash, beaches, formatted_data, descriptions, beachday_results, beachday_cloud_max, beachday_temp_min, beachday_wind_max)
  count = 0
  # Generate surf_hash relating all locations to their respective result ("Y" or "N") and distance from user
  beachday_results.each do |result|
    beachday_hash[beaches[count]] = {suitable: result, distance: "#{('%.2f' % distances[count])} km"}
    count += 1
  end
  # Generate spots hash with only suitable places (aka 'spots') and their distance from user
  beachday_hash.each do |key, value|
    if value[:suitable] == "Y"
      spots[key] = value[:distance].to_f
    end
  end
  # Generate spots_distances array with distance to user for each 'spot' (suitable place)
  spots.each do |key, value|
    spots_distances.push(value.to_f)
  end
  # Sort spots_distances array and compare smallest distance to distances stored in spots hash to determine corresponding location name.
  # Output closest location name and then all other 'spots' (suitable locations)
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
  # If there are no suitable locations - Outpout
  if spots.length == 0
    puts "Sorry, there are currently no locations suitable for this activity"
    puts "Try again later"
    end
  puts others
  puts ""
  puts ""
end
