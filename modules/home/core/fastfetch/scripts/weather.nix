{
  pkgs,
  lib,
  ...
}:
let
  jq = lib.getExe pkgs.jq;
in
pkgs.writeScript "weather" ''
  #!/usr/bin/env zsh

  # INFO: Based on https://github.com/fcambus/ansiweather
  # Usage: ./weather "Richmond,US"

  if [ -z "$1" ]; then
      echo "Usage: ./weather <city>"
      exit 1
  fi

  # URL-encode spaces in city name
  CITY=$(echo "$1" | sed 's/ /%20/g')
  API_KEY="85a4e3c55b73909f42c6a23ec35b7147"

  if [ -z "$API_KEY" ]; then
      echo "Please set the environment variable API_KEY"
      exit 1
  fi

  WEATHER_API_URL="https://api.openweathermap.org/data/2.5/weather?q=$CITY&units=metric&appid=$API_KEY"

  # Fetch current weather data
  weather_data=$(curl -s "$WEATHER_API_URL")

  # Parse needed fields
  city_name=$(echo $weather_data | ${jq} -r '.name')
  temperature=$(echo $weather_data | ${jq} -r '.main.temp' | xargs printf "%.0f")
  humidity=$(echo $weather_data | ${jq} -r '.main.humidity')
  weather_main=$(echo $weather_data | ${jq} -r '.weather[0].main')
  lon=$(echo $weather_data | ${jq} -r '.coord.lon')
  lat=$(echo $weather_data | ${jq} -r '.coord.lat')

  # Fetch UVI data
  UVI_API_URL="https://api.openweathermap.org/data/2.5/uvi?lat=$lat&lon=$lon&appid=$API_KEY"
  uvi_data=$(curl -s "$UVI_API_URL")
  uvi=$(echo $uvi_data | ${jq} -r '.value')

  # Helper function for weather icon
  weather_icon() {
      case $1 in
          Clouds)
              echo "☁"
              ;;
          Clear)
              echo "☀"
              ;;
          Rain)
              echo "🌧"
              ;;
          Snow)
              echo "❄"
              ;;
          Thunderstorm)
              echo "⛈"
              ;;
          Drizzle)
              echo "🌦"
              ;;
          Mist|Haze|Fog|Smoke|Dust|Sand|Ash|Squall|Tornado)
              echo "🌫"
              ;;
          *)
              echo "🌈"
              ;;
      esac
  }

  icon=$(weather_icon "$weather_main")

  printf "%s %s°C ⸗  %s ⸗  %s%% (%s)\n" "$icon" "$temperature" "$uvi" "$humidity" "$city_name"
''
