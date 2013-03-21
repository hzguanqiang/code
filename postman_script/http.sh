#!/bin/bash
#URLL+tenantID
TENANT=`keystone token-get |grep tenant_id| awk '{print $4}'`
TOKEN=`keystone token-get |grep id |grep -v _id | awk '{print $4}'`

#URL='http://localhost:7878/v1.0/49d0548301a440f2bb5374b8ceef3a73'
URL='http://localhost:7878/v1.0/'$TENANT
#TOKEN=`/home/openstack/script/getToken.sh`
XTOKEN='x-auth-token:'$TOKEN
MODEL='POST'
REQUEST=''
id=$i
#curl -H $XTOKEN -X $MODEL -v $URL/servers/detail  | python -mjson.tool

http post $URL/loadbalancers $XTOKEN <<< \
'''
{
    "loadBalancer": {
        "name": "lb-site12",
        "protocol": "TCP",
        "port": 80,
        "algorithm": "rr",
        "checktimeout":10,
        "checkinterval":2
    }
}
'''
