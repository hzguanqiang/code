i=1
while [ true ]
do
        echo "==================Testing $i times ======================"
        echo "create volume vol-1-copy"
	cinder create --display-name vol-1-copy --snapshot-id 1de9a592-c4ce-4937-bf8f-d8b570abc72e 20 --metadata nbs_copycount=1 --metadata nbs_hostname=10-180-0-68
	sleep 5
	vol=`cinder list | grep vol-1-copy | grep available | awk '{print $2}'`
        echo "create server test-server-copy-1"
	nova boot --boot-volume $vol --flavor flavor_1 --nic net-id=d223523d-53a2-44ad-add1-f5818a96b0b3  --availability-zone cnsdev2:10-180-0-68  test-server-copy-1 
        inst=`nova list | grep test-server-copy-1 | grep -v delet | awk '{print $2}'`

	sleep 30

	while [ true ] 
	do
	  res=`nova console-log $inst | grep Cloud-init |  grep -o "[^ ]\+\( \+[^ ]\+\)*"`
	  if [ "$res" != "" ]
	  then
	     echo 'bingo, test-server-copy-1 starting over'
	     break
	 else 
	     echo 'test-server-copy-1 starting not finish'
	     sleep 5
	     res=`nova console-log $inst | grep Cloud-init |  grep -o "[^ ]\+\( \+[^ ]\+\)*"`
	 fi 
	 done

	sleep 15

        t=`date`
        echo "rebooting test-server-copy-1"
	nova reboot $inst --hard
        sleep 30

	while [ true ] 
	do  
	  res=`nova console-log $inst | grep Cloud-init |  grep -o "[^ ]\+\( \+[^ ]\+\)*"`
	  if [ "$res" != "" ] 
	  then 
	     echo 'bingo, test-server-copy-1 rebooting over'
	     break
	 else 
	     echo "$t -- `date`, test-server-copy-1 rebooting not finish"
	     sleep 5
	     res=`nova console-log $inst | grep Cloud-init |  grep -o "[^ ]\+\( \+[^ ]\+\)*"`
	 fi 
	 done

        echo "delete server test-server-copy-1 and volume vol-1-copy "
	nova delete $inst
        sleep 30
        while [ true ]
        do 
                tt=`nova show $inst`
                if [[ "$tt" == "" ]]
		then
		    echo "test-server-copy-1 deleted"
		    break
		else
                    echo "continue to delete test-server-copy-1"
		    sleep 5
                fi
        done
	cinder delete $vol
	sleep 10
        i=`expr $i + 1`
        echo $i

done
