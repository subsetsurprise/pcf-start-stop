#!/bin/bash
# Deletes BOSH vms with ruthless abandon

if [[ ($1 == "shut") || ($1 == "start" ) || ($1 == "shutall") ]]
        then
                echo "Running PCF $1 Process (warning: this toggles director resurrection off/on!)..."
        else
                echo "Usage: $0 [shut|start|shutall]"
                exit 1
fi

deleteVMs() {
 bundle exec bosh vm resurrection off
  for x in $jobVMs; do
     jobId=$(echo $x | awk -F "/" '{ print $1 }')
     instanceId=$(echo $x | awk -F "/" '{ print $2 }'| awk -F '(' '{ print $1 }')
     if [ -z $instanceId ]; then
       continue
     fi
     jobVMID=$(echo $x | awk -F ',' '{ print $2 }')
       echo Killing: $jobId
       bundle exec bosh -n -N delete vm $jobVMID
   done
   echo "Kill VM tasks scheduled, execing 'watch bundle exec bosh tasks --no-filter' to track progress"
   watch bundle exec bosh tasks --no-filter
}

if [ $1 == "shutall" ]; then
 jobVMs=$(bundle exec bosh vms --details| awk -F '|' '{gsub(/ /, "", $0); print $2","$7 }')
 deleteVMs
fi

if [ $1 == "shut" ]; then
 jobVMs=$(bundle exec bosh instances --details| awk -F '|' '{gsub(/ /, "", $0); print $2","$7 }')
 deleteVMs
fi


if [ $1 == "start" ]; then
 bundle exec bosh -n deploy
 bundle exec bosh vm resurrection on
fi

