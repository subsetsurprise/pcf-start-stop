Add-PSSnapin VMware.VimAutomation.Core

#Connect To Server
Connect-VIServer -Server 192.168.10.5 -User administrator@vsphere.local -Password pivotal

#test if Initial Director Is Powered Off
$objState = Get-VM vm-1b76d67a-78c1-4459-80eb-500d9509f8d1 | Select-Object PowerState

#If Director is Powered Off=True
If ($objState -match "ff") {
    Write-Host "Starting Foundation...." -fore green

    $Jobs = New-Object System.Collections.ArrayList($null)
    $Jobs.Add("nats")
    $Jobs.Add("consul_server")
    $Jobs.Add("etcd_server")
    $Jobs.Add("nfs_server")
    $Jobs.Add("ccdb")
    $Jobs.Add("uaadb")
    $Jobs.Add("consoledb")
    $Jobs.Add("cloud_controller-")
    $Jobs.Add("ha_proxy")
    $Jobs.Add("router")
    $Jobs.Add("health_manager")
    $Jobs.Add("clock_global")
    $Jobs.Add("cloud_controller_worker")
    $Jobs.Add("uaa-")
    $Jobs.Add("mysql_proxy")
    $Jobs.Add("mysql-")
    $Jobs.Add("dea")
    $Jobs.Add("doppler")
    $Jobs.Add("loggregator_trafficcontroller")

    #Create Attribute Lookup table
    $customFieldMgr = Get-View (Get-View ServiceInstance).Content.CustomFieldsManager
    $customKeyLookup = @{}
    $customNameLookup = @{}
    $customFieldMgr.Field | where {$_.ManagedObjectType -eq “VirtualMachine”} | % {
        $customKeyLookup.Add($_.Key, $_.Name)
        $customNameLookup.Add($_.Name, $_.Key)
        }

    #Get VMs with Annotations in a hashtable
    $vms = Get-View -ViewType VirtualMachine
    $vmArray = @{}
    $vms | % {
        $VmCustom = @{}
        $_.CustomValue | % {
            $VmCustom.Add($_.Key, $_.Value)
            }
        $row = New-Object psobject
        $row | Add-Member -MemberType noteproperty -Name Object -Value $_
        $row | Add-Member -MemberType noteproperty -Name Custom -Value $VmCustom
        $vmArray.Add($_.Name, $row)
    }

    Foreach ( $job in $Jobs ) {
            Write-Host "Finding & starting VMs for ”$job -fore yellow
            $tgtKey = $customNameLookup[“job”]
            $myvms = $vmArray.GetEnumerator() | where {$_.Value.Custom[$tgtKey] -like “$job*”} | %{
            $_.Name
            } 
            Foreach ( $actionvm in $myvms ) {
                Write-Host "Starting "$actionvm"..."
                While ( Get-vm | where { $_.PowerState -ne “PoweredOn” -and $_.Name -eq "$actionvm"}){
                Get-VM $actionvm | Start-VM
                Start-Sleep -Seconds 5
                }
            }
        Start-Sleep -Seconds 20
        }

    #Find and Start MicroBosh
    Write-Host "Finding & starting MicroBosh\Director" -fore yellow
    $tgtKey = $customNameLookup[“Name”]
    $myvm = $vmArray.GetEnumerator() | where {$_.Value.Custom[$tgtKey] -like “microbosh*”} | %{
    $_.Name
    } 
    Foreach ( $actionvm in $myvm ) {
                Write-Host "Starting "$actionvm"..."
                While ( Get-vm | where { $_.PowerState -ne “PoweredOn” -and $_.Name -eq "$actionvm"}){
                Get-VM $actionvm | Start-VM
                }
            }
    Start-Sleep -Seconds 20
    
    While ( Get-vm | where { $_.PowerState -ne “PoweredOn” -and $_.Name -eq "Ops Manager"}){
        Get-VM "Ops Manager" | Start-VM
        }

    #Print hashtable
    #Write-Host “Report all guest with custom fields” -fore green
    #$vmArray.GetEnumerator() | %{
    #    Write-Host $_.Name
    #    $_.Value.Custom.getenumerator() | %{
    #    Write-Host “`t” $customKeyLookup[$_.Name] $_.Value
    #    }
    #}
}
