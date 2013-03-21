#!/bin/sh

#COMMAND=`curl -X 'POST' -v http://10.120.41.31:5000/v2.0/tokens -d '{"auth":{"passwordCredentials":{"username": "admin", "password":"admin"}, "tenantName":"admin"}}' -H 'Content-type: application/json' | python -mjson.tool | grep "token" -A 2 | sed -n 3p | cut -d'"' -f4`
COMMAND=`curl -X 'POST' -v http://10.120.41.31:5000/v2.0/tokens -d '{"auth":{"passwordCredentials":{"username": "admin", "password":"admin"}, "tenantName":"admin"}}' -H 'Content-type: application/json'`

t=$COMMAND
echo ======
echo $t

echo =======
d=`echo $t | python -mjson.tool | grep "token" -A 2 | sed -n 3p | cut -d'"'-f4`
echo $d

#echo $COMMAND
