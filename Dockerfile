FROM alpine:latest

COPY weather-to-influxdb.sh /root/weather-to-influxdb.sh

RUN apk update && apk add \
    bash \
    curl \
    jq

ENV LATITUDE=0.00
ENV LONGITUDE=0.00
ENV OPENWEATHERMAP_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
ENV AIRNOW_API_KEY=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx
ENV INFLUXDB_ADDRESS=http://influxdb.domain.tld:8086
ENV INFLUXDB_DATABASE=database
ENV INFLUXDB_USER=user
ENV INFLUXDB_PASSWORD=password
ENV INTERVAL=900

ENTRYPOINT ["/bin/bash"]

CMD ["/root/weather-to-influxdb.sh"]
