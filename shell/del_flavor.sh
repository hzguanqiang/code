#!/bin/bash
flavor_id=11
while [ "$flavor_id" -lt "911" ]
do
    echo nova flavor-delete $flavor_id
    nova flavor-delete $flavor_id
    flavor_id=`expr $flavor_id + 1`
done
