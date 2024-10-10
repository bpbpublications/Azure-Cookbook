#!/bin/bash

url=$1 # URL from command line argument
duration=${2:-120} # duration from command line argument in seconds, default is 120

start_time=$(date +%s)
end_time=$((start_time + duration))

i=1
while [ $(date +%s) -lt $end_time ]
do
   curl -s GET $url | grep -A 1000 "<title>" | grep -B 1000 "</title>"
   sleep 0.25
   i=$((i+1))
done
