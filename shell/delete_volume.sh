while [ true ]
do
    for i in `cinder snapshot-list --all-| awk '{print $2}' | grep -v ID`; do cinder snapshot-reset-state $i;cinder snapshot-delete $i;done;
    for i in `cinder list --all-| awk '{print $2}' | grep -v ID`; do cinder reset-state $i; cinder delete $i;done;
    sleep 15
done 
