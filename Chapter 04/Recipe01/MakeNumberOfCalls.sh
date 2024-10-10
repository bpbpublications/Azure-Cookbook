#!/bin/bash

url=$1 # URL from command line argument
num_calls=${2:-100} # number of calls from command line argument, default is 100

for i in $(seq 1 $num_calls)
do
    echo "Making call number $i to $url"
    http_status=$(curl -o /dev/null -s -w "%{http_code}\n" $url)
    echo "HTTP status code: $http_status"
    sleep 0.25
done
