#!/bin/bash
#URLL+tenantID
URL='http://localhost:8774/v2/'
#TOKEN=`/home/openstack/script/getToken.sh`
TOKEN=`keystone token-get |grep id |grep -v _id | awk '{print $4}'`
XTOKEN='x-auth-token:'$TOKEN
MODEL='POST'
REQUEST=''

#curl -H $XTOKEN -X $MODEL -v $URL/servers/detail  | python -mjson.tool
#http get http://localhost:7878/v1.0/49d0548301a440f2bb5374b8ceef3a73/loadbalancers x-auth-token:49d0548301a440f2bb5374b8ceef3a73

echo http get $URL/version/ $XTOKEN
http get $URL/version/ $XTOKEN
