#!/bin/bash

from=$1
to=$2
number=$3

data=`cat request_template.xml | sed "s/%from%/${from}/" | sed "s/%to%/${to}/" | sed "s/%number%/${number}/"`
curl -s --header "Content-Type: text/xml;charset=UTF-8" --data "$data" https://lite.realtime.nationalrail.co.uk/OpenLDBWS/ldb9.asmx
