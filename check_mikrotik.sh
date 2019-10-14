#!/bin/bash

function usage {
	echo "USAGE"
	exit 3
}

function cpuavgusage {

	local cores=$(snmpwalk $scommand .1.3.6.1.2.1.25.3.3.1.2 | wc -l)
	local cnt=1
	local avg=0
	while [ $cnt -lt $(($cores+1)) ]; do
		
		local core=$(snmpget $scommand .1.3.6.1.2.1.25.3.3.1.2.$cnt | awk '{print $4}')
		local avg=$(($avg+$core))
		((cnt++))
	done

	local cpuavg=$(($avg/$cores))
	
	if [ $cpuavg -lt $warning ]; then
		echo "CPU_load AVG for $cores core(s): $(($avg/$cores))%"
		exit 0
	elif [ $cpuavg -lt $critical ]; then
		echo "*WARNING* CPU_load AVG for $cores core(s): $(($avg/$cores))%"
		exit 1
	else
		echo "***CRITICAL*** CPU_load AVG for $cores core(s): $(($avg/$cores))%"
		exit 2
	fi

}

function systemperature {
	
	local version=$(snmpget $scommand .1.3.6.1.2.1.47.1.1.1.1.2.65536 | awk {'print $5'} |sed 's/[[:digit:]]\.\([[:digit:]][[:digit:]]\)\.[[:digit:]]*/\1/')
	
	if [ $version -gt 42 ]; then
		local temperature=$(($(snmpget $scommand .1.3.6.1.4.1.14988.1.1.3.10.0 | awk '{print $4}')/10))
	else
		local temperature=$(($(snmpget $scommand .1.3.6.1.4.1.14988.1.1.3.11.0 | awk '{print $4}')/10))
	fi

	
	if [ $temperature -lt $warning ]; then
		echo "Temperature is ${temperature}'C"
		exit 0
	elif [ $temperature -lt $critical ]; then
		echo "*WARNING* Temperature is ${temperature}'C"
		exit 1
	else 
		echo "***CRITICAL*** Temperature is ${temperature}'C"
		exit 2
	fi

}

function sysmemory {

	local totalmemory=$(snmpget $scommand .1.3.6.1.2.1.25.2.3.1.5.65536 | awk '{print $4}')
	local usedmemory=$(snmpget $scommand .1.3.6.1.2.1.25.2.3.1.6.65536 | awk '{print $4}')
	local percusage=$(($usedmemory*100/$totalmemory))
	
	if [ $percusage -lt $warning ]; then
		echo "Memory usage: ${percusage}%"
		exit 0
	elif [ $percusage -lt $critical ]; then
		echo "*WARNING* Memory usage: ${percusage}%"
		exit 1
	else
		echo "***CRITICAL*** Memory usage: ${percusage}%"
		exit 2
	fi

}

function sysuptime {

	local hour=3600
	local day=86400
	local minute=60
	local uptime=$(($(snmpget $scommand .1.3.6.1.2.1.1.3.0 | awk {'print $4'} | sed 's/(\([[:digit:]]*\))/\1/')/100))
	
	local D=$(($uptime/$day))
  	local H=$(($uptime/$hour%24))
  	local M=$(($uptime/$minute%60))
  	local S=$(($uptime%60))
	
	if [ $uptime -ge $day ]; then
		echo "Uptime: ${D}days ${H}hour's ${M}minutes ${S}seconds" 
		exit 0
	elif [ $uptime -ge $hour ]; then
		echo "*WARNING* Uptime: ${H}hour's ${M}minutes ${S}seconds"
		exit 1
	else
		echo "***CRITICAL*** Uptime: ${M}minutes ${S}seconds"
		exit 2
	fi
}

ip="127.0.0.1"
community="default"
task="cpuusage"
warning=40
critical=80


if [ $# -eq 0 ]; then
	usage;
fi

while getopts ':hH:C:t:w:c:u:' opt
do
	case $opt in

		h )
			usage
			;;
		H )
			ip=$OPTARG
			;;
		C )
			community=$OPTARG
			;;

		t )
			task=$OPTARG
			;;

		w )
			warning=$OPTARG
			;;

		c )
			critical=$OPTARG
			;;

		i )
			interface=$OPTARG
			;;
		u )
			units=$OPTARG
			;;
			
		\? )
			echo "Invalid option $OPTARG" 1>&2
			usage
			exit 3
			;;
		: )
			echo "Invalid Option: -$OPTARG requires an argument" 1>&2
			usage
			exit 3
			;;

	esac
done


scommand="-v 2c -c $community $ip"

case $task in

	cpuusage )
		cpuavgusage
		;;
	temp )
		systemperature
		;;
	memory )
		sysmemory
		;;
	uptime )
		sysuptime
		;;
esac
