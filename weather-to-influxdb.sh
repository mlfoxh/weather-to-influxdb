#!/bin/bash
# weather-to-influxdb.sh
# mlfh
# 2020-09-08
# fetches current weather/aqi data from nws/airnow, parses, and sends to influxdb

# check to see if ENV variables are set (running in docker container), and source
# config file if not (running as standalone script)
if [ -z $OPENWEATHERMAP_API_KEY ]
then
	. config
	echo "Sourcing variables from config file..."
else
	echo "Sourcing ENV variables from container..."
fi

# loop fetch/parse/send/wait forever
while true
do
	# log where data is being fetched for
	LOCATION="$LATITUDE\,$LONGITUDE"
	echo "Location: $LATITUDE, $LONGITUDE"

	# fetch, parse, and send weather data if weather is configured on
	if [ $WEATHER_ON != "false" ]
	then
		# fetch raw data from api.openweathermap.org
		echo "Fetching data from api.openweathermap.org..."
		OPENWEATHERMAP=$(curl --silent "https://api.openweathermap.org/data/2.5/weather?lat=$LATITUDE&lon=$LONGITUDE&units=$UNITS&appid=$OPENWEATHERMAP_API_KEY")

		# parse openweathermap data and print to stdout for logging
		TEMP=$(echo $OPENWEATHERMAP | jq '.main.temp')
		echo "Temperature: $TEMP"
		FEELS_LIKE=$(echo $OPENWEATHERMAP | jq '.main.feels_like')
		echo "Feels Like: $FEELS_LIKE"
		PRESSURE=$(echo $OPENWEATHERMAP | jq '.main.pressure')
		echo "Pressure: $PRESSURE"
		HUMIDITY=$(echo $OPENWEATHERMAP | jq '.main.humidity')
		echo "Humidity: $HUMIDITY"
		VISIBILITY=$(echo $OPENWEATHERMAP | jq '.visibility')
		echo "Visibility: $VISIBILITY"
		WIND_SPEED=$(echo $OPENWEATHERMAP | jq '.wind.speed')
		echo "Wind Speed: $WIND_SPEED"
		WIND_DIR=$(echo $OPENWEATHERMAP | jq '.wind.deg')
		echo "Wind Direction: $WIND_DIR"
		CLOUDS=$(echo $OPENWEATHERMAP | jq '.clouds.all')
		echo "Cloud Cover: $CLOUDS"
		RAIN=$(echo $OPENWEATHERMAP | jq '.rain["1h"] // 0') # returns 0 if null
		echo "Rain (last hour): $RAIN"
		SNOW=$(echo $OPENWEATHERMAP | jq '.snow["1h"] // 0') # returns 0 if null
		echo "Snow (last hour): $SNOW"
		# send values to influxdb
		echo "Sending weather values to InfluxDB..."
		curl -v --output /dev/null -i -XPOST "$INFLUXDB_ADDRESS/write?db=$INFLUXDB_DATABASE&u=$INFLUXDB_USER&p=$INFLUXDB_PASSWORD" --data-binary \
			"temp,location=$LOCATION,location_name=$LOCATION_NAME value=$TEMP
			temp_feels_like,location=$LOCATION,location_name=$LOCATION_NAME value=$FEELS_LIKE
			pressure,location=$LOCATION,location_name=$LOCATION_NAME value=$PRESSURE
			humidity,location=$LOCATION,location_name=$LOCATION_NAME value=$HUMIDITY
			visibility,location=$LOCATION,location_name=$LOCATION_NAME value=$VISIBILITY
			wind_speed,location=$LOCATION,location_name=$LOCATION_NAME value=$WIND_SPEED
			wind_direction,location=$LOCATION,location_name=$LOCATION_NAME value=$WIND_DIR
			clouds,location=$LOCATION,location_name=$LOCATION_NAME value=$CLOUDS
			rain,location=$LOCATION,location_name=$LOCATION_NAME value=$RAIN
			snow,location=$LOCATION,location_name=$LOCATION_NAME value=$SNOW"
	fi

	# fetch, parse, and send aqi data if aqi is configured on
	if [ $AQI_ON != "false" ]
	then
		# fetch raw data from airnowapi.org
		echo "Fetching data from airnowapi.org..."
		AIRNOW=$(curl --silent "https://www.airnowapi.org/aq/observation/latLong/current/?format=application/json&latitude=$LATITUDE&longitude=$LONGITUDE&distance=50&API_KEY=$AIRNOW_API_KEY")

		# parse aqi data
		AQI_TYPES=($(echo $AIRNOW | jq -r '.[].ParameterName'))
		echo "AQI Types: ${AQI_TYPES[@]}"
		AQI_VALUES=($(echo $AIRNOW | jq -r '.[].AQI'))
		echo "AQI Values: ${AQI_VALUES[@]}"
		# declare empty string array to hold influxdb post data for aqi types/values, then populate
		AQI_DATA=()
		for (( i=0; i<${#AQI_TYPES[@]}; i++ ))
		do
			AQI_DATA+=("aqi,type=${AQI_TYPES[i]},location=$LOCATION,location_name=$LOCATION_NAME value=${AQI_VALUES[i]}")
		done
		# send values to influxdb
		echo "Sending AQI values to InfluxDB..."
		curl -v --output /dev/null -i -XPOST "$INFLUXDB_ADDRESS/write?db=$INFLUXDB_DATABASE&u=$INFLUXDB_USER&p=$INFLUXDB_PASSWORD" --data-binary \
			"$(printf "%s\n" "${AQI_DATA[@]}")"
	fi

	# repeat after interval (seconds)
	echo "Sleeping for $INTERVAL seconds..."
	sleep $INTERVAL
done
