#!/bin/bash
# Deletes BOSH vms with ruthless abandon

# CHange me to your bosh command name (e.g. bosh2)
export COMMAND=bosh

if [[ ($1 == "shutall") ]]
        then
                echo "Running PCF $1 Process ..."
        else
                echo "Usage: $0 [shutall]"
                exit 1
fi

deleteVMs() {
  for x in $jobVMs; do
     jobVMID=$(echo $x | awk -F ',' '{ print $2 }')
       echo Killing: $x
       $COMMAND -d $current_deployment -n delete-vm $jobVMID 2>&1 >> dev/null &
   done
   echo "Kill VM tasks scheduled, execing 'watch $COMMAND tasks --no-filter' to track progress"
   watch $COMMAND tasks -a
}

if [ $1 == "shutall" ]; then
 deployments=$($COMMAND deployments --json | jq -r '.Tables[0].Rows[] | [ .name ] | @csv' | sed 's/"//g')
 for current_deployment in $deployments; do
   jobVMs=$($COMMAND vms -d $current_deployment --json | jq -r '.Tables[0].Rows[] | [ .instance, .vm_cid ] | @csv' | sed 's/"//g')
   deleteVMs
 done
fi

