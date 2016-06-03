#!/bin/bash
# Updated for 1.6 with workaround for nfs_mounter
# Updated for 1.7 new Gemfile location

if [ -f /home/tempest-web/tempest/web/vendor/bosh/Gemfile ];
then
  export BUNDLE_GEMFILE=/home/tempest-web/tempest/web/vendor/bosh/Gemfile
else
  export BUNDLE_GEMFILE=/home/tempest-web/tempest/web/bosh.Gemfile
fi

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
 jobVMs=$(bundle exec bosh vms --detail|grep partition| awk -F '|' '{ print $2 }')
 bundle exec bosh vm resurrection off
 for (( i=${#bootOrder[@]}-1; i>=0; i-- )); do
        for x in $jobVMs; do
                jobId=$(echo $x | awk -F "/" '{ print $1 }')
                instanceId=$(echo $x | awk -F "/" '{ print $2 }')
                jobType=$(echo $jobId | awk -F "-" '{ print $1 }')
                        if [ "$jobType" == "${bootOrder[$i]}" ];
                        then
                                #echo MATCHVAL---${bootOrder[$i]} JOBTYPE----$jobType JOBID----$jobId Instance-------$instanceId
                                bundle exec bosh -n stop $jobId --hard
                        fi
        done;

 done
 bundle exec bosh -n stop --hard
fi


if [ $1 == "start" ]; then
 bundle exec bosh -n start
 bundle exec bosh vm resurrection on
fi

