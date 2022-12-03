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

# GETTING KEY AND URL INFO
# KEYS/URL available:
# davis:[{key,secret}]
# kigprod:[{key,url}]
# kigdev:[{key,url}]
# dots:[{key,url}]

# KEY & URL FOR KIG/KIG-DEV/DOTs
kigKey=`cat $apisInfo | jq 'select(.kigdev) | .kigdev[] | .key'`
kigKey=`echo $kigKey | sed 's/^.//;s/.$//'`
kigUrl=`cat $apisInfo | jq 'select(.kigdev) | .kigdev[] | .url'`
kigUrl=`echo $kigUrl | sed 's/^.//;s/.$//'`

function sensorLoc()
{
        while read line;
        do
                if [[ $line =~ "lat" ]]; then
                        lat=`echo $line | awk '{print $2}'`
                elif [[ $line =~ "long" ]]; then
                        long=`echo $line | awk  '{print $2}'`
                elif [[ $line =~ "alt" ]]; then
                        alt=`echo $line | awk '{print $2}'`
                fi
        done < ${rootDir}ID.WhoAmI
        locDes="JOHNSTON"
        siteloc="jh-iowa"
        gatewaymac=`/sbin/ifconfig wlan0 | grep ether | awk '{print $2}'`
        device="${gatewaymac//:}-$siteloc-$sensor_type"
        sensorData
}

function sensorData()
{
	mate3sData=$(curl 'http://192.168.1.134/Dev_status.cgi?Port=0')
	if [ -z "$mate3sData" ]
	then
		echo "`date +%Y-%m-%dT%T` --- Communication error, please check MATE3S unit" >> ${logsDir}comm_error.log
		exit 0
	else
		pTime=`echo $mate3sData | jq '.[]' | grep Sys_Time | awk '{print $2}'`
		pTime=${pTime::-1}
		pTime=`echo "scale=3 ; $pTime + 28800" | bc`
		eTime=`echo "@$pTime"`
		sTime=`date -d "$eTime" -u +%Y-%m-%dT%T`

		invBattV=`echo $mate3sData | jq '.[] | .ports[] | select(.Port==1) | .Batt_V'`
		invVACout=`echo $mate3sData | jq '.[] | .ports[] | select(.Port==1) | .VAC_out'`


		ccBattV=`echo $mate3sData | jq '.[] | .ports[] | select(.Port==2) | .Batt_V'`
		ccInV=`echo $mate3sData | jq '.[] | .ports[] | select(.Port==2) | .In_V'`
		cckWhout=`echo $mate3sData | jq '.[] | .ports[] | select(.Port==2) | .Out_kWh'`
		ccAHout=`echo $mate3sData | jq '.[] | .ports[] | select(.Port==2) | .Out_AH'`

		fndcShuntB=`echo $mate3sData | jq '.[] | .ports[] | select(.Port==3) | .Shunt_B_I'`
		fndcSOC=`echo $mate3sData | jq '.[] | .ports[] | select(.Port==3) | .SOC'`
		fndcMinSOC=`echo $mate3sData | jq '.[] | .ports[] | select(.Port==3) | .Min_SOC'`
		fndcDaysSFull=`echo $mate3sData | jq '.[] | .ports[] | select(.Port==3) | .Days_since_full'`
		fndcInAHToday=`echo $mate3sData | jq '.[] | .ports[] | select(.Port==3) | .In_AH_today'`
		fndcOutAHToday=`echo $mate3sData | jq '.[] | .ports[] | select(.Port==3) | .Out_AH_today'`
		fndcInkWhToday=`echo $mate3sData | jq '.[] | .ports[] | select(.Port==3) | .In_kWh_today'`
		fndcOutkWhToday=`echo $mate3sData | jq '.[] | .ports[] | select(.Port==3) | .Out_kWh_today'`
		fndcBattV=`echo $mate3sData | jq '.[] | .ports[] | select(.Port==3) | .Batt_V'`
		fndcBattTc=`echo $mate3sData | jq '.[] | .ports[] | select(.Port==3) | .Batt_temp'`
		fndcBattTc=`echo $fndcBattTc | sed 's/^.//;s/.$//'`
		fndcBattTc=${fndcBattTc::-2}
		fndcBattTf=`echo "scale=3 ; $fndcBattTc * 1.80 + 32.00" | bc`

		panelEnergy=`echo "scale=3 ; $ccBattV * $fndcShuntB" | bc`

		payload="\\\"Inv Battery Volt(vdc)\\\":\\\"$invBattV\\\",\\\"Inv VAC Out(vac)\\\":\\\"$invVACout\\\",\\\"CC Battery Volt(vdc)\\\":\\\"$ccBattV\\\",\\\"CC In Volts(vdc)\\\":\\\"$ccInV\\\",\\\"CC kWh Out(kWh)\\\":\\\"$cckWhout\\\",\\\"CC Out AH\\\":\\\"$ccAHout\\\",\\\"FNDC Shunt B Input(AH)\\\":\\\"$fndcShuntB\\\",\\\"FNDC SOC(%)\\\":\\\"$fndcSOC\\\",\\\"FNDC Min SOC(%)\\\":\\\"$fndcMinSOC\\\",\\\"FNDC Days Since Full(days)\\\":\\\"$fndcDaysSFull\\\",\\\"FNDC In AH Today(AH)\\\":\\\"$fndcInAHToday\\\",\\\"FNDC Out AH Today(AH)\\\":\\\"$fndcOutAHToday\\\",\\\"FNDC In kWh Today(kWh)\\\":\\\"$fndcInkWhToday\\\",\\\"FNDC Out kWh Today(kWh)\\\":\\\"$fndcOutkWhToday\\\",\\\"FNDC Battery Volt(vdc)\\\":\\\"$fndcBattV\\\",\\\"FNDC Battery Temp(F)\\\":\\\"$fndcBattTf\\\",\\\"Panel Energy(Watts)\\\":\\\"$panelEnergy\\\",\\\"GpsLong\\\":\\\"$long\\\",\\\"GpsLat\\\":\\\"$lat\\\",\\\"GpsAlt\\\":\\\"0\\\",\\\"LocationDescription\\\":\\\"SolarSystem\\\""

		ingestData
	fi
}

function ingestData()
{
	body="\"UUID\": \"$device\", \"PayLoad\": \"{$payload}\", \"CreatedDate\": \"$sTime\", \"Tag\": \"$sensor_type\""
	echo $body
	cmdout=`curl --max-time 20 -i -X POST -H "Content-Type:application/json" -H "x-functions-key:$kigKey" $kigUrl/api/SensorReading/IngestData -d "{$body}"`
	if [ -z "`echo $cmdout | grep 'success'`" ]; then
		echo -e $body >> /home/pi/kigs/logs/bufferedSensorData.txt
	fi
}

sensorLoc

exit 0

