<#

    Glance Module

#>

#-----------------------------#
#--- GlanceADComputerError ---#
#-----------------------------#
function GlanceADComputerError {

    [CmdletBinding()]
    Param(

    [int]$Newest = 5

    )

    $errorLog = @()

    $computerSearch = ((Get-ADComputer -Filter *).name) | Sort-Object -Property Name

    #Gathers the system errors from the list of computers created above.
    Foreach($computer in $computerSearch){

        if(Test-Connection $computer -Quiet){

            try{

                $errorLog += Get-EventLog -ComputerName $computer -LogName System -EntryType Error -Newest $newest | 
                    Select-Object -Property @{n="Computer";e={$computer}},TimeWritten,EventID,InstanceID,Message
            
            }catch{}

        }
        
    }

    #Returns the array of errors to the console.
    $errorLog | Select-Object -Property Computer,TimeWritten,EventID,InstanceID,Message

    return

}

#--------------------------#
#--- GlanceADDiskHealth ---#
#--------------------------#

function GlanceADDiskHealth{

    $physicalDiskHealthLog = @()

    $computerSearch = ((Get-ADComputer -Filter *).name) | Sort-Object -Property name
    
    #Gathers the physical disk info from the list of computers created above.
    foreach($computerName in $computerSearch){
    
        try{
    
            $physicalDisk = Get-PhysicalDisk -CimSession $computerName | 
                Where-Object -Property HealthStatus | 
                Select-Object -Property @{n="ComputerName";e={$computerName}},`
                FriendlyName,MediaType,OperationalStatus,HealthStatus,`
                @{n="SizeGB";e={[math]::Round(($_.Size / 1GB),1)}}
    
            $physicalDiskHealthLog += $physicalDisk
    
        }catch{}
    
    }
    
    #Returns the array of PS objects to the console with the properties in the order shown in the command.
    $physicalDiskHealthLog | Select-Object -Property ComputerName,FriendlyName,MediaType,OperationalStatus,HealthStatus,SizeGB
    
    Return

}

#--------------------------#
#--- GlanceADDriveSpace ---#
#--------------------------#

function GlanceADDriveSpace {

    $driveSpaceLog = @()

    $computerSearch = ((Get-ADComputer -Filter *).name) | Sort-Object -Property Name
    
    #Gathers the drive info from the list of computers created above.
    foreach($computerName in $computerSearch){
    
        try{
    
            $driveSpace = Get-CimInstance -ComputerName $computerName -ClassName win32_logicaldisk | 
                Select-Object -Property @{name="ComputerName";expression={$computerName}},`
                @{name="DeviceID";expression={$_.deviceid}},`
                @{name="StorageGB";expression={[math]::Round(($_.size / 1GB),1)}},`
                @{name="FreeSpaceGB";expression={[math]::Round(($_.freespace / 1GB),1)}},`
                @{name="Under20Percent";expression={if($_.freespace / $_.size -le 0.2){"True"}else{"False"}}}
    
            $driveSpaceLog += $driveSpace
    
        }catch{}
    
    }
    
    #Returns an array of PS objects with all the drive information.
    $driveSpaceLog | Select-Object -Property ComputerName,DeviceID,StorageGB,FreeSpaceGB,Under20Percent
    
    return

}

#---------------------------#
#--- GlanceADFailedLogon ---#
#---------------------------#

function GlanceADFailedLogon{

    $failedLoginLog = @()

    $computerSearch = ((Get-ADComputer -Filter *).name) | Sort-Object -Property Name
    
    foreach($computerName in $computerSearch){
    
        try{
    
            $failedLogin = Get-EventLog -ComputerName $computerName -LogName Security -InstanceId 4625 -After ((Get-Date).AddDays(-1)) |
                Select-Object -Property @{n="ComputerName";e={$computerName}},TimeWritten,EventID
    
            $failedLoginLog += $failedLogin
    
        }catch{}
        
    }
    
    #Returns an array of PS objects with failed logon events.
    $failedLoginLog | Select-Object -Property ComputerName,TimeWritten,EventID
    
    return 

}