#!/bin/sh

#COMMAND=`curl -X 'POST' -v http://10.120.41.31:5000/v2.0/tokens -d '{"auth":{"passwordCredentials":{"username": "admin", "password":"admin"}, "tenantName":"admin"}}' -H 'Content-type: application/json' | python -mjson.tool | grep "token" -A 2 | sed -n 3p | cut -d'"' -f4`

token=`keystone token-get |grep id |grep -v _id | awk '{print $4}'`

tenant=`keystone token-get |grep tenant_id| awk '{print $4}'`

echo $token
#echo $tenant

#echo $COMMAND
