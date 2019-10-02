#!/bin/bash

community=$2
ip=$1

usedm=$(snmpget -v 2c -c "$community" $ip .1.3.6.1.2.1.25.2.3.1.6.65536 |awk '{print $4}')
totalm=$(snmpget -v 2c -c "$community" $ip .1.3.6.1.2.1.25.2.3.1.5.65536 |awk '{print $4}')

usage=$((($usedm*100)/$totalm))

warning=$3
critical=$4

if [ $usage -lt $warning ] ; then
	echo "OK - $usage%"
	exit 0

elif [ $usage -ge $warning ] ; then
	if [ $usage -lt $critical ] ; then
  		echo "WARNING - *$usage%*"
		exit 1
	else
		echo "CRITICAL - *$usage%*"
		exit 2
	fi
else
  	echo "UNKNOWN"
	exit 3 
fi

