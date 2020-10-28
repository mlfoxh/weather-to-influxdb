# weather-to-influxdb
Bash script which curls and parses openweathermap and airnow data for specified
latitude/longitude coordinates, and sends to InfluxDB.

Can be run as standalone script; also includes Dockerfile to use in Docker container.

## InfluxDB Schema:
All measurements have a location tag, so that a single database can be used for multiple
locations by running multiple instances of this script with different lat/long options.

## Requirements:
* [openweathermap.org API Key](https://openweathermap.org/appid)
* [airnowapi.org API Key](https://docs.airnowapi.org/account/request/)

#### If running as standalone script, the following packages are required:
* bash
* curl
* jq

## Configuration:
Configuration options are sourced from the config file if running as standalone, or
from ENV variables if running in a Docker container.
#### If running as Docker container:
Set the following ENV variables eiter at runtime or in Dockerfile:
* LATITUDE="0.00"
* LONGITUDE="0.00"
* UNITS="metric" or "imperial" (sets temperature units)
* OPENWEATHERMAP_API_KEY="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
* AIRNOW_API_KEY="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx"
* INFLUXDB_ADDRESS="http://influxdb.domain.tld:8086"
* INFLUXDB_DATABASE="database"
* INFLUXDB_USER="user"
* INFLUXDB_PASSWORD="password"
* INTERVAL="900" (how long the script waits before running again)

#### If running as standalone script:
* Edit the config file to set all options, same as above.
