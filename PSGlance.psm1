function Get-ADOfflineComputer{

    <#

    .SYNOPSIS
    Gets a list of all computers in AD that are currently offline. 

    .DESCRIPTION
    Returns a list of computers from AD that are offline with information including name, DNSHostName, and DistinguishedName.

    .PARAMETER None

    .INPUTS
    None.

    .OUTPUTS
    PS objects with information including name, DNSHostName, and DistinguishedName.

    .NOTES
    The firewalls must be configured to allow ping requests.

    .EXAMPLE
    Get-ADOfflineComputer

    Returns a list of all AD computers that are currently offline.

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

function Get-ADOldComputer{

    <#

    .SYNOPSIS
    Gets a list of all the computers in AD that have not been online for a specific number of months.

    .DESCRIPTION
    Returns a list of all the computers in AD that have not been online a number of months. The default amount of months is 3. Can be set by the user
    by passing a value to MonthsOld.

    .PARAMETER MonthsOld
    Determines how long the computer account has to be inactive for it to be returned.

    .INPUTS
    None.

    .OUTPUTS
    Array of PS objects with information including computer names and the date it last connected to the domain.

    .NOTES
    None.

    .EXAMPLE
    Get-ADOldComputer

    Lists all computers in the domain that have not checked in for more than 6 months.

    .EXAMPLE
    Get-ADOldComputer -MonthsOld 2

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
                "LastLogon" = ([datetime]::fromfiletime($computer.lastlogon));
                "Computer" = ($computer.name)
            }
    
            $lastLogonObject = New-Object -TypeName PSObject -Property $lastLogonProperties
        
            $lastLogonList += $lastLogonObject
        
        }
    
    }
    
    $lastLogonList | Select-Object -Property Computer,LastLogon | Sort-Object -Property Computer
    
    return

}

function Get-ADOldUser{

    <#

    .SYNOPSIS
    Gets a list of all the users in AD that have not logged on for a number amount of months.

    .DESCRIPTION
    Returns a list of all the users in AD that have not been online a number of months. The default amount of months is 3. Can be set by the user by 
    passing a value to MonthsOld.

    .PARAMETER MonthsOld
    Determines how long the computer account has to be inactive for it to be returned.

    .INPUTS
    None.

    .OUTPUTS
    PS objects with user names and last logon date.

    .NOTES
    None.

    .EXAMPLE
    Get-ADOldUser

    Lists all users in the domain that have not checked in for more than 6 months.

    .EXAMPLE
    Get-ADOldUser -MonthsOld 2

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
    
    $users = Get-ADUser -Filter * | Get-ADObject -Properties lastlogon | Select-Object -Property lastlogon,name 
    
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

function Get-ADOnlineComputer{

    <#

    .SYNOPSIS
    Gets a list of AD computers that are currently online.

    .DESCRIPTION
    Returns an array of PS objects containing the name, DNS host name, and distinguished name of AD computers that are currently online. 

    .INPUTS
    None.

    .OUTPUTS
    PS objects containing name, DNS host name, and distinguished name.

    .NOTES

    .EXAMPLE
    Get-ADOnlineComputer

    Returns list of all AD computers that are currently online.

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

function Get-ComputerError{

    <#

    .SYNOPSIS
    Gets system errors from a computer.

    .DESCRIPTION
    Returns system errors from a computer. By default it gathers them from the local 
    computer. Computer and number of errors returned can be set by user.

    .PARAMETER Name
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
    Get-ComputerError

    This cmdlet returns the last 5 system errors from localhost.

    .EXAMPLE
    Get-ComputerError -ComputerName Server -Newest 2

    This cmdlet returns the last 2 system errors from server.

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    #>

    [CmdletBinding()]
    Param(

        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true,Position=1)]
        [Alias('ComputerName')]
        [string]$Name = "$env:COMPUTERNAME",

        [parameter(Position=2)]
        [int]$Newest = 5

    )

    begin{

        $ErrorActionPreference = "Stop"

        $errors = @()

    }

    Process{

        try{
        
            #Gathers system errors. 
            $errors += Get-EventLog -ComputerName $Name -LogName System -EntryType Error -Newest $Newest |
                Select-Object -Property @{n="ComputerName";e={$Name}},TimeWritten,EventID,InstanceID,Message

        }catch{}

    }

    end{

        #Returns array of PS objects with system error information including computer name, time written, 
        #event ID, instance ID, and message.
        $errors | Sort-Object -Property ComputerName | Select-Object -Property ComputerName,TimeWritten,EventID,InstanceID,Message

        return

    }

}

function Get-ComputerInformation{

    <#

    .SYNOPSIS
    Gets infomation about a computer.

    .DESCRIPTION
    This cmdlet gathers infomation about a computer. By default it gathers info from the local host. The information includes computer name, model, 
    CPU, memory in GB, storage in GB, free space in GB, if less than 20 percent of storage is left, the current user, and IP address.

    .PARAMETER Name
    Specifies the computer.

    .INPUTS
    Computer objects with property type "name" or "computername".

    .OUTPUTS
    Returns an object with computer name, model, CPU, memory in GB, storage in GB, free space in GB, if
    less than 20 percent of storage is left, and the current user.

    .NOTES
    Only returns information from computers running Windows 10 or Windows Server 2012 or higher.

    .EXAMPLE
    Get-ComputerInformation -ComputerName Server1

    This returns computer into on Server1.

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    #>

    [CmdletBinding()]
    Param(

        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True,Position=1)]
        [Alias('ComputerName')]
        [string]$Name = $env:COMPUTERNAME

    )

    begin{

        $ErrorActionPreference = "Stop"

        $computerInfoList = @()

    }

    process{

        $computerObjectProperties = @{
            "ComputerName" = "";
            "Model" = "";
            "CPU" = "";
            "MemoryGB" = "";
            "StorageGB" = "";
            "FreeSpaceGB" = "";
            "Under20Percent" = "";
            "CurrentUser" = "";
            "IPAddress" = ""}

        try{
        
            $computerInfo = New-Object -TypeName PSObject -Property $computerObjectProperties

            $computerInfo.computername = $Name

            $computerInfo.model = (Get-CimInstance -ComputerName $Name -ClassName Win32_ComputerSystem -Property Model).model

            $computerInfo.CPU = (Get-CimInstance -ComputerName $Name -ClassName Win32_Processor -Property Name).name

            $computerInfo.memoryGB = [math]::Round(((Get-CimInstance -ComputerName $Name -ClassName Win32_ComputerSystem -Property TotalPhysicalMemory).TotalPhysicalMemory / 1GB),1)

            $computerInfo.storageGB = [math]::Round((((Get-CimInstance -ComputerName $Name -ClassName win32_logicaldisk -Property Size) | 
                Where-Object -Property DeviceID -eq "C:").size / 1GB),1)

            $computerInfo.freespaceGB = [math]::Round((((Get-CimInstance -ComputerName $Name -ClassName win32_logicaldisk -Property Freespace) | 
                Where-Object -Property DeviceID -eq "C:").freespace / 1GB),1)

            if($computerInfo.freespacegb / $computerInfo.storagegb -le 0.2){
                
                $computerInfo.under20percent = "TRUE"

            }else{

                $computerInfo.under20percent = "FALSE"

            }

            $computerInfo.currentuser = (Get-CimInstance -ComputerName $Name -ClassName Win32_ComputerSystem -Property UserName).UserName

            $computerInfo.IPAddress = (Test-Connection -ComputerName $Name -Count 1).IPV4Address

            $computerInfoList += $computerInfo

        }catch{}

    }

    end{

        $computerInfoList | Select-Object -Property ComputerName,Model,CPU,MemoryGB,StorageGB,FreeSpaceGB,Under20Percent,CurrentUser,IPAddress

        return

    }

}

function Get-ComputerSoftware{

    <#

    .SYNOPSIS
    Gets all of the installed software on a computer.

    .DESCRIPTION
    This cmdlet gathers all of the installed software on a computer.  

    .PARAMETER Name
    A list of installed software will be pulled from this computer 

    .INPUTS
    You can pipe input to this cmdlet. PS objects containing "name" or "computername" property.

    .OUTPUTS
    Returns PS objects containing computer name, software name, version, installdate, uninstall 
    command, registry path.

    .NOTES
    Requires remote registry service running on remote machines.

    .EXAMPLE
    Get-ComputerSoftware

    This cmdlet returns all installed software on the local host.

    .EXAMPLE
    Get-ComputerSoftware -ComputerName “Computer”

    This cmdlet returns all the software installed on "Computer".

    .EXAMPLE
    Get-ComputerSoftware -Filter * | GlanceComputerSoftware

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
    
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true,Position=1)]
        [Alias('ComputerName')]
        [string]$Name = $env:COMPUTERNAME
        
    )

    begin{

        $ErrorActionPreference = "Stop"

        $lmKeys = "Software\Microsoft\Windows\CurrentVersion\Uninstall","SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
        $lmReg = [Microsoft.Win32.RegistryHive]::LocalMachine
        $cuKeys = "Software\Microsoft\Windows\CurrentVersion\Uninstall"
        $cuReg = [Microsoft.Win32.RegistryHive]::CurrentUser
        $masterKeys = @()

    }

    process{

        try{

            if((Test-Connection -ComputerName $Name -Count 1 -ErrorAction Stop)){

                $remoteCURegKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($cuReg,$Name)
                $remoteLMRegKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($lmReg,$Name)

                foreach($key in $lmKeys){
                    $regKey = $remoteLMRegKey.OpenSubkey($key)
                    
                    foreach ($subName in $regKey.GetSubkeyNames()){
                    
                        foreach($sub in $regKey.OpenSubkey($subName)){
                    
                            $masterKeys += (New-Object PSObject -Property @{
                                "ComputerName" = $Name;
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

                foreach ($key in $cuKeys){

                    $regKey = $remoteCURegKey.OpenSubkey($key)

                    if($regKey -ne $null){

                        foreach($subName in $regKey.getsubkeynames()){

                            foreach ($sub in $regKey.opensubkey($subName)){

                                $masterKeys += (New-Object PSObject -Property @{
                                    "ComputerName" = $Name;
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

    end{
    
        $woFilter = {$null -ne $_.name -AND $_.SystemComponent -ne "1" -AND $null -eq $_.ParentKeyName}
        $props = 'ComputerName','Name','Version','Installdate','UninstallCommand','RegPath'
        $masterKeys = ($masterKeys | Where-Object $woFilter | Select-Object -Property $props | Sort-Object -Property ComputerName)
        $masterKeys

    }

}

#####################################################################################################################################################
#####################################################################################################################################################

function Get-DiskHealth{

    <#

    .SYNOPSIS
    This script returns the health status of the physical disks on a computer.

    .DESCRIPTION
    This script returns the health status of the physical disks on the local or remote computer.

    .PARAMETER Name
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

        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true,Position=1)]
        [Alias('ComputerName')]
        [string]$Name = $env:COMPUTERNAME

    )

    begin{

        $ErrorActionPreference = "Stop"

        $physicalDisk = @()

    }

    process{

        try{

            $physicalDisk += Get-PhysicalDisk -CimSession $Name | 
                Where-Object -Property HealthStatus | 
                Select-Object -Property @{n="ComputerName";e={$Name}},`
                FriendlyName,MediaType,OperationalStatus,HealthStatus,`
                @{n="SizeGB";e={[math]::Round(($_.Size / 1GB),1)}}

        }catch{}

    }

    end{

        $physicalDisk | Select-Object -Property ComputerName,FriendlyName,MediaType,OperationalStatus,HealthStatus,SizeGB

        Return

    }

}

function Get-DisabledComputer{

}

function Get-DisabledUser{
    
}
function Get-DriveSpace{

    <#

    .SYNOPSIS
    Gathers information for the drives on a computer including computer name, drive, volume, name, 
    size, free space, and indicates those under 20% desc space remaining.

    .DESCRIPTION
    Gathers information for the drives on a computer including computer name, drive, volume, name, 
    size, free space, and indicates those under 20% desc space remaining.

    .PARAMETER Name
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

        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true,Position=1)]
        [Alias('ComputerName')]
        [string]$Name = $env:COMPUTERNAME

    )

    begin{

        $ErrorActionPreference = "Stop"

        $driveSpaceLog = @()

    }

    process{

        try{

            $driveSpaceLog += Get-CimInstance -ComputerName $Name -ClassName win32_logicaldisk -Property deviceid,volumename,size,freespace | 
                Where-Object -Property DeviceID -NE $null | 
                Select-Object -Property @{n="Computer";e={$Name}},`
                @{n="Drive";e={$_.deviceid}},`
                @{n="VolumeName";e={$_.volumename}},`
                @{n="SizeGB";e={$_.size / 1GB -as [int]}},`
                @{n="FreeGB";e={$_.freespace / 1GB -as [int]}},`
                @{n="Under20Percent";e={if(($_.freespace / $_.size) -le 0.2){"True"}else{"False"}}}

        }catch{}

    }

    end{

        #add filter to pull out drives with 0 storage and freespace.
        foreach($drive in $driveSpaceLog){

            if(($drive.SizeGB) -ne 0){



            }

        }

        $driveSpaceLog = $driveSpaceLog | Where-Object -Property SizeGB -NE 0

        $driveSpaceLog | Select-Object -Property Computer,Drive,VolumeName,SizeGB,FreeGB,Under20Percent

        return

    }  

}

function Get-FailedLogon{

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
    Glance-ADFailedLogon

    Returns failed logon events from all computers in the domain.

    .EXAMPLE
    Glance-ADFailedLogon -searchOU "Servers"

    Returns failed logon events from all computers in the "Servers" OU.

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    #>

    [CmdletBinding()]
    Param(

        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true,Position=1)]
        [Alias('ComputerName')]
        [string]$Name = $env:COMPUTERNAME,

        [int]$DaysBack = 1

    )

    begin{

        $ErrorActionPreference = "Stop"

        $failedLoginLog = @()

    }

    process{
        
        try{

            $failedLogin = Get-EventLog -ComputerName $Name -LogName Security -InstanceId 4625 -After ((Get-Date).AddDays($DaysBack * -1)) |
                Select-Object -Property @{n="ComputerName";e={$Name}},TimeWritten,EventID

            $failedLoginLog += $failedLogin

        }catch{}
        
    }

    end{

        #Returns an array of PS objects with failed logon events.
        $failedLoginLog | Select-Object -Property ComputerName,TimeWritten,EventID

        return

    }

}

function Get-ComputerLastLogon{

    <#

    .SYNOPSIS
    This cmdlet returns the last time a computer was connected to an AD network.

    .DESCRIPTION
    
    .PARAMETER Name
    
    .INPUTS
    None.

    .OUTPUTS
    PS object with computer name and the last time is was connected to the domain.

    .NOTES
    None.

    .EXAMPLE
    Get-ComputerLastLogon

    .LINK
    By Ben Peterson
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

    #>

    [CmdletBinding()]
    Param(

        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true,Position=1)]
        [Alias('ComputerName')]
        [string]$Name = $env:COMPUTERNAME

    )

    begin{

        $ErrorActionPreference = "Stop"
        
        $lastLogonList = @()

    }

    process{

        $computer = Get-ADComputer $Name | Get-ADObject -Properties lastlogon

        $lastLogonProperties = @{
        
            "Last Logon" = ([datetime]::fromfiletime($computer.lastlogon));
        
            "Computer" = ($computer.name)
        
        }

        $lastLogonObject = New-Object -TypeName PSObject -Property $lastLogonProperties
        
        $lastLogonList += $lastLogonObject
        
    }

    end{

        #Returns an array of PS objects with the computer name and last logon date.
        $lastLogonList

        return

    }

}

function Get-UserLastLogon{

    <#

    .SYNOPSIS
    This cmdlet returns the last time a user logged onto the domain.

    .DESCRIPTION
    Returns a list of all the users in AD that have not been online a number of months. The default
    amount of months is 6. Can be set by the user by passing a value to MonthsOld.

    .PARAMETER Name

    .INPUTS

    .OUTPUTS
    PS objects with user name and last logon date.

    .NOTES
    None.

    .EXAMPLE
    Get-UserLastLogon

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    #>

    [cmdletbinding()]
    param(

        [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true,Position=1)]
        [string]$Name

    )

    begin{

        $lastLogonList = @()

    }

    process{

        $user = Get-ADUser -Identity $Name | Get-ADObject -Properties lastlogon | 
            Select-Object -Property lastlogon,name 

        $lastLogonProperties = @{
            "LastLogon" = ([datetime]::fromfiletime($user.lastlogon));
            "User" = ($user.name)
        }

        $lastLogonObject = New-Object -TypeName PSObject -Property $lastLogonProperties
        
        $lastLogonList += $lastLogonObject
        
    }

    end{

        #Returns an array of PS objects with user name and last logon dates.
        $lastLogonList | Select-Object -Property User,LastLogon

        return

    }

}