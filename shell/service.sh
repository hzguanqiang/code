#!/bin/sh
service libvirt-bin restart
service nova-api restart
service nova-compute restart
service nova-network restart
service nova-scheduler restart
service keystone restart
