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

wind_spd_kts = 1.94
beaches = ["Tewantin QLD", "Mooloolaba QLD", "Donnybrook QLD", "Margate QLD", "Burleigh Heads QLD", "Bilinga QLD", "Byron Bay NSW", "Ballina NSW", "Evans Head NSW", "Palmer Island NSW"]
data_batch = []
surf_results = []
surf_hash = {}
kite_results = []
beach_locations = []
distances = []
kite_hash = {}
beachday_results = []
beachday_hash = {}
formatted_data = {}
name_count = 0
surf_wind_max = 7
surf_swell_min = 0.5
kite_wind_min = 14
kite_wind_max = 36
kite_swell_max = 2.5
beachday_temp_min = 24
beachday_cloud_max = 50
beachday_wind_max = 15
    #surf
def surf(surf_hash, beaches, formatted_data, descriptions, surf_results, surf_swell_min, surf_wind_max)
    beaches.each do |beach|
        if formatted_data[beach][:swell_height] > surf_swell_min && formatted_data[beach][:wind_spd_kts] < surf_wind_max && formatted_data[beach][:description] == descriptions[0] || formatted_data[beach][:description] == descriptions[1] || formatted_data[beach][:description] == descriptions[2] || formatted_data[beach][:description] == descriptions[3] || formatted_data[beach][:description] == descriptions[4] || formatted_data[beach][:description] == descriptions[5]
            surf_results.push("Y")
        else
            surf_results.push("N")
        end
    end
end
      #kite
def kite(beaches, formatted_data, descriptions, kite_results, kite_swell_max, kite_wind_max, kite_wind_min)
    beaches.each do |beach|
        if formatted_data[beach][:swell_height] < kite_swell_max && formatted_data[beach][:wind_spd_kts] < kite_wind_max && formatted_data[beach][:wind_spd_kts] > kite_wind_min&& formatted_data[beach][:description] == descriptions[0] || formatted_data[beach][:description] == descriptions[1] || formatted_data[beach][:description] == descriptions[2] || formatted_data[beach][:description] == descriptions[3] || formatted_data[beach][:description] == descriptions[4]
            kite_results.push("Y")
        else
            kite_results.push("N")
        end
    end
end
      #beachday
def beachday(beaches, formatted_data, descriptions, beachday_results, beachday_cloud_max, beachday_temp_min, beachday_wind_max)
    beaches.each do |beach|
        if formatted_data[beach][:temp_max] > beachday_temp_min && formatted_data[beach][:cloud_coverage] < beachday_cloud_max && formatted_data[beach][:wind_spd_kts] < beachday_wind_max && formatted_data[beach][:description] == descriptions[0] || formatted_data[beach][:description] == descriptions[1] || formatted_data[beach][:description] == descriptions[2]
            beachday_results.push("Y")
        else
            beach_dayresults.push("N")
        end
    end
end

beaches_coords.each do |key, value|
    data_batch.push(OpenWeather::Current.geocode(value[:lat], value[:lon], options))
end

data_batch.each do |hash|
    swell_height = rand(1..6)/2.0
    hash["name"] = beaches[name_count]
    formatted_data[hash["name"]] = {"description": hash["weather"][0]["description"], "wind_spd_kts": hash["wind"]["speed"]* 1.94, "cloud_coverage": hash["clouds"]["all"], "temp_max": hash["main"]["temp_max"], "swell_height": swell_height}
    name_count += 1
end
beaches.each do |beach|
    beach_locations.push(Geokit::Geocoders::GoogleGeocoder.geocode(beach))
end
puts "Choose an activity"
puts "Surf / Kite / Beachday"
activity = gets.chomp.capitalize
puts "Where are you now, e.g. brisbane QLD"
user_loc = Geokit::Geocoders::GoogleGeocoder.geocode(gets.chomp.capitalize)
beach_locations.each do |beach_loc|
    distances.push(user_loc.distance_to(beach_loc))
end
if activity == "Surf"
    surf(surf_hash, beaches, formatted_data, descriptions, surf_results, surf_swell_min, surf_wind_max)
    count = 0
    surf_hash = {}
    surf_results.each do |result|
      surf_hash[beaches[count]] = {suitable: result, distance: "#{('%.2f' % distances[count])} km"}
      count += 1
    end
    spots = {}
    surf_hash.each do |key, value|
      if value[:suitable] == "Y"
        spots[key] = value[:distance]
      end
    end
    puts spots


elsif activity == "Kite"
  kite(kite_hash, beaches, formatted_data, descriptions, surf_results, surf_swell_min, surf_wind_max)
  count = 0
  kite_hash = {}
  kite_results.each do |result|
    kite_hash[beaches[count]] = {suitable: result, distance: "#{('%.2f' % distances[count])} km"}
    count += 1
  end
  spots = {}
  kite_hash.each do |key, value|
    if value[:suitable] == "Y"
      spots[key] = value[:distance]
    end
  end
  puts spots
elsif activity == "Beachday"
  beachday(beachday_hash, beaches, formatted_data, descriptions, surf_results, surf_swell_min, surf_wind_max)
  count = 0
  beachday_hash = {}
  beachday_results.each do |result|
    beachday_hash[beaches[count]] = {suitable: result, distance: "#{('%.2f' % distances[count])} km"}
    count += 1
  end
  spots = {}
  beachday_hash.each do |key, value|
    if value[:suitable] == "Y"
      spots[key] = value[:distance]
    end
  end
  puts spots
end

# WRITE A CLASS TO REDUCE REPETITION ???????

# NOW I WILL, FOR EACH ONE, GET TO ANOTHER HASH FOR SUITABLE VALUES (Y)
# = {TEWANTIN: __KM, MOOLOOLABA: __KM, ETC...}
# THEN WE WILL NEED A METHOD TO SORT AND CHOOSE THE SHORTEST DISTANCE
