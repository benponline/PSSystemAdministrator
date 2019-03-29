<#

    Glance Module

#>

function GlanceADComputerError{

    [CmdletBinding()]
    Param(
    
        [string]$searchOU,
    
        [int]$newest = 5
    
    )
    
    $domainInfo = Get-ADDomain
    $errorLog = @()
    
    if($searchOU -eq ""){
    
        $computerSearch = ((Get-ADComputer -Filter *).name) | Sort-Object
    
    }elseif($searchOU -eq "computers"){
    
        $computerSearch = ((Get-ADComputer -Filter * -SearchBase "CN=$searchOU, $domainInfo").name) | 
            Sort-Object
    
    }else{
    
        $computerSearch = ((Get-ADComputer -Filter * -SearchBase "OU=$searchOU, $domainInfo").name) |
            Sort-Object
    
    }
    
    Foreach($computer in $computerSearch){
    
        if((Test-Connection $computer -Quiet) -eq $true){
    
            try{
    
                $errorLog += Get-EventLog -ComputerName $computer -LogName System -EntryType Error -Newest $newest | 
                    Select-Object -Property @{n="Computer";e={$computer}},TimeWritten,EventID,InstanceID,Message
            
            }catch{}
    
        }
        
    }
    
    $errorLog
    
    return 

}

function GlanceADDiskHealth{

    [CmdletBinding()]
    Param(
    
        [string]$searchOU
    
    )
    
    $domaininfo = Get-ADDomain
    $physicalDiskHealthLog = @()
    
    if($searchOU -eq ""){
    
        $computerSearch = ((Get-ADComputer -Filter *).name) | Sort-Object
    
    }else{
    
        $computerSearch = ((Get-ADComputer -Filter * -SearchBase "OU=$searchOU, $domainInfo").name) | Sort-Object
    
    }
    
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
    
    $physicalDiskHealthLog
    
    Return

}

function GlanceADDriveSpace{

    [CmdletBinding()]
    Param(

        [string]$searchOU

    )

    $domainInfo = Get-ADDomain
    $driveSpaceLog = @()

    if($searchOU -eq ""){

        $computerSearch = ((Get-ADComputer -Filter *).name) | Sort-Object

    }elseif($searchOU -eq "computers"){

        $computerSearch = ((Get-ADComputer -Filter * -SearchBase "CN=$searchOU, $domainInfo").name) | 
            Sort-Object

    }else{

        $computerSearch = ((Get-ADComputer -Filter * -SearchBase "OU=$searchOU, $domainInfo").name) | 
            Sort-Object

    }

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

    $driveSpaceLog

    return

}