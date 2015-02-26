#!/bin/bash
mysql -u root -ppwroot <<EOF
    use nova;
    update instance_faults set details = 'hello' where instance_uuid = 'c1f5848d-7ae9-4ab8-9de5-9905d154bb6d';
EOF
