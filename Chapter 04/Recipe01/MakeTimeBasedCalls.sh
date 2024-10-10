#!/bin/bash

url=$1 # URL from command line argument
duration=${2:-60} # duration from command line argument in seconds, default is 60

start_time=$(date +%s)
end_time=$((start_time + duration))

i=1
while [ $(date +%s) -lt $end_time ]
do
   echo "Making call number $i to $url"
   http_status=$(curl -o /dev/null -s -w "%{http_code}\n" $url)
   echo "HTTP status code: $http_status"
   sleep 0.25
   i=$((i+1))
done
