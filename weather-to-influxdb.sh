#!/bin/bash
# weather-to-influxdb.sh
# mlfh
# 2020-09-08
# fetches current weather/aqi data from nws/airnow, parses, and sends to influxdb

# Check to see if ENV variables are set (running in docker container), and source
# config file if not (running as standalone script)
if [ -z $OPENWEATHERMAP_API_KEY ]
then
	. config
	echo "Sourcing variables from config file..."
else
	echo "Sourcing ENV variables from container..."
fi

# Loop fetch/parse/send/wait forever
while true
do
	# Fetch raw data from api.weather.gov and airnowapi.org
	echo "Fetching data from api.openweathermap.org..."
	OPENWEATHERMAP=$(curl --silent "https://api.openweathermap.org/data/2.5/weather?lat=$LATITUDE&lon=$LONGITUDE&units=$UNITS&appid=$OPENWEATHERMAP_API_KEY")
	echo "Fetching data from airnowapi.org..."
	AIRNOW=$(curl --silent "https://www.airnowapi.org/aq/observation/latLong/current/?format=application/json&latitude=$LATITUDE&longitude=$LONGITUDE&distance=50&API_KEY=$AIRNOW_API_KEY")

	# Parse Openweathermap data
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

	# Parse AQI data
	AQI_TYPES=($(echo $AIRNOW | jq -r '.[].ParameterName'))
	echo "AQI Types: ${AQI_TYPES[@]}"
	AQI_VALUES=($(echo $AIRNOW | jq -r '.[].AQI'))
	echo "AQI Values: ${AQI_VALUES[@]}"

	# declare empty string array to hold influxdb post data for aqi types/values, then populate
	AQI_DATA=()
	for (( i=0; i<${#AQI_TYPES[@]}; i++ ))
	do
		AQI_DATA+=("aqi,type=${AQI_TYPES[i]} value=${AQI_VALUES[i]}")
	done

	# Send values to InfluxDB
	echo "Sending values to InfluxDB..."
	curl -v --output /dev/null -i -XPOST "$INFLUXDB_ADDRESS/write?db=$INFLUXDB_DATABASE&u=$INFLUXDB_USER&p=$INFLUXDB_PASSWORD" --data-binary \
		"$(printf "%s\n" "${AQI_DATA[@]}")
		temp,type=observed value=$TEMP
		temp,type=feels_like value=$FEELS_LIKE
		pressure value=$PRESSURE
		humidity value=$HUMIDITY
		visibility value=$VISIBILITY
		wind,type=speed value=$WIND_SPEED
		wind,type=direction value=$WIND_DIR
		clouds value=$CLOUDS"

	# Repeat after interval (seconds)
	echo "Sleeping for $INTERVAL seconds..."
	sleep $INTERVAL
done