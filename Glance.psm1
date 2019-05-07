function GlanceADComputerError {

    <#

    .SYNOPSIS
    This cmdlet gathers system errors from AD computers.

    .DESCRIPTION
    This cmdlet gathers system errors from all AD computers.  

    .PARAMETER Newest
    Specifies the number of recent system errors to be returned.

    .INPUTS
    None. You cannot pipe input to this cmdlet.

    .OUTPUTS
    Returns PS objects containing system error information including Computer, TimeWritten, EventID, 
    InstanceId, and Message.

    .NOTES
    This cmdlet can take a long time to finish if there are a large number of computers/errors.

    Requires "Printer and file sharing" and "Network Discovery" to be enabled.

    Windows Server 2012, Windows 7, or newer. "Get-EventLog: No matched found" is returned when the 
    script contacts a computer running an OS older then is required.

    .EXAMPLE
    GlanceADComputerError

    This cmdlet returns the 5 newest system errors from all AD computers.

    .EXAMPLE
    GlanceADComputerError -newest 2

    This cmdlet returns the 2 newest system errors from all AD computers.

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    #>

    [CmdletBinding()]
    Param(
    
        [int]$Newest = 5
    
    )
    
    $ErrorActionPreference = "Stop"
    
    $errorLog = @()
    
    $computerSearch = ((Get-ADComputer -Filter *).name) 
    
    Foreach($computer in $computerSearch){
    
        if(Test-Connection $computer -Quiet){
    
            try{
    
                $errorLog += Get-EventLog -ComputerName $computer -LogName System -EntryType Error -Newest $newest | 
                    Select-Object -Property @{n="Computer";e={$computer}},TimeWritten,EventID,InstanceID,Message
            
            }catch{}
    
        }
        
    }
    
    $errorLog | Select-Object -Property Computer,TimeWritten,EventID,InstanceID,Message | Sort-Object -Property Computer
    
    return

}

function GlanceADComputerInfo{

    <#

    .SYNOPSIS
    This cmdlet gathers infomation about a computer.

    .DESCRIPTION
    This cmdlet gathers infomation about a computer. By default it gathers info from the local host.
    The information includes computer name, model, CPU, memory in GB, storage in GB, free space in GB, 
    if less than 20 percent of storage is left, the current user, and IP address.

    .PARAMETER ComputerName
    Specifies the computer.

    .INPUTS
    None. You cannot pipe input to this cmdlet.

    .OUTPUTS
    Returns an object with computer name, model, CPU, memory in GB, storage in GB, free space in GB, if
    less than 20 percent of storage is left, and the current user.

    .NOTES

    .EXAMPLE
    GlanceComputerInfo -ComputerName Server1

    This returns computer into on Server1.

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    #>

    $ErrorActionPreference = "Stop"

    $computerList = (Get-ADComputer -Filter *).name

    $computerLog = @()

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

    foreach($ComputerName in $computerList){

        try{

            $computerInfo = New-Object -TypeName PSObject -Property $computerObjectProperties

            $computerInfo.computername = $ComputerName

            $computerInfo.model = (Get-CimInstance -ComputerName $ComputerName -ClassName Win32_ComputerSystem -Property Model).model

            $computerInfo.CPU = (Get-CimInstance -ComputerName $ComputerName -ClassName Win32_Processor -Property Name).name

            $computerInfo.memoryGB = [math]::Round(((Get-CimInstance -ComputerName $ComputerName -ClassName Win32_ComputerSystem -Property TotalPhysicalMemory).TotalPhysicalMemory / 1GB),1)

            $computerInfo.storageGB = [math]::Round((((Get-CimInstance -ComputerName $ComputerName -ClassName win32_logicaldisk -Property Size) | 
                Where-Object -Property DeviceID -eq "C:").size / 1GB),1)

            $computerInfo.freespaceGB = [math]::Round((((Get-CimInstance -ComputerName $ComputerName -ClassName win32_logicaldisk -Property Freespace) | 
                Where-Object -Property DeviceID -eq "C:").freespace / 1GB),1)

            if($computerInfo.freespacegb / $computerInfo.storagegb -le 0.2){
                
                $computerInfo.under20percent = "TRUE"

            }else{

                $computerInfo.under20percent = "FALSE"

            }

            $computerInfo.currentuser = (Get-CimInstance -ComputerName $ComputerName -ClassName Win32_ComputerSystem -Property UserName).UserName

            $computerInfo.IPAddress = (Test-Connection -ComputerName $ComputerName -Count 1).IPV4Address

            $computerLog += $computerInfo

        }catch{}

    }

    $computerLog | Select-Object -Property ComputerName,Model,CPU,MemoryGB,StorageGB,FreeSpaceGB,Under20Percent,CurrentUser,IPAddress | Sort-Object -Property ComputerName

    return

}

function GlanceADComputerSoftware{

    <#

    .SYNOPSIS
    This cmdlet gathers all of the installed software on a computer.

    .DESCRIPTION
    This cmdlet gathers all of the installed software on a computer.  or group of computers.  

    .PARAMETER ComputerName
    A list of installed software will be pulled from this computer 

    .INPUTS
    You can pipe input to this cmdlet.

    .OUTPUTS
    Returns PS objects containing computer name, software name, version, installdate, uninstall 
    command, registry path.

    .NOTES
    Requires remote registry service running on remote machines.

    .EXAMPLE
    GlanceComputerSoftware

    This cmdlet returns all installed software on the local host.

    .EXAMPLE
    GlanceComputerSoftware -ComputerName “Computer”

    This cmdlet returns all the software installed on "Computer".

    .EXAMPLE
    GLanceComputerSoftware -Filter * | GlanceComputerSoftware

    This cmdlet returns the installed software on all computers on the domain.

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT


    .LINK
    Based on code from:
    https://community.spiceworks.com/scripts/show/2170-get-a-list-of-installed-software-from-a-remote-computer-fast-as-lightning

    #>

    $ErrorActionPreference = "Stop"

    $computerList = (Get-ADComputer -Filter *).name | Sort-Object -Property Name
    
    $lmKeys = "Software\Microsoft\Windows\CurrentVersion\Uninstall","SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    
    $lmReg = [Microsoft.Win32.RegistryHive]::LocalMachine
    
    $cuKeys = "Software\Microsoft\Windows\CurrentVersion\Uninstall"
    
    $cuReg = [Microsoft.Win32.RegistryHive]::CurrentUser
    
    $masterKeys = @()
    
    foreach($ComputerName in $computerList){
    
        try{
    
            if((Test-Connection -ComputerName $ComputerName -Count 1 -ErrorAction Stop)){
    
                $remoteCURegKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($cuReg,$ComputerName)
                
                $remoteLMRegKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($lmReg,$ComputerName)
    
                foreach($key in $lmKeys){
                    $regKey = $remoteLMRegKey.OpenSubkey($key)
                        
                    foreach ($subName in $regKey.GetSubkeyNames()) {
                        
                        foreach($sub in $regKey.OpenSubkey($subName)) {
                        
                            $masterKeys += (New-Object PSObject -Property @{
                                "ComputerName" = $ComputerName;
                                "Name" = $sub.getvalue("displayname");
                                "SystemComponent" = $sub.getvalue("systemcomponent");
                                "ParentKeyName" = $sub.getvalue("parentkeyname");
                                "Version" = $sub.getvalue("DisplayVersion");
                                "UninstallCommand" = $sub.getvalue("UninstallString");
                                "InstallDate" = $sub.getvalue("InstallDate");
                                "RegPath" = $sub.ToString()})
                        }
                                
                    }
                            
                }
    
                foreach ($key in $cuKeys) {
    
                    $regKey = $remoteCURegKey.OpenSubkey($key)
    
                    if($regKey -ne $null){
    
                        foreach($subName in $regKey.getsubkeynames()){
    
                            foreach ($sub in $regKey.opensubkey($subName)) {
    
                                $masterKeys += (New-Object PSObject -Property @{
                                    "ComputerName" = $ComputerName;
                                    "Name" = $sub.getvalue("displayname");
                                    "SystemComponent" = $sub.getvalue("systemcomponent");
                                    "ParentKeyName" = $sub.getvalue("parentkeyname");
                                    "Version" = $sub.getvalue("DisplayVersion");
                                    "UninstallCommand" = $sub.getvalue("UninstallString");
                                    "InstallDate" = $sub.getvalue("InstallDate");
                                    "RegPath" = $sub.ToString()})
                                
                            }
                            
                        }
                            
                    }
                        
                }
                        
            }else{
    
                break
    
            }
    
        }catch{}
    
    }
    
    $woFilter = {$null -ne $_.name -AND $_.SystemComponent -ne "1" -AND $null -eq $_.ParentKeyName}
    
    $props = 'ComputerName','Name','Version','Installdate','UninstallCommand','RegPath'
    
    $masterKeys = ($masterKeys | Where-Object $woFilter | Select-Object -Property $props | Sort-Object -Property ComputerName)
    
    $masterKeys

}

function GlanceADDiskHealth{

    <#

    .SYNOPSIS
    This cmdlet returns the health status of the physical disks in AD computers.

    .DESCRIPTION
    This cmdlet returns physical disk health information from all AD computers, specific 
    organizational units, or the "computers" container. By default, it returns disk info from all AD
    computers.

    .PARAMETER SearchOU
    Specifies the top level OU the cmdlet will search.

    .INPUTS
    None. You cannot pipe input to this cmdlet.

    .OUTPUTS
    Returns array of objects with physical disk info including computer name, friendly name, media 
    type, operational status, health status, and size in GB.

    .NOTES
    Only returns information from computers running Windows Server 2012, Windows 7 or higher.

    .EXAMPLE
    GlanceADDiskHealth

    Returns disk health information for all computers in the domain.

    .EXAMPLE
    GlanceADDiskHealth -searchOU "Servers"

    Returns disk health information for all computers in the "Servers" OU.

    .LINK
    By Ben Peterson
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

    #>

    $ErrorActionPreference = "Stop"

    $physicalDiskHealthLog = @()
    
    $computerSearch = ((Get-ADComputer -Filter *).name)
    
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
    
    $physicalDiskHealthLog | Select-Object -Property ComputerName,FriendlyName,MediaType,OperationalStatus,HealthStatus,SizeGB | Sort-Object -Property ComputerName

    Return

}

function GlanceADDriveSpace {

    $ErrorActionPreference = "Stop"

    $driveSpaceLog = @()
    
    $computerSearch = ((Get-ADComputer -Filter *).name) 

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
    
    $driveSpaceLog = $driveSpaceLog | Where-Object -Property StorageGB -NE 0
    
    $driveSpaceLog | Select-Object -Property ComputerName,DeviceID,StorageGB,FreeSpaceGB,Under20Percent | Sort-Object -Property ComputerName
    
    return

}

function GlanceADFailedLogon{

    <#

    .SYNOPSIS
    This cmdlet returns a list of failed logon events from AD computers.

    .DESCRIPTION
    This cmdlet can return failed logon events from all AD computers, computers in a specific 
    organizational unit, or computers in the "computers" container.

    .PARAMETER SearchOU
    Specifies the top level OU the cmdlet will search.

    .INPUTS
    None. You cannot pipe input to this cmdlet.

    .OUTPUTS
    Returns PS objects with computer names, time written, and event IDs for failed logon events.

    .NOTES

    .EXAMPLE
    GlanceADFailedLogon

    Returns failed logon events from all computers in the domain.

    .EXAMPLE
    GlanceADFailedLogon -searchOU "Servers"

    Returns failed logon events from all computers in the "Servers" OU.

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    #>

    [CmdletBinding()]
    Param(
    
        [int]$daysBack = 1
    
    )
    
    $ErrorActionPreference = "Stop"
    
    $failedLoginLog = @()
    
    $computerSearch = ((Get-ADComputer -Filter *).name) | Sort-Object -Property Name
    
    foreach($computerName in $computerSearch){
    
        try{
    
            $failedLogin = Get-EventLog -ComputerName $computerName -LogName Security -InstanceId 4625 -After ((Get-Date).AddDays($daysBack * -1)) |
                Select-Object -Property @{n="ComputerName";e={$computerName}},TimeWritten,EventID
    
            $failedLoginLog += $failedLogin
    
        }catch{}
        
    }
    
    $failedLoginLog | Select-Object -Property ComputerName,TimeWritten,EventID
    
    return

}

function GlanceADOfflineComputer {

    <#

    .SYNOPSIS

    .DESCRIPTION

    .INPUTS

    .OUTPUTS

    .NOTES

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    #>

    $computers = Get-ADComputer -Filter *

    $offlineComputers = @()
    
    foreach($computer in $computers){
    
        if(!(Test-Connection -ComputerName ($computer.name) -Count 1 -Quiet)){
    
            $offlineComputers += $computer
    
        }
    
    }
    
    $offlineComputers | Select-Object -Property Name,DNSHostName,DistinguishedName | Sort-Object -Property Name
    
    return
    
}

function GlanceADOldComputer{

    <#

    .SYNOPSIS
    This cmdlet returns a list of all the computers in AD that have not been online for a specific 
    amount of time.

    .DESCRIPTION
    Returns a list of all the computers in AD that have not been online a number of months. The default
    amount of months is 6. Can be set by the user by passing a value to MonthsOld.

    .PARAMETER MonthsOld
    Determines how long the computer account has to be inactive for it to be returned.

    .INPUTS
    None.

    .OUTPUTS
    Array of PS objects with information including computer names and the date it last connected to the
    domain.

    .NOTES
    None.

    .EXAMPLE
    GlanceADOldComputer

    Lists all computers in the domain that have not checked in for more than 6 months.

    .EXAMPLE
    GlanceADOldComputer -MonthsOld 2

    Lists all computers in the domain that have not checked in for more than 2 months.

    .LINK
    By Ben Peterson
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

    #>

    [CmdletBinding()]
    Param(
    
        [int]$MonthsOld = 3
    
    )
    
    $lastLogonList = @()
    
    $computers = Get-ADComputer -Filter * | Get-ADObject -Properties lastlogon | Select-Object -Property name,lastlogon
    
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
    
    $lastLogonList | Sort-Object -Property Computer
    
    return

}

function GlanceADOldUser{

    <#

    .SYNOPSIS
    This cmdlet returns a list of all the users in AD that have not logged on for an amount of months.

    .DESCRIPTION
    Returns a list of all the users in AD that have not been online a number of months. The default
    amount of months is 6. Can be set by the user by passing a value to MonthsOld.

    .PARAMETER MonthsOld
    Determines how long the computer account has to be inactive for it to be returned.

    .INPUTS
    None.

    .OUTPUTS
    Array of PS objects with user names and last logon date.

    .NOTES
    None.

    .EXAMPLE
    GlanceADOldUser

    Lists all users in the domain that have not checked in for more than 6 months.

    .EXAMPLE
    GlanceADOldUser -MonthsOld 2

    Lists all users in the domain that have not checked in for more than 2 months.

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    #>

    [CmdletBinding()]
    Param(
    
        [int]$MonthsOld = 3
    
    )
    
    $lastLogonList = @()
    
    $users = Get-ADUser -Filter * | Get-ADObject -Properties lastlogon | 
        Select-Object -Property lastlogon,name 
    
    foreach($user in $users){
    
        if(([datetime]::fromfiletime($user.lastlogon)) -lt ((Get-Date).AddMonths($monthsOld * -1))){
    
            $lastLogonProperties = @{
                "LastLogon" = ([datetime]::fromfiletime($user.lastlogon));
                "User" = ($user.name)
            }
    
            $lastLogonObject = New-Object -TypeName PSObject -Property $lastLogonProperties
        
            $lastLogonList += $lastLogonObject
        
        }
    
    }
    
    $lastLogonList | Select-Object -Property User,LastLogon | Sort-Object -Property User
    
    return

}

function GlanceADOlineComputer{

    <#

    .SYNOPSIS

    .DESCRIPTION

    .INPUTS

    .OUTPUTS

    .NOTES

    .EXAMPLE

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    #>

    $computers = Get-ADComputer -Filter *

    $onlineComputers = @()
    
    foreach($computer in $computers){
    
        if(Test-Connection -ComputerName ($computer.name) -Count 1 -Quiet){
    
            $onlineComputers += $computer
    
        }
    
    }
    
    $onlineComputers | Select-Object -Property Name,DNSHostName,DistinguishedName | Sort-Object -Property Name
    
    return

}

function GlanceComputerError{

    <#

    .SYNOPSIS
    This cmdlet gathers system errors from a computer.

    .DESCRIPTION
    This cmdlet gathers system errors from a computer. By default it gathers them from the local 
    computer. Computer and number of errors returned can be set by user.

    .PARAMETER ComputerName
    Specifies the computer where the errors are returned from.

    .PARAMETER Newest
    Specifies the numbers of errors returned.

    .INPUTS
    None. You cannot pipe input to this cmdlet.

    .OUTPUTS
    Returns PS objects for computer system errors with Computer, TimeWritten, EventID, InstanceId, 
    and Message.

    .NOTES
    Requires "Printer and file sharing", "Network Discovery", and "Remote Registry" to be enabled on computers 
    that are searched.

    .EXAMPLE
    GlanceComputerError

    This cmdlet returns the last 5 system errors from localhost.

    .EXAMPLE
    GetComputerError -ComputerName Server -Newest 2

    This cmdlet returns the last 2 system errors from server.

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    #>

    [CmdletBinding()]
    Param(
    
        [string]$ComputerName = $env:COMPUTERNAME,
    
        [int]$Newest = 5
    
    )
    
    $errors = Get-EventLog -ComputerName $ComputerName -LogName System -EntryType Error -Newest $Newest |
        Select-Object -Property @{n="ComputerName";e={$ComputerName}},TimeWritten,EventID,InstanceID,Message
    
    $errors | Select-Object -Property ComputerName,TimeWritten,EventID,Instance,Message
    
    return

}

function GlanceComputerInfo{

    <#

    .SYNOPSIS
    This cmdlet gathers infomation about a computer.

    .DESCRIPTION
    This cmdlet gathers infomation about a computer. By default it gathers info from the local host.
    The information includes computer name, model, CPU, memory in GB, storage in GB, free space in GB, 
    if less than 20 percent of storage is left, the current user, and IP address.

    .PARAMETER ComputerName
    
    .INPUTS
    None. You cannot pipe input to this cmdlet.

    .OUTPUTS
    Returns an object with computer name, model, CPU, memory in GB, storage in GB, free space in GB, if
    less than 20 percent of storage is left, and the current user.

    .NOTES

    .EXAMPLE
    GlanceComputerInfo -ComputerName Server1

    This returns computer into on Server1.

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    #>

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
    
    $computerInfo = New-Object -TypeName PSObject -Property $computerObjectProperties
    
    $computerInfo.computername = $ComputerName
    
    $computerInfo.model = (Get-CimInstance -ComputerName $ComputerName -ClassName Win32_ComputerSystem -Property Model).model
    
    $computerInfo.CPU = (Get-CimInstance -ComputerName $ComputerName -ClassName Win32_Processor -Property Name).name
    
    $computerInfo.memoryGB = [math]::Round(((Get-CimInstance -ComputerName $ComputerName -ClassName Win32_ComputerSystem -Property TotalPhysicalMemory).TotalPhysicalMemory / 1GB),1)
    
    $computerInfo.storageGB = [math]::Round((((Get-CimInstance -ComputerName $ComputerName -ClassName win32_logicaldisk -Property Size) | 
        Where-Object -Property DeviceID -eq "C:").size / 1GB),1)
    
    $computerInfo.freespaceGB = [math]::Round((((Get-CimInstance -ComputerName $ComputerName -ClassName win32_logicaldisk -Property Freespace) | 
        Where-Object -Property DeviceID -eq "C:").freespace / 1GB),1)
    
    if($computerInfo.freespacegb / $computerInfo.storagegb -le 0.2){
        
        $computerInfo.under20percent = "TRUE"
    
    }else{
    
        $computerInfo.under20percent = "FALSE"
    
    }
    
    $computerInfo.currentuser = (Get-CimInstance -ComputerName $ComputerName -ClassName Win32_ComputerSystem -Property UserName).UserName
    
    $computerInfo.IPAddress = (Test-Connection -ComputerName $ComputerName -Count 1).IPV4Address
    
    $computerInfo | Select-Object -Property ComputerName,Model,CPU,MemoryGB,StorageGB,FreeSpaceGB,Under20Percent,CurrentUser,IPAddress
    
    return

}

function GlanceComputerSoftware{

    <#

    .SYNOPSIS
    This cmdlet gathers all of the installed software on a computer.

    .DESCRIPTION
    This cmdlet gathers all of the installed software on a computer.  or group of computers.  

    .PARAMETERS ComputerName
    A list of installed software will be pulled from this computer 

    .INPUTS
    You can pipe input to this cmdlet.

    .OUTPUTS
    Returns PS objects containing computer name, software name, version, installdate, uninstall 
    command, registry path.

    .NOTES
    Requires remote registry service running on remote machines.

    .EXAMPLE
    GlanceComputerSoftware

    This cmdlet returns all installed software on the local host.

    .EXAMPLE
    GlanceComputerSoftware -ComputerName “Computer”

    This cmdlet returns all the software installed on "Computer".

    .EXAMPLE
    GLanceComputerSoftware -Filter * | GlanceComputerSoftware

    This cmdlet returns the installed software on all computers on the domain.

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    .LINK
    Based on code from:
    https://community.spiceworks.com/scripts/show/2170-get-a-list-of-installed-software-from-a-remote-computer-fast-as-lightning

    #>

    [cmdletbinding()]
    param(
     
        [string]$ComputerName = $env:COMPUTERNAME
        
    )
    
    $lmKeys = "Software\Microsoft\Windows\CurrentVersion\Uninstall","SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    
    $lmReg = [Microsoft.Win32.RegistryHive]::LocalMachine
    
    $cuKeys = "Software\Microsoft\Windows\CurrentVersion\Uninstall"
    
    $cuReg = [Microsoft.Win32.RegistryHive]::CurrentUser
    
    $masterKeys = @()
    
    try{
    
        if((Test-Connection -ComputerName $ComputerName -Count 1 -ErrorAction Stop)){
    
            $remoteCURegKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($cuReg,$ComputerName)
            
            $remoteLMRegKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($lmReg,$ComputerName)
    
            foreach($key in $lmKeys){
                $regKey = $remoteLMRegKey.OpenSubkey($key)
                    
                foreach ($subName in $regKey.GetSubkeyNames()) {
                    
                    foreach($sub in $regKey.OpenSubkey($subName)) {
                    
                        $masterKeys += (New-Object PSObject -Property @{
                            "ComputerName" = $ComputerName;
                            "Name" = $sub.getvalue("displayname");
                            "SystemComponent" = $sub.getvalue("systemcomponent");
                            "ParentKeyName" = $sub.getvalue("parentkeyname");
                            "Version" = $sub.getvalue("DisplayVersion");
                            "UninstallCommand" = $sub.getvalue("UninstallString");
                            "InstallDate" = $sub.getvalue("InstallDate");
                            "RegPath" = $sub.ToString()})
                    }
                            
                }
                        
            }
    
            foreach ($key in $cuKeys) {
    
                $regKey = $remoteCURegKey.OpenSubkey($key)
    
                if($regKey -ne $null){
    
                    foreach($subName in $regKey.getsubkeynames()){
    
                        foreach ($sub in $regKey.opensubkey($subName)) {
    
                            $masterKeys += (New-Object PSObject -Property @{
                                "ComputerName" = $ComputerName;
                                "Name" = $sub.getvalue("displayname");
                                "SystemComponent" = $sub.getvalue("systemcomponent");
                                "ParentKeyName" = $sub.getvalue("parentkeyname");
                                "Version" = $sub.getvalue("DisplayVersion");
                                "UninstallCommand" = $sub.getvalue("UninstallString");
                                "InstallDate" = $sub.getvalue("InstallDate");
                                "RegPath" = $sub.ToString()})
                            
                        }
                          
                    }
                        
                }
                    
            }
                    
        }else{
    
            break
    
        }
    
    }catch{}
    
    $woFilter = {$null -ne $_.name -AND $_.SystemComponent -ne "1" -AND $null -eq $_.ParentKeyName}
    
    $props = 'ComputerName','Name','Version','Installdate','UninstallCommand','RegPath'
    
    $masterKeys = ($masterKeys | Where-Object $woFilter | Select-Object -Property $props | Sort-Object -Property ComputerName)
    
    $masterKeys

}

function GlanceDiskHealth{

    <#

    .SYNOPSIS
    This script returns the health status of the physical disks on a computer.

    .DESCRIPTION
    This script returns the health status of the physical disks on the local or remote computer.

    .PARAMETER ComputerName
    Specifies the top level OU the cmdlet will search.

    .INPUTS
    None. You cannot pipe input to this cmdlet.

    .OUTPUTS
    Returns array of objects with disk info including computer name, friendly name, media type, 
    operational status, health status, and size in GB.

    .NOTES
    Only returns information from computers running Windows 10 or Windows Server 2012 or higher.

    .EXAMPLE
    GlanceDiskHealth

    Returns disk health information for the local computer.

    .EXAMPLE
    GlanceADDiskHealth -ComputerName Computer1

    Returns disk health information for the computer named Computer1.

    .LINK
    By Ben Peterson
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

    #>

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

    <#

    .SYNOPSIS
    Gathers information for the drives on a computer including computer name, drive, volume, name, 
    size, free space, and indicates those under 20% desc space remaining.

    .DESCRIPTION
    Gathers information for the drives on a computer including computer name, drive, volume, name, 
    size, free space, and indicates those under 20% desc space remaining.

    .PARAMETER ComputerName
    Specifies the computer the cmdlet will search.

    .INPUTS
    None. You cannot pipe input to this cmdlet.

    .OUTPUTS
    Returns PS objects to the host the following information about the drives on a computer: computer name, drive, 
    volume name, size, free space, and indicates those under 20% desc space remaining.  

    .NOTES


    .EXAMPLE
    GlanceDriveSpace

    Gets drive information for the local host.

    .EXAMPLE
    GlanceDriveSpace -computerName computer

    Gets drive information for "computer".

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    #>

    [CmdletBinding()]
    Param(
    
        [string]$ComputerName = $env:COMPUTERNAME
    
    )
    
    $driveSpaceLog = @()
    
    $driveSpaceLog += Get-CimInstance -ComputerName $ComputerName -ClassName win32_logicaldisk -Property deviceid,volumename,size,freespace | 
        Where-Object -Property DeviceID -NE $null | 
        Select-Object -Property @{n="Computer";e={$ComputerName}},`
        @{n="Drive";e={$_.deviceid}},`
        @{n="VolumeName";e={$_.volumename}},`
        @{n="SizeGB";e={$_.size / 1GB -as [int]}},`
        @{n="FreeGB";e={$_.freespace / 1GB -as [int]}},`
        @{n="Under20Percent";e={if(($_.freespace / $_.size) -le 0.2){"True"}else{"False"}}}
    
    $driveSpaceLog = $driveSpaceLog | Where-Object -Property SizeGB -NE 0
    
    $driveSpaceLog | Select-Object -Property Computer,Drive,VolumeName,SizeGB,FreeGB,Under20Percent
    
    return

}

function GlanceFailedLogon{

    <#

    .SYNOPSIS
    This cmdlet returns a list of failed logon events from AD computers.

    .DESCRIPTION
    This cmdlet can return failed logon events from all AD computers, computers in a specific 
    organizational unit, or computers in the "computers" container.

    .PARAMETER SearchOU
    Specifies the top level OU the cmdlet will search.

    .INPUTS
    None. You cannot pipe input to this cmdlet.

    .OUTPUTS
    Returns PS objects with computer names, time written, and event IDs for failed logon events.

    .NOTES

    .EXAMPLE
    GlanceADFailedLogon

    Returns failed logon events from all computers in the domain.

    .EXAMPLE
    GlanceADFailedLogon -searchOU "Servers"

    Returns failed logon events from all computers in the "Servers" OU.

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    #>

    [CmdletBinding()]
    Param(
    
        [string]$ComputerName = $env:COMPUTERNAME,
    
        [int]$daysBack = 1
    
    )
    
    $failedLogon = Get-EventLog -ComputerName $computerName -LogName Security -InstanceId 4625 -After ((Get-Date).AddDays($daysBack * -1)) |
        Select-Object -Property @{n="ComputerName";e={$computerName}},TimeWritten,EventID
    
    $failedLogon | Select-Object -Property ComputerName,TimeWritten,EventID
    
    return 

}