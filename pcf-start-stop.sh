#!/bin/bash

export BUNDLE_GEMFILE=/home/tempest-web/tempest/web/bosh.Gemfile
if [ $1 == "shut" -o $1 == "start" ];
        then
                echo "Running PCF $1 Process..."
        else
                echo "Only shut or start are valid args!"
                exit 1
fi

declare -a bootOrder=(
nats
etcd_server
nfs_server
ccdb
uaadb
consoledb
cloud_controller
ha_proxy
router
health_manager
clock_global
cloud_controller_worker
uaa
login
mysql_proxy
mysql
dea
doppler
loggregator_trafficcontroller
)


if [ $1 == "shut" ]; then
 jobVMs=$(bundle exec bosh vms --detail|grep partition| awk -F '|' '{ print $2 }')
 bundle exec bosh vm resurrection disable
 for (( i=${#bootOrder[@]}-1; i>=0; i-- )); do
        for x in $jobVMs; do
                jobId=$(echo $x | awk -F "/" '{ print $1 }')
                instanceId=$(echo $x | awk -F "/" '{ print $2 }')
                jobType=$(echo $jobId | awk -F "-" '{ print $1 }')
                        if [ "$jobType" == "${bootOrder[$i]}" ];
                        then
                                #echo MATCHVAL---${bootOrder[$i]} JOBTYPE----$jobType JOBID----$jobId Instance-------$instanceId
                                bundle exec bosh -n stop $jobId $instanceId --hard
                        fi
        done;

 done
fi


if [ $1 == "start" ]; then
 startJobVMs=$(bundle exec bosh vms --detail|grep partition| awk -F '|' '{ print $4 }')
 bundle exec bosh vm resurrection enable
 for x in ${bootOrder[@]}; do
        for i in $startJobVMs; do
                jobString=$i
                jobPart=$(echo $jobString | awk -F "-" '{ print $3 }')
                jobType=$(echo $jobString | awk -F "-" '{ print $1 }')
                 if [ "$x" == "$jobType" ];
                 then
                        #echo FOUND $jobString
                        bundle exec bosh -n start $jobString
                 fi
        done;
 done
fi


