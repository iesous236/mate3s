#!/bin/bash

# Date: December 2022
# Description: Script to ingest data from MATE3S into DoTs

# FILES LOCATION
rootDir="/home/pi/kigs/"
apisInfo="/home/pi/kigs/apisInfo.json"
logsDir="/home/pi/kigs/logs/mate3s/"
sensorDir="/home/pi/kigs/scripts/sensor/mate3s/"
sensor_type="mate3s"

# CHECKING IF LOG DIRECTORY EXISTS
if [ ! -d $logsDir ]; then
         mkdir $logsDir
fi

# GET APIS INFO
if [ ! -f $apisInfo ]; then
        echo "`date +%Y-%m-%dT%T` $apisInfo does not exist. You need to create the file to get API info" >> ${logsDir}apisInfo_error.log
        exit 0
fi

exit 0
