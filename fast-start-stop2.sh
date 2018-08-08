#!/bin/bash
# Deletes BOSH vms with ruthless abandon

# CHange me to your bosh command name (e.g. bosh2)
export COMMAND=bosh

if [[ ($1 == "shutall") || ($1 == "shut") || ($1 == "shutjobs") || ($1 == "shutpatterns") ]]
        then
                echo "Running PCF $1 Process ..."
        else
                echo "Usage: $0 [shutall|shut <deployment name>|shutjobs <deployment name> <job name>|shutpatterns <deployment name> <send patterns from stdin]"
                exit 1
fi

deleteVMs() {
  for x in $jobVMs; do
     jobVMID=$(echo $x | awk -F ',' '{ print $2 }')
     # Strip out noise from Azure VM CIDs (e.g. agent_id:ffff-ffff-ffffff;resource_group:eeee-eeee-eeeee )
     if [[ $jobVMID =~ agent_id ]]; then
        jobVMID=$(echo $jobVMID | awk -F ":" '{ print $2 }' | awk -F ";" '{ print $1 }')
     fi
     echo Killing: $x
     $COMMAND -d $current_deployment -n delete-vm $jobVMID 2>&1 >> /dev/null &
   done
}

if [ $1 == "shutall" ]; then
 deployments=$($COMMAND deployments --json | jq -r '.Tables[0].Rows[] | [ .name ] | @csv' | sed 's/"//g')
 for current_deployment in $deployments; do
   jobVMs=$($COMMAND vms -d $current_deployment --json | jq -r '.Tables[0].Rows[] | [ .instance, .vm_cid ] | @csv' | sed 's/"//g')
   deleteVMs
 done
fi

if [ $1 == "shut" ]; then
   current_deployment=$2

   jobVMs=$($COMMAND vms -d $current_deployment --json | jq -r '.Tables[0].Rows[] | [ .instance, .vm_cid ] | @csv' | sed 's/"//g')
   deleteVMs
fi

if [ $1 == "shutjobs" ]; then
   current_deployment=$2

   jobVMs=$($COMMAND vms -d $current_deployment --json | jq -r '.Tables[0].Rows[] | [ .instance, .vm_cid] | @csv' | sed 's/"//g' | grep $3)
   deleteVMs
fi

if [ $1 == "shutpatterns" ]; then
   current_deployment=$2
   while read pattern; do 
     jobVMs=$($COMMAND vms -d $current_deployment --json | jq -r '.Tables[0].Rows[] | [ .instance, .vm_cid ] | @csv' | sed 's/"//g' | grep $pattern)
     deleteVMs
   done
fi

echo "Kill VM tasks scheduled, execing 'watch -n $COMMAND tasks -a' to track progress"
watch -n 5 $COMMAND tasks -a

