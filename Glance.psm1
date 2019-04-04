<#

    Glance Module

#>

function GlanceADComputerError{

    [CmdletBinding()]
    Param(
    
        [string]$SearchOU,
    
        [int]$Newest = 5
    
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
    
        [string]$SearchOU
    
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

        [string]$SearchOU

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

function GlanceADFailedLogon{

    [CmdletBinding()]
    Param(
    
        [string]$SearchOU
    
    )
    
    $failedLoginLog = @()
    $domainInfo = Get-ADDomain
    
    if($searchOU -eq ""){
    
        $computerSearch = ((Get-ADComputer -Filter *).name) | Sort-Object
    
    }else{
    
        $computerSearch = ((Get-ADComputer -Filter * -SearchBase "OU=$searchOU, $domainInfo").name) | Sort-Object
    
    }
    
    foreach($computerName in $computerSearch){
    
        try{
    
            $failedLogin = Get-EventLog -ComputerName $computerName -LogName Security -InstanceId 4625 -After ((Get-Date).AddDays(-1)) |
                Select-Object -Property @{n="ComputerName";e={$computerName}},TimeWritten,EventID
    
            $failedLoginLog += $failedLogin
    
        }catch{}
        
    }
    
    $failedLoginLog
    
    return 

}

function GlanceADOldComputer{

    [cmdletbinding()]
    param(
    
        [int]$MonthsOld = 6
    
    )
    
    $lastLogonList = @()
    
    $computers = Get-ADComputer -Filter * | Get-ADObject -Properties lastlogon | Select-Object -Property name,lastlogon | 
        Sort-Object -Property name
    
    foreach($computer in $computers){
    
        if(([datetime]::fromfiletime($computer.lastlogon)) -lt ((Get-Date).AddMonths(($monthsOld * -1)))){
    
            $lastLogonProperties = @{
                "Last Logon" = ([datetime]::fromfiletime($computer.lastlogon));
                "Computer" = ($computer.name)
            }
    
            $lastLogonObject = New-Object -TypeName PSObject -Property $lastLogonProperties
        
            $lastLogonList += $lastLogonObject
        
        }
    
    }
    
    $lastLogonList
    
    return

}

function GlanceADOldUser{

    [cmdletbinding()]
    param(
    
        [int]$MonthsOld = 6
    
    )
    
    $lastLogonList = @()
    
    $users = Get-ADUser -Filter * | Get-ADObject -Properties lastlogon | 
        Select-Object -Property lastlogon,name | Sort-Object -Property name
    
    foreach($user in $users){
    
        if(([datetime]::fromfiletime($user.lastlogon)) -lt ((Get-Date).AddMonths($monthsOld * -1))){
    
            $lastLogonProperties = @{
                "Last Logon" = ([datetime]::fromfiletime($user.lastlogon));
                "User" = ($user.name)
            }
    
            $lastLogonObject = New-Object -TypeName PSObject -Property $lastLogonProperties
        
            $lastLogonList += $lastLogonObject
        
        }
    
    }
    
    $lastLogonList
    
    return

}

function GlanceComputerError{

    [CmdletBinding()]
    Param(
    
        [string]$ComputerName = "$env:COMPUTERNAME",
    
        [int]$Newest = 5
    
    )
    
    #Main code
    
    if((Test-Connection $ComputerName -Quiet) -eq $true){
    #Tests to see if the computer is online.
    
        $errors = Get-EventLog -ComputerName $ComputerName -LogName System -EntryType Error -Newest $Newest |
            Select-Object -Property @{n="Computer";e={$ComputerName}},TimeWritten,EventID,InstanceID,Message
    
    }else{
        
        Write-Host "$ComputerName is not online."
    
    }
    
    $errors
    
    return

}

function GlanceComputerInfo{

    [CmdletBinding()]
    Param(
    
        [string]$ComputerName = $env:COMPUTERNAME
    
    )
    
    $computerObjectProperties = @{
      "ComputerName" = "";
      "Model" = "";
      "CPU" = "";
      "MemoryGB" = "";
      "StorageGB" = "";
      "FreeSpaceGB" = "";
      "Under20Percent" = "";
      "CurrentUser" = "";
      "IPAddress" = ""
    }
    #Creates properties that will be gathered from the computer.
    
    $computerInfo = New-Object -TypeName PSObject -Property $computerObjectProperties
    #Creates the PowerShell Object that will hold the computer info being gathered.
    
    $computerInfo.computername = $ComputerName
    #Store computer name
    
    $computerInfo.model = (Get-CimInstance -ComputerName $ComputerName -ClassName Win32_ComputerSystem -Property Model).model
    #Gathers computer model
    
    $computerInfo.CPU = (Get-CimInstance -ComputerName $ComputerName -ClassName Win32_Processor -Property Name).name
    #Gather computer CPU info
    
    $computerInfo.memoryGB = [math]::Round(((Get-CimInstance -ComputerName $ComputerName -ClassName Win32_ComputerSystem -Property TotalPhysicalMemory).TotalPhysicalMemory / 1GB),1)
    #Gather RAM amount in GB
    
    $computerInfo.storageGB = [math]::Round((((Get-CimInstance -ComputerName $ComputerName -ClassName win32_logicaldisk -Property Size) | Where-Object -Property DeviceID -eq "C:").size / 1GB),1)
    #Gather storage space in GB
    
    $computerInfo.freespaceGB = [math]::Round((((Get-CimInstance -ComputerName $ComputerName -ClassName win32_logicaldisk -Property Freespace) | Where-Object -Property DeviceID -eq "C:").freespace / 1GB),1)
    #Gather freeSpace in GB
    
    if($computerInfo.freespacegb / $computerInfo.storagegb -le 0.2){
        
        $computerInfo.under20percent = "TRUE"
    
    }else{
    
        $computerInfo.under20percent = "FALSE"
    
    }
    #Records if there is less than 20 percent of stogare space left.
    
    $computerInfo.currentuser = (Get-CimInstance -ComputerName $ComputerName -ClassName Win32_ComputerSystem -Property UserName).UserName
    #Gathers name of current user
    
    $computerInfo.IPAddress = (Test-Connection -ComputerName $ComputerName -Count 1).IPV4Address
    #add computer IPv4.
    
    $computerInfo | Select-Object -Property ComputerName,Model,CPU,MemoryGB,StorageGB,FreeSpaceGB,Under20Percent,CurrentUser,IPAddress
    
    return

}

function GlanceDiskHealth{

    [CmdletBinding()]
    Param(
    
        [string]$ComputerName = $env:COMPUTERNAME
    
    )
    
    $physicalDisk = Get-PhysicalDisk -CimSession $ComputerName | 
        Where-Object -Property HealthStatus | 
        Select-Object -Property @{n="ComputerName";e={$ComputerName}},`
        FriendlyName,MediaType,OperationalStatus,HealthStatus,`
        @{n="SizeGB";e={[math]::Round(($_.Size / 1GB),1)}}
        
    $physicalDisk | Select-Object -Property ComputerName,FriendlyName,MediaType,OperationalStatus,HealthStatus,SizeGB
    
    Return

}

function GlanceDriveSpace{

    [CmdletBinding()]
    Param(
    
        [string]$ComputerName = $env:COMPUTERNAME
    
    )
    
    $discSpaceLog = @()
    
    #Main code
    
    $discSpaceLog += Get-CimInstance -ComputerName $ComputerName -ClassName win32_logicaldisk -Property deviceid,volumename,size,freespace | 
        Where-Object -Property DeviceID -NE $null | 
        Select-Object -Property @{n="Computer";e={$ComputerName}},`
        @{n="Drive";e={$_.deviceid}},`
        @{n="VolumeName";e={$_.volumename}},`
        @{n="SizeGB";e={$_.size / 1GB -as [int]}},`
        @{n="FreeGB";e={$_.freespace / 1GB -as [int]}},`
        @{n="Under20Percent";e={if(($_.freespace / $_.size) -le 0.2){"True"}else{"False"}}}
    
    $discSpaceLog | Select-Object -Property Computer,Drive,VolumeName,SizeGB,FreeGB,Under20Percent
    
    return

}

function GlancePingLog{

    [CmdletBinding()]
    Param(
        
        [Parameter(Mandatory=$True)]
        [string]$Target,
        
        [Parameter(Mandatory=$True)]
        [int]$Minutes
    
    )
    
    #Variables
    
    $pingObject = New-Object System.Net.NetworkInformation.Ping
    
    $pingRecord = @()
    
    $startTime = Get-Date
    
    $minuteTicker = Get-Date
    
    #Functions
    
    function CreatePingObject{
    #Creates an object out of the information from a ping that returns information.
    
        $pingResults = New-Object -TypeName psobject -Property @{`
            "Status"=$targetPing.Status;`
            "Target"=$Target;`
            "Time"=(Get-Date -Format g);`
            "ResponseTime"=$targetPing.RoundtripTime}
    
        $pingResults
    
        return
    
    }
    
    function CreateFailedPingObject{
    #Creates an object with information about a ping that does not return information.
    
        $pingResults = New-Object -TypeName psobject -Property @{`
            "Status"="Failure";`
            "Target"=$Target;`
            "Time"=(Get-Date -Format g);`
            "ResponseTime"= 0}
    
        
        $pingResults
    
        return
    
    }
    
    #Main code
    
    While(((Get-Date) -le $startTime.AddMinutes($Minutes))){
    #Runs for the number of minutes stored in $Minutes.
        
        if((Get-Date) -ge $minuteTicker){
            
            Try{
    
                $targetPing = $pingObject.Send($Target)
    
                if(($targetPing.Status) -eq "Success"){
                #Ping found target.
                
                    $pingRecord += CreatePingObject
                                            
                }else{
                #Ping to target timed out.
                
                    $pingRecord += CreatePingObject
                }
            }catch{
            #Ping could not find target.
    
                $pingRecord += CreateFailedPingObject
    
            }
    
            $minuteTicker = $minuteTicker.AddMinutes(1)
            
        }
    
    }
    
    $pingRecord | Select-Object -Property status,target,time,ResponseTime
    
    Return

}