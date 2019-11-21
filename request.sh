#!/bin/bash

from=$1
to=$2
number=$3

path=`dirname $0`

data=`cat ${path}/request_template.xml | sed "s/%from%/${from}/" | sed "s/%to%/${to}/" | sed "s/%number%/${number}/"`
curl -s --header "Content-Type: text/xml;charset=UTF-8" --data "$data" https://lite.realtime.nationalrail.co.uk/OpenLDBWS/ldb9.asmx
