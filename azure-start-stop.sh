#!/bin/bash
# The safe/slow way to stop bosh jobs, for non-Ops Man deployments eg. Azure

if [ $1 == "shut" -o $1 == "start" ];
        then
                echo "Running PCF $1 Process..."
        else
                echo "Only shut or start are valid args!"
                exit 1
fi


# These must be explicitly stopped due to nfs_mounter blocking as of 1.6.17
declare -a bootOrder=(
cloud_controller
clock_global
cloud_controller_worker
)


if [ $1 == "shut" ]; then
 jobVMs=$(bosh vms --details| awk -F '|' '{ print $2 }')
 bosh vm resurrection off
 for (( i=${#bootOrder[@]}-1; i>=0; i-- )); do
        for x in $jobVMs; do
                jobId=$(echo $x | awk -F "/" '{ print $1 }')
                instanceId=$(echo $x | awk -F "/" '{ print $2 }')
                if [ -z $instanceId ]; then
                  continue
                fi
                jobType=$(echo $jobId | awk -F "-" '{ print $1 }')
                        if [ "$jobType" == "${bootOrder[$i]}" ];
                        then
                                #echo MATCHVAL---${bootOrder[$i]} JOBTYPE----$jobType JOBID----$jobId Instance-------$instanceId
                                bosh -n stop $jobId --hard
                        fi
        done;

 done
 bosh -n stop --hard
fi


if [ $1 == "start" ]; then
 bosh -n start
 bosh vm resurrection on
fi

