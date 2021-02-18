<#
This module is meant to be used in a Windows Domain by a domain administrator.

By:
Ben Peterson
linkedin.com/in/benponline
github.com/benponline
twitter.com/benponline
paypal.me/teknically
#>

function Add-DHCPReservation{
    <#
    .SYNOPSIS
    Adds a reservation in DHCP for a computer.

    .DESCRIPTION
    This function adds an IPv4 reservation for a computer in all DHCP servers in a domain.

    .PARAMETER ComputerName
    Name of the computer that will get a reservation in DHCP.

    .PARAMETER IPAddress
    IP address of the reservation made in DHCP.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .NOTES
    This function is meant to be used in a domain with one DHCP scope.

    This function will attempt to add the reservation to each DHCP server in the domain.

    The target computer will not get the new address immediately if it does not already use that IP. 
    
    You can create a reservation with an IP that is currently leased to another computer. You will need to manually trigger an IP change in the computer currently holding the IP, then in the computer getting the new reservation. The computer in the reservation will then be using the assigned IP.
    
    You can allow the DHCP servers to naturally renew their leases over time. Eventually the computer will get the IP assigned to it in the reservation.

    If a reservation with the computer or IP address passed to the function already exists, then the function will stop and notify you which DHCP server it is located on. 

    .EXAMPLE
    Add-DHCPReservation -ComputerName "Computer1" -IPAddress 10.10.10.123

    This will create a reservation in all available DHCP servers in a domain for the computer name passed to it for the IP address passed to it.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,

        [Parameter(Mandatory=$true)]
        [string]$IPAddress
    )

    $dhcpServers = (Get-DhcpServerInDC).DnsName
    $hostName = (Get-ADComputer -Identity $ComputerName).DNSHostName

    foreach($server in $dhcpServers){
        $dhcpServer = $server.split(".")[0]
        $scopeId = (Get-DhcpServerv4Scope -ComputerName $dhcpServer | Select-Object -First 1).ScopeId
        $reservations = Get-DhcpServerv4Reservation -ScopeId $scopeId -ComputerName $dhcpServer

        # Check for reservations that already contain the host name or ip address passed to the funciton.
        foreach($r in $reservations){
            if($r.Name -EQ $hostName){
                return "The computer $hostName already has a reservation on $dhcpServer"
            }

            if($r.IPAddress -EQ $IPAddress){
                return "The IP address $IPAddress already has a reservation on $dhcpServer"
            }

        }
    }

    foreach($server in $dhcpServers){
        $dhcpServer = $server.split(".")[0]
        $scopeId = (Get-DhcpServerv4Scope -ComputerName $dhcpServer | Select-Object -First 1).ScopeId
        $dhcpLeases = Get-DhcpServerv4Lease -ComputerName $dhcpServer -ScopeId $scopeId -AllLeases
        $clientId = ($dhcpLeases | Where-Object -Property HostName -EQ $hostName | Select-Object -First 1).ClientId

        Add-DhcpServerv4Reservation -ScopeId $scopeId -ComputerName $dhcpServer -IPAddress $IPAddress -ClientId $clientId
    }
}

function Disable-Computer{
    <#
    .SYNOPSIS
    Disables a computer.

    .DESCRIPTION
    Disables a computer or group of computers by passing host names or computer AD objects to this function. 

    .PARAMETER Name
    This is the host name of the computer that will be disable.

    .INPUTS
    Computer AD objects can be passed to this function from the pipeline.

    .OUTPUTS
    An array of computer AD objects. One for each computer that this function disables.

    .NOTES

    .EXAMPLE 
    Disable-Computer -Name "Computer1"

    Disables the computer named "Computer1" in Active Directory.

    .EXAMPLE
    "Computer1","Computer2" | Disable-Computer

    Disables computers Computer1 and Computer2 in Active Directory.

    .EXAMPLE
    Get-ADComputer Computer1 | Disable-Computer

    Disables Computer1 in Active Directory.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true,Mandatory=$True)]
        [Alias('ComputerName')]
        [string]$Name
    )

    begin{
        $disabledComputers = @()
    }

    process{
        $computer = Get-ADComputer $Name
        $computer | Disable-ADAccount

        #Updates computer object to show disabled status.
        Start-Sleep -Seconds 1
        $computer = Get-ADComputer $Name
        $disabledComputers += $computer
    }

    end{
        return $disabledComputers
    }
}

function Disable-User{
    <#
    .SYNOPSIS
    User Disables a user.

    .DESCRIPTION
    Disables a user or group of users by passing SamAccountNames or user AD objects to this funtion. 

    .PARAMETER SamAccountName
    This is the user name of the user that will be disabled.

    .INPUTS
    User AD objects can be passed to this function.

    .OUTPUTS
    An array of user AD objects. One for each user that this function disables.

    .NOTES

    .EXAMPLE 
    Disable-User -Name "User1"

    Disables the user named User1 in Active Directory.

    .EXAMPLE
    "User1","User2" | Disable-User

    Disables users User1 and User2 in Active Directory.

    .EXAMPLE
    Get-ADUser "User1" | Disable-User

    Disables User1 in Active Directory.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true,Mandatory=$True)]
        [string]$SamAccountName
    )

    begin{
        $disabledUsers = @()
    }

    process{
        $user = Get-ADUser $SamAccountName
        $user | Disable-ADAccount

        #Gets updated AD user object to pass back to the host.
        Start-Sleep -Seconds 1
        $user = Get-ADUser $SamAccountName
        $disabledUsers += $user
    }

    end{
        return $disabledUsers
    }
}

function Enable-WakeOnLan{
    <#
    .SYNOPSIS
    Configures a computer to allow wake on lan.
    
    .DESCRIPTION
    Configures a computer's ethernet network adapter to respond to wake on lan commands. This allow the computer to be turned on while it is shut down. 
    
    .PARAMETER Name
    Target computer's host name.

    .INPUTS
    Computer AD objects

    .OUTPUTS
    None.

    .NOTES
    This function needs to be run against a computer before you can be sure that the Start-Computer function in the PSSystemAdministrator modile will work.

    .EXAMPLE
    Enable-WakeOnLan -Name 'Computer1'

    Sets the network adapter on 'Computer1' to respond to WOL commands and boot from a shutdown state.

    .EXAMPLE
    'Computer1','Computer2' | Enable-WakeOnLan

    Sets the network adapters on 'Computer1' and 'Computer2' to respond to WOL commands and boot from a shutdown state.

    .EXAMPLE
    Get-OUComputer -OrganizationalUnit 'Department X' | Enable-WakeOnLan

    Sets the network adapters on all computers in the 'Department X' OU to respond to WOL commands and boot from a shutdown state.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    Based on: https://docs.microsoft.com/en-us/powershell/module/netadapter/enable-netadapterpowermanagement
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [Alias("ComputerName")]
        [string]$Name
    )

    begin{
        $domainController = (Get-ADDomainController).Name
        $scopeID = (Get-DhcpServerv4Scope -ComputerName $domainController).ScopeID
    }

    process{
        $cimSession = New-CimSession -ComputerName $Name
        $computerMAC = (Get-DhcpServerv4Lease -ComputerName $domainController -ScopeId $scopeID | Where-Object -Property hostname -match $Name).clientid
        $adapterName = (Get-NetAdapter -CimSession $cimSession | Where-Object -Property MacAddress -match $computerMAC).Name
        Enable-NetAdapterPowerManagement -CimSession $cimSession -Name $adapterName -WakeOnMagicPacket
    }

    end{}
}

function Get-AccessedFile{
    <#
    .SYNOPSIS
    Gets all files in a directory that have been accessed in the last 24 hours.
    
    .DESCRIPTION
    Gets all files in a directory recursively that have been accessed less than a day ago. Directory and days in the past can be adjusted.
    
    .PARAMETER Path
    Function will gather all files recursively from the directory at the end of the path.

    .PARAMETER Days
    Function will return only files that have been accessed this number of days into the past.

    .INPUTS
    You can pipe multiple paths to this function.
    
    .OUTPUTS
    Array of PS objects that includes file Name, LastAccessTme, SizeMB, and FullName.
    
    .NOTES

    .EXAMPLE
    Get-AccessedFile -Path "C:\Directory1" -Days

    Gets all files recursively in the "Directory1" folder that have been accessed within 5 days.

    .EXAMPLE
    "C:\Directory1","C:\Directory2" | Get-AccessedFile

    Gets all files recursively in the "Directory1" and "Directory2" folders that have been accessed in the last day.
    
    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true,Mandatory=$True)]
        [Alias('FullName')]
        [string]$Path,
        [int]$Days = 1
    )

    begin{
        $files = @()
        $fileAge = (Get-Date).AddDays(-1 * $Days)
    }

    process{
        $files += Get-ChildItemLastAccessTime -Path $Path | 
            Where-Object -Property LastAccessTime -GT $fileAge
    }

    end{
        return $files
    }
}

function Get-ActiveComputer{
    <#
    .SYNOPSIS
    Gets a list of computers that have logged onto the domain in the last 30 days.

    .DESCRIPTION
    Gets a list of computers from Active Directory that have logged onto the domain in the last 30 days. By default all computers are checked, but can be limited to a specific organizational unit. Days inactive can be adjusted.

    .PARAMETER Days
    Sets how recently in days the computer account has to be active for it to be returned.

    .PARAMETER OrganizationalUnit
    Limits the function to a specific organizational unit.

    .INPUTS
    None.

    .OUTPUTS
    Computer AD object for each computer returned.

    .NOTES

    .EXAMPLE
    Get-ActiveComputer

    Lists all computers in the domain that have been online in the last 30 days.

    .EXAMPLE
    Get-ActiveComputer -Days 100

    Lists all computers in the domain that have been online in the last 100 days.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [CmdletBinding()]
    Param(
        [int]$Days = 30,
        [string]$OrganizationalUnit = ""
    )

    if($OrganizationalUnit -eq ""){
        $computers = Get-ADComputer -Filter * | 
            Get-ComputerLastLogonTime | 
            Where-Object -Property LastLogon -GT ((Get-Date).AddDays(($Days * -1)))
    }else{
        $computers = Get-OUComputer -OrganizationalUnit $OrganizationalUnit | 
            Get-ComputerLastLogonTime |
            Where-Object -Property LastLogon -GT ((Get-Date).AddDays(($Days * -1)))
    }

    return $computers
}

function Get-ActiveFile{
    <#
    .SYNOPSIS
    Gets all files in a directory that have been written in the last 24 hours.
    
    .DESCRIPTION
    Gets all files in a directory recursively that have been written to going back one day. Path and days back can be adjusted.
    
    .PARAMETER Path
    Sets directory the function returns files from.

    .PARAMETER Days
    Sets how recently, in days, the file has been written to.

    .INPUTS
    You can pipe multiple paths to this function.
    
    .OUTPUTS
    Array of PS objects that includes file Name, LastWriteTime, SizeMB, and FullName.
    
    .NOTES

    .EXAMPLE
    Get-ActiveFile -Path "C:\Directory1" -Days 5

    Gathers all files recursively in the "Directory1" folder that have been written to within 5 days.

    .EXAMPLE
    "C:\Directory1","C:\Directory2" | Get-ActiveFile

    Gathers all files recursively in the "Directory1" and "Directory2" folders that have been written to in the last day.
    
    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true,Mandatory=$True)]
        [string]$Path,
        [int]$Days = 1
    )

    begin{
        $files = @()
        $fileAge = (Get-Date).AddDays(-1*$Days)
    }

    process{
        $files += Get-ChildItemLastWriteTime -Path $Path | 
            Where-Object -Property LastWriteTime -GT $fileAge
    }

    end{
        return $files
    }
}

function Get-ActiveUser{
    <#
    .SYNOPSIS
    Gets a list of all users that have logged on in the last 30 days.

    .DESCRIPTION
    Gets a list of all users in active directory that have logged on in the last 30 days. Days and Organizational Unit can be adjusted.

    .PARAMETER Days
    Sets how long the user account has to be inactive for it to be returned.

    .PARAMETER OrganizationalUnit
    Focuses the function on a specific AD organizational unit.

    .INPUTS
    None.

    .OUTPUTS
    PS objects with user names and last logon date.

    .NOTES
    Function is intended to help find inactive user accounts.

    .EXAMPLE
    Get-ActiveUser

    Lists all users in the domain that have not checked in for more than 3 months.

    .EXAMPLE
    Get-ActiveUser -Days 2

    Lists all users in the domain that have not checked in for more than 2 days.

    .EXAMPLE
    Get-ActiveUser -Days 45 -OrganizationalUnit "Company Servers"

    Lists all users in the domain that have not checked in for more than 45 days in the "Company Servers" organizational unit.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [CmdletBinding()]
    Param(
        [int]$Days = 30,
        [string]$OrganizationalUnit = ""
    )

    if($OrganizationalUnit -eq ""){
        $users = Get-ADUser -Filter * | 
            Get-UserLastLogonTime |
            Where-Object -Property LastLogon -GT ((Get-Date).AddDays($Days * -1))
    }else{
        $users = Get-OUUser -OrganizationalUnit $OrganizationalUnit | 
            Get-UserLastLogonTime |
            Where-Object -Property LastLogon -GT ((Get-Date).AddDays($Days * -1))
    }

    return $users
}

function Get-ChildItemLastAccessTime{
    <#
    .SYNOPSIS
    Gets all files in a directory and returns information including file name and last access time.
    
    .DESCRIPTION
    Gets all files in a directory recursively and returns file name, last access time, size in MB, and full name.
    
    .PARAMETER Path
    Function will gather all files recursively from this directory.

    .INPUTS
    You can pipe multiple paths to this function.
    
    .OUTPUTS
    Array of PS objects that includes FileNames, LastAccessTime, SizeMB, and FullName.
    
    .NOTES

    .EXAMPLE
    Get-ChildItemLastAccessTime -Path "C:\Directory1"

    Gathers  information on all files recursively in the "Directory1" directory.

    .EXAMPLE
    "C:\Directory1","C:\Directory2" | Get-ChildItemLastAccessTime

    Gathers all files recursively in the "Directory1" and "Directory2" folders.
    
    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true,Mandatory=$True)]
        [string]$Path
    )

    begin{
        $files = @()
    }

    process{
        $files += Get-ChildItem -Path $Path -File -Recurse | 
            Select-Object -Property Name,LastAccessTime,@{n='SizeMB';e={[math]::Round(($_.Length/1MB),3)}},FullName
    }

    end{
        return $files
    }
}

function Get-ChildItemLastWriteTime{
    <#
    .SYNOPSIS
    Gets all files in a directory and returns information including last write time.
    
    .DESCRIPTION
    This function gathers all files in a directory recursively. Returns file name, last write time, size in MB, and full name.
    
    .PARAMETER Path
    Function will gather all files recursively from this directory.

    .INPUTS
    None.
    
    .OUTPUTS
    Array of PS objects that includes file Name, LastWriteTime, SizeMB, and FullName.
    
    .NOTES

    .EXAMPLE
    Get-ChildItemLastWriteTime -Path "C:\Directory1"

    Gathers all files recursively in the "Directory1" folder and returns file names, last write time, size in MB, and full name.

    .EXAMPLE
    "C:\Directory1","C:\Directory2" | Get-ChildItemLastWriteTime

    Gathers all files recursively in the "Directory1" and "Directory2" folders.
    
    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>    

    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true,Mandatory=$True)]
        [string]$Path
    )

    begin{
        $files = @()
    }

    process{
        $files += Get-ChildItem -Path $Path -File -Recurse |
            Select-Object -Property Name,LastWriteTime,@{n='SizeMB';e={[math]::Round(($_.Length/1MB),3)}},FullName
    }

    end{
        return $files
    }
}

function Get-ComputerCurrentUser{
    <#
    .SYNOPSIS
    Gets the current user logged onto a computer.

    .DESCRIPTION
    Gets the currently logged in user on a computer or computers. 

    .PARAMETER Name
    The host name of the computer that the current user will be returned from.

    .INPUTS
    An array of host names or AD Computer objects.

    .OUTPUTS
    Returns a PS Object with the computer Name and CurrentUser.

    .NOTES

    .EXAMPLE
    Get-ComputerCurrentUser

    Gets the current user on the local computer.

    .EXAMPLE
    Get-ComputerCurrentUser -Name 'Computer1'

    Gets the current logged on user from 'Computer1'.

    .EXAMPLE
    'Computer1','Computer2' | Get-ComputerCurrentUser

    Returns the current logged on user from 'Computer1' and 'Computer2'.

    .EXAMPLE
    Get-OUComputer -OrganizationalUnit 'Department X' | Get-ComputerCurrentUser

    Returns the current logged on users for all computer in the 'Deparment X' Active Directory organizational unit. Get-OUComputer is a function from the PSSystemAdministrator module.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('ComputerName')]
        [string]$Name = $env:COMPUTERNAME
    )

    begin{
        $computerUserList = @()
    }

    process{
        $currentUser = (Get-CimInstance -ComputerName $Name -ClassName Win32_ComputerSystem).UserName

        if(!$null -eq $currentUser){
            $currentUser = $currentUser.split('\')[-1]
        }else{
            $currentUser = ""
        }

        $computerUserList += [PSCustomObject]@{
            ComputerName = $Name;
            UserName = $currentUser
        }
    }

    end{
        return $computerUserList
    }
}

function Get-ComputerDriveInformation{
    <#
    .SYNOPSIS
    Gets information about the drives on a computer.

    .DESCRIPTION
    Returns information about the drives on a computer or group of computers. The information includes computer name, drive, volume name, size, free space, and if the drive has less than 20% space left.

    .PARAMETER Name
    Specifies the computer the function will gather information from.

    .INPUTS
    You can pipe host names or AD computer objects.

    .OUTPUTS
    Returns PS objects to the host the following information about the drives on a computer: Name, DeviceID, VolumeName,SizeGB, FreeGB, and indicates those under 20% desc space remaining.

    .NOTES
    Compatible with Window 7 and newer.

    Results include mapped drives.

    .EXAMPLE
    Get-ComputerDriveInformation

    Gets drive information for the local host.

    .EXAMPLE
    Get-ComputerDriveInformation -Name computer

    Gets ddrive information for "computer".

    .EXAMPLE
    Get-ADComputer -Filter * | Get-ComputerDriveInformation

    Gets drive information for all computers in AD.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [Alias('ComputerName')]
        [string]$Name = $env:COMPUTERNAME
    )

    begin{
        $driveInformationList = @()
    }

    process{
        $driveInformationList += Get-CimInstance -ComputerName $Name -ClassName win32_logicaldisk -Property DeviceID,VolumeName,Size,FreeSpace,DriveType | 
            Where-Object -Property DriveType -EQ 3 | 
            Select-Object -Property @{n="Computer";e={$Name}},`
            @{n="DeviceID";e={$_.deviceid}},`
            @{n="VolumeName";e={$_.volumename}},`
            @{n="SizeGB";e={$_.size / 1GB -as [int]}},`
            @{n="FreeGB";e={$_.freespace / 1GB -as [int]}},`
            @{n="Under20Percent";e={if(($_.freespace / $_.size) -le 0.2){"True"}else{"False"}}}
    }

    end{
        $driveInformationList = $driveInformationList | Where-Object -Property SizeGB -NE 0
        return $driveInformationList
    }  
}

function Get-ComputerFailedLogonEvent{
    <#
    .SYNOPSIS
    Gets failed logon events from a computer in the last day.

    .DESCRIPTION
    Gets failed logon events from a computer or computers in the last day. Can adjust how far back in days events are returned.

    .PARAMETER Name
    Host name of the computer events will be returned from.

    .PARAMETER Days
    Sets how far back in days the function will look for failed logon events.

    .INPUTS
    Computer AD objects.

    .OUTPUTS
    PS objects for computer failed logon events with Computer, TimeWritten, EventID, InstanceId, and Message.

    .NOTES
    Requires administrator privilages.

    Requires "Printer and file sharing", "Network Discovery", and "Remote Registry" to be enabled on computers that are searched. This funtion can take a long time to complete if more than 5 computers are searched.

    .EXAMPLE
    Get-ComputerFailedLogonEvent

    This cmdlet returns the last 5 system errors from localhost.

    .EXAMPLE
    Get-ComputerFailedLogonEvent -Name "Server" -Days 2

    This function returns the last 2 days of failed logon events from Server.

    .EXAMPLE
    "computer1","computer2" | Get-ComputerFailedLogonEvent

    This function returns failed logon events from "computer1" and "computer2" in the last day.

    .EXAMPLE
    Get-ADComputer "Computer1" | Get-ComputerFailedLogonEvent

    This cmdlet returns failed logon event from the last day from Computer1.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    Made with help from: https://theposhwolf.com/howtos/Get-ADUserBadPasswords
    #>

    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [Alias('ComputerName')]
        [string]$Name = "$env:COMPUTERNAME",
        [int]$DaysBack = 1
    )

    begin{
        $failedLogonList = @()
        $date = (Get-Date).AddDays($DaysBack * -1)

        $logonTypeDictionary = @{
            '2' = 'Interactive'
            '3' = 'Network'
            '4' = 'Batch'
            '5' = 'Service'
            '7' = 'Unlock'
            '8' = 'Networkcleartext'
            '9' = 'NewCredentials'
            '10' = 'RemoteInteractive'
            '11' = 'CachedInteractive'
        }
    }

    process{
        $failedLogonsRaw = Get-WinEvent -ComputerName $Name -FilterHashtable @{LogName='Security';ID=4625; StartTime=$date}
            
        for($i = 0; $i -lt $failedLogonsRaw.Count; $i++){
            $logonTypeNumber = $failedLogonsRaw[$i].Properties[10].Value

            $failedLogonList += [PSCustomObject]@{
                Computer = $Name;
                Account = $failedLogonsRaw[$i].Properties[5].Value;
                AccountDomain = $failedLogonsRaw[$i].Properties[6].Value;
                LogonType = $logonTypeDictionary["$logonTypeNumber"];
                TimeCreated = $failedLogonsRaw[$i].TimeCreated
            }
        }
    }

    end{
        return $failedLogonList
    }
}

function Get-ComputerInformation{
    <#
    .SYNOPSIS
    Gets general information about a computer.

    .DESCRIPTION
    This function gathers information about a computer or computers. By default it gathers info from the local host.

    .PARAMETER Name
    Specifies which computer's information is gathered.

    .INPUTS
    You can pipe host names or AD computer objects.

    .OUTPUTS
    Returns an object with computer Name, Model, Processor, MemoryGB, CDriveGB, CurrentUser, IPAddress, LastBootupTime, and LastLogonTime.

    .NOTES
    Compatible for Windows 7 and newer.

    Only returns information from computers running Windows 10 or Windows Server 2012 or higher.

    Will not return information on computers that are offline.

    .EXAMPLE
    Get-ComputerInformation

    Returns computer information for the local host.

    .EXAMPLE
    Get-ComputerInformation -Name "Server1"

    Returns computer information for Server1.

    .EXAMPLE
    Get-ADComputer -filter * | Get-ComputerInformation

    Returns computer information on all AD computers. 

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('ComputerName')]
        [string]$Name = $env:COMPUTERNAME
    )

    begin{
        $computers = [System.Collections.Generic.List[string]]::new()        
        $computerInfoList = [System.Collections.Generic.List[psobject]]::new()
    }

    process{
        $computers.Add($Name)
    }

    end{
        $computers | ForEach-Object -Parallel {
            if(Test-Connection -ComputerName $_ -Count 1 -Quiet){
                New-Object -TypeName PSObject -Property @{
                Name = $_;
                Model = (Get-ComputerModel -Name $_).Model;
                Processor = (Get-ComputerProcessor -Name $_).Processor;
                MemoryGB = (Get-ComputerMemory -Name $_).MemoryGB;
                CDriveGB = (Get-ComputerDriveInformation -Name $_ | Where-Object -Property DeviceID -Match 'C').SizeGB;
                CurrentUser = (Get-ComputerCurrentUser -Name $_).UserName;
                IPAddress = (Get-ComputerIPAddress -Name $_).IPAddress;
                LastBootupTime = (Get-ComputerLastBootUpTime -Name $_).LastBootupTime;
                LastLogon = ""
                }
            }
        } | ForEach-Object {$computerInfoList.Add($_)}
        
        #Get-ComputerLastLogonTime did not work consistantly inside of Foreach-Object.
        foreach($computer in $computerInfoList){
            if(Test-Connection -ComputerName $computer.Name -Count 1 -Quiet){
                $computer.LastLogon = (Get-ComputerLastLogonTime -Name $computer.Name).LastLogon
            }
        }

        return $computerInfoList
    }
}

function Get-ComputerIPAddress{
    <#
    .SYNOPSIS
    Gets the IPv4 address of a computer.

    .DESCRIPTION
    Gets the IPv4 address of a computer or computers.

    .PARAMETER Name
    Target computer's host name.

    .INPUTS
    This function takes an array of host names or AD computer objects.

    .OUTPUTS
    Returns an array of PS Objects with computer Name and IPAddress.

    .NOTES

    .EXAMPLE
    Get-ComputerIPAddress

    Returns a PS Object with the local computer's name and IPv4 address.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('ComputerName')]
        [string]$Name = $env:COMPUTERNAME
    )

    begin{
        $computerIPList = @()
    }

    process{
        $computerIPList += [PSCustomObject]@{
            Name = $Name;
            IPAddress = (Resolve-DnsName -Type A -Name $Name).IPAddress
        }
    }

    end{
        return $computerIPList
    }
}

function Get-ComputerLastBootUpTime{
    <#
    .SYNOPSIS
    Gets the last time a computer booted up.

    .DESCRIPTION
    Gets the name and last time a computer or computers booted up. By default targets localhost.
    
    .PARAMETER Name
    Target computer's host name.

    .INPUTS
    Can pipe host names or AD computer objects to function.

    .OUTPUTS
    PS object with computer Name and LastBootupTime.

    .NOTES
    Compatible with Windows 7 and newer.

    .EXAMPLE
    Get-ComputerLastBootupTime

    Returns the last time the local host booted up.

    .EXAMPLE
    Get-ComputerLastBootupTime -Name "Borg"

    Returns the last time the computer "Borg" booted up.

    .EXAMPLE
    "Computer1","Computer2" | Get-ComputerLastBootupTime

    Returns last bootup time for "Computer1" and "Computer2".

    .EXAMPLE
    Get-OUComputer -OrganizationalUnit 'Department X' | Get-ComputerLastBootupTime

    Returns the last bootup time of all the computers in the 'Department X' organizational unit.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [Alias('ComputerName')]
        [string]$Name = $env:COMPUTERNAME
    )

    begin{
        $lastBootUpTimeList = @()
    }

    process{
        $lastBootUpTimeList += Get-CimInstance -ComputerName $Name -Class Win32_OperatingSystem -Property LastBootUpTime | 
            Select-Object -Property @{n='Name';e={$_.pscomputername}},LastBootUpTime
    }

    end{
        return $lastBootUpTimeList
    }
}

function Get-ComputerLastLogonTime{
    <#
    .SYNOPSIS
    Gets the last time a computer logged onto the domain.

    .DESCRIPTION
    Gets the last time a computer or group of computers logged onto the domain. By default gets the last logon time for the local computer.

    .PARAMETER Name
    Target computer.

    .INPUTS
    You can pipe computer names and computer AD objects to this function.

    .OUTPUTS
    PS objects with computer Name and LastLogonTime.

    .NOTES
    None.

    .EXAMPLE
    Get-ComputerLastLogonTime -Name "Computer1"

    Returns the last time 'Computer1" logged into the domain.

    .EXAMPLE
    Get-ADComputer -Filter * | Get-ComputerLastLogonTime

    Gets the last time all computers in AD logged onto the domain.

    .EXAMPLE
    'Computer1','Computer2' | Get-ComputerLastLogonTime

    Returns the last logon time for 'Computer1' and 'Computer2'.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [string]$Name = $env:ComputerName
    )

    begin{
        $lastLogonList = @()

        #When looking for AD computer LastLogon we need to check all domain controllers because this information is not synced between them.
        $domainControllers = (Get-ADDomainController -Filter *).Name
    }

    process{
        $dcCount = $domainControllers.Count
        
        if($dcCount -eq 1){
            $lastLogonList += Get-ADComputer $Name | 
                Get-ADObject -Properties LastLogon | 
                Select-Object -Property @{n="Name";e={$Name}},@{n="LastLogon";e={([datetime]::fromfiletime($_.LastLogon))}}
        }else{
            $lastLogonTime = Get-ADComputer $Name -Server $domainControllers[0] | 
                Get-ADObject -Properties LastLogon | 
                Select-Object -Property @{n="Name";e={$Name}},@{n="LastLogon";e={([datetime]::fromfiletime($_.LastLogon))}}
                
            for($i = 1; $i -LT $dcCount; $i++){
                $nextlogonTime = Get-ADComputer $Name -Server $domainControllers[$i] | 
                    Get-ADObject -Properties LastLogon | 
                    Select-Object -Property @{n="Name";e={$Name}},@{n="LastLogon";e={([datetime]::fromfiletime($_.LastLogon))}}


                if($nextlogonTime.LastLogon -GT $lastLogonTime.LastLogon){
                    $lastLogonTime = $nextlogonTime
                }
            }
            
            $lastLogonList += $lastLogonTime
        }
    }

    end{
        return $lastLogonList
    }
}

<# Draft - Function returns drives inconsistantly.
function Get-ComputerMappedNetworkDrive{
    
    .SYNOPSIS
    Gets information about the mapped drives on a computer or computers.

    .DESCRIPTION
    Returns information from about the mapped drives on a computer, remote computer, or group of computers. The information includes computer name, drive, volume name, size, free space, and if the drive has less than 20% space left.

    .PARAMETER Name
    Specifies the computer the function will gather information from.

    .INPUTS
    You can pipe host names or AD computer objects.

    .OUTPUTS
    Returns PS objects to the host the following information about the mapped drives on a computer: computer name, drive, volume name, size, free space, and indicates those under 20% desc space remaining.

    .NOTES
    Compatible with Window 7 and newer.

    Will only try to contact computers that are on and connected to the network.

    .EXAMPLE
    Get-ComputerMappedNetworlDrive

    Gets mapped drive information for the local host.

    .EXAMPLE
    Get-MappedNetworlDrive -computerName computer

    Gets mapped drive information for "computer".

    .EXAMPLE
    Get-DriveInformation -Filter * | Get-DriveSpace

    Gets mapped drive information for all computers in AD.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    

    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [Alias('ComputerName')]
        [string]$Name = "$env:COMPUTERNAME"
    )

    begin{
        $mappedDrives = @()
    }

    process{

        if(Test-Connection $Name -Count 1 -Quiet){
            $mappedDrives += Get-CimInstance -ComputerName $Name -ClassName win32_mappedlogicaldisk -Property DeviceID,VolumeName,Size,FreeSpace,ProviderName | 
                Select-Object -Property @{n="Computer";e={$Name}},`
                @{n="Drive";e={$_.DeviceID}},`
                @{n="VolumeName";e={$_.VolumeName}},`
                @{n="Path";e={$_.ProviderName}},`
                @{n="SizeGB";e={$_.Size / 1GB -as [int]}},`
                @{n="FreeGB";e={$_.FreeSpace / 1GB -as [int]}},`
                @{n="Under20Percent";e={if(($_.FreeSpace / $_.Size) -le 0.2){"True"}else{"False"}}}
        }
    }

    end{
        return $mappedDrives
    }
}
#>

function Get-ComputerMemory{
    <#
    .SYNOPSIS
    Gets the memory in GB of a computer.

    .DESCRIPTION
    Gets the memory in GB of a computer or group of computers. 

    .PARAMETER Name
    Target comuputer's host name. By defualt it is the local computers.

    .INPUTS
    Takes an array of computer names or AD computer objects over the pipeline.

    .OUTPUTS
    Returns PS Object/s of the computers passed to it including computer name and memory in GB.

    .NOTES

    .EXAMPLE
    Get-ComputerMemory -Name 'computer1'

    Returns a PS Object with the computer name and memory in GB of the 'Computer1'.

    .EXAMPLE
    'computer1','computer2' | Get-ComputerMemory
    
    Returns a PS Object for each computer containing computer name and memory in GB.

    .EXAMPLE
    Get-OUComputer -OrhanizationalUnit 'Department X' | Get-ComputerMemory

    Returns a PS Object for each computer in the 'Department X' Active Directory organizational unit containing computer name and memory in GB.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('ComputerName')]
        [string]$Name = $env:COMPUTERNAME
    )

    begin{
        $computerMemories = @()
    }

    process{

        if(Test-Connection -TargetName $Name -Count 1 -Quiet){
            Write-Verbose -Message "Connecting to $Name."

            $computerMemories += [PSCustomObject]@{
                Name = $Name;
                MemoryGB = [math]::Round(((Get-CimInstance -ComputerName $Name -ClassName Win32_ComputerSystem -Property TotalPhysicalMemory).TotalPhysicalMemory / 1GB),1)
            }
        }else{
            Write-Verbose -Message "$Name is offline."
        }
    }

    end{
        return $computerMemories
    }
}

function Get-ComputerModel{
    <#
    .SYNOPSIS
    Gets the model of a computer.

    .DESCRIPTION
    Gets the model of a computer or group of computers. 

    .PARAMETER Name
    The model of the computer with this name will be returned. By defualt it is the local computers.

    .INPUTS
    Takes an array of computer names or AD computer objects over the pipeline.

    .OUTPUTS
    Returns PS Object/s of the computers passed to it including computer name and model.

    .NOTES

    .EXAMPLE
    Get-ComputerModel -Name 'computer1'

    Returns a PS Object with the computer name and model of the 'Computer1'.

    .EXAMPLE
    'computer1','computer2' | Get-ComputerModel
    
    Returns a PS Object for each computer containing computer name and model.

    .EXAMPLE
    Get-OUComputer -OrhanizationalUnit 'Department X' | Get-ComputerModel

    Returns a PS Object for each computer in the 'Department X' Active Directory organizational unit containing computer name and model.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('ComputerName')]
        [string]$Name = $env:COMPUTERNAME
    )

    begin{
        $computerModels = @()
    }

    process{
        $computerModels += Get-CimInstance -ComputerName $Name -ClassName Win32_ComputerSystem -Property Model | Select-Object -Property @{n='Name';e={$Name}},@{n='Model';e={$_.Model}}
    }

    end{
        return $computerModels
    }
}

function Get-ComputerOS{
    <#
    .SYNOPSIS
    Gets the operating system name of a computer.

    .DESCRIPTION
    Gets the Windows operating system of the local host or remote computer. Does not return build number or any other detailed info.
    
    .PARAMETER Name
    Name of computer the user wants the operating system of.

    .INPUTS
    Accepts pipeline input. Host names and AD computer objects.
    
    .OUTPUTS
    PSObject with computer name and operating system.
    
    .NOTES

    .EXAMPLE
    Get-ComputerOS

    Returns the local host's operating system.

    .EXAMPLE
    Get-ComputerOS -Name Computer1

    Returns computer name and operating system.

    .EXAMPLE
    "Computer1","Computer2" | Get-ComputerOS
    
    Returns the operating system of "Computer1" and "Computer2".

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [Alias('ComputerName')]
        [string]$Name = $env:COMPUTERNAME
    )

    begin{
        $computerOSList = @()
    }

    process{
        if(Test-Connection $Name -Quiet -Count 1){
            try{
                $computerOSList += Get-CimInstance -ComputerName $Name -ClassName win32_operatingsystem -ErrorAction "Stop" | Select-Object -Property @{n='Name';e={$_.PSComputerName}},Caption,BuildNumber
            }catch{
                $computerOSList += Get-WmiObject -ComputerName $Name -Class win32_operatingsystem | Select-Object -Property @{n='Name';e={$_.PSComputerName}},Caption,BuildNumber
            }
        }
    }

    end{
        return $computerOSList
    }
}

function Get-ComputerPhysicalDiskInformation{
    <#
    .SYNOPSIS
    Gets information about the physical disks of a computer.

    .DESCRIPTION
    Returns the health status of the physical disks of the local computer, remote computer, group of computers, or computers in an organizational unit.

    .PARAMETER Name
    Specifies the computer the fuction will gather information from.

    .INPUTS
    You can pipe host names or AD computer objects.

    .OUTPUTS
    Returns objects with disk info including computer name, friendly name, media type, operational status, health status, and size in GB.

    .NOTES
    Only returns information from computers running Windows 10 or Windows Server 2012 or higher.

    .EXAMPLE
    Get-ComputerPhysicalDiskInformation

    Returns disk health information for the local computer.

    .EXAMPLE
    Get-ComputerPhysicalDiskInformation -Name Computer1

    Returns disk health information for the computer named Computer1.

    .EXAMPLE
    "computer1","computer2" | Get-ComputerPhysicalDiskInformation

    Returns physical disk information from "computer1" and "computer2".

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [Alias('ComputerName')]
        [string]$Name = $env:COMPUTERNAME
    )

    begin{
        $physicalDiskList = @()
    }

    process{

        if(Test-Connection $Name -Count 1 -Quiet){
            $physicalDiskList += Get-PhysicalDisk -CimSession $Name | 
                Select-Object -Property @{n="ComputerName";e={$Name}},`
                FriendlyName,`
                MediaType,`
                OperationalStatus,`
                HealthStatus,`
                @{n="SizeGB";e={[math]::Round(($_.Size / 1GB),1)}}
        }
    }

    end{
        return $physicalDiskList
    }
}

function Get-ComputerProcessor{
    <#
    .SYNOPSIS
    Gets the processor of a computer.

    .DESCRIPTION
    Gets the processor of a computer or group of computers. 

    .PARAMETER Name
    The processor of the computer with this name will be returned. By defualt it is the local computer.

    .INPUTS
    Takes an array of computer names or AD computer objects over the pipeline.

    .OUTPUTS
    Returns PS Object/s of the computers passed to it including computer name and processor.

    .NOTES

    .EXAMPLE
    Get-ComputerProcessor -Name 'computer1'

    Returns a PS Object with the computer name and processor of the 'Computer1'.

    .EXAMPLE
    'computer1','computer2' | Get-ComputerProcessor
    
    Returns a PS Object for each computer containing computer name and processor.

    .EXAMPLE
    Get-OUComputer -OrganizationalUnit 'Department X' | Get-ComputerProcessor

    Returns a PS Object for each computer in the 'Department X' Active Directory organizational unit containing computer name and processor.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('ComputerName')]
        [string]$Name = $env:COMPUTERNAME
    )

    begin{
        $computerProcessors = @()
    }

    process{
        $computerProcessors += Get-CimInstance -ComputerName $Name -ClassName Win32_Processor -Property Name | Select-Object -Property @{n='Name';e={$Name}},@{n='Processor';e={$_.Name}}
    }

    end{
        return $computerProcessors
    }
}

function Get-ComputerShareFolder{
    <#
    .SYNOPSIS
    Gets all of the share folders on a computer.
    
    .DESCRIPTION
    This function returns all of the share folders on a computer or remote computer.
    
    .PARAMETER Name
    Target computer's host name.
    
    .INPUTS
    Can accept AD computer objects from the pipeline.
    
    .OUTPUTS
    PS objects with the computer name, share folder name, path to the folder, and status of the folder.
    
    .NOTES
    Requires administrative privileges to work on local machine.

    .EXAMPLE
    Get-ComputerShareFolder -Name 'Computer1'

    Returns all of the share folders from 'Computer1'.
    
    .EXAMPLE
    Get-ADComputer -filter * | Get-ComputerShareFolder

    Returns the share folders from all computers in AD.

    .EXAMPLE
    Get-OUComputer -OrganizationalUnit 'Workstations' | Get-ComputerShareFolder

    Returns the share folders from all computers in the 'Workstations' OU. Get-OUComputer 
    is a function from the PSSystemAdministrator module.
    
    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>
    
    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [Alias('ComputerName')]
        [string]$Name = $env:COMPUTERNAME
    )

    begin{
        #$computerShareList = @()
        $computerShareList = [System.Collections.Generic.List[psobject]]::new()
        $computers = [System.Collections.Generic.List[string]]::new()
    }

    process{
        $computers.Add($Name)
    }

    end{
        $computers | ForEach-Object -Parallel {
            Get-FileShare -CimSession $_ | 
                Select-Object -Property `
                @{n = "ComputerName"; e = {$_.PSComputerName}}, 
                @{n = "Name"; e = {$_.Name}},
                @{n = "Path"; e = {$_.VolumeRelativePath}},
                @{n = "Status"; e = {$_.OperationalStatus}}
        } | ForEach-Object { $computerShareList.Add($_) }

        return $computerShareList
    }
}

function Get-ComputerSoftware{
    <#
    .SYNOPSIS
    Gets all of the installed software on a computer or computers.

    .DESCRIPTION
    This function gathers all of the installed software on a computer or group of computers. By default gathers from the local host.

    .PARAMETER Name
    Host name of target computer.

    .INPUTS
    You can pipe host names or computer AD objects input to this function.

    .OUTPUTS
    Returns PS objects containing ComputerName, Name, Version, Installdate, UninstallCommand, and RegPath.

    .NOTES
    Compatible with Windows 7 and newer.

    Requires remote registry service running on remote machines.

    .EXAMPLE
    Get-ComputerSoftware

    This cmdlet returns all installed software on the local host.

    .EXAMPLE
    Get-ComputerSoftware -ComputerName “Computer”

    This cmdlet returns all the software installed on "Computer".

    .EXAMPLE
    Get-ADComputer -Filter * | Get-ComputerSoftware

    This cmdlet returns the installed software on all computers on the domain.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically

    .LINK
    Based on code from:
    https://community.spiceworks.com/scripts/show/2170-get-a-list-of-installed-software-from-a-remote-computer-fast-as-lightning
    #>

    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [Alias('ComputerName')]
        [string]$Name = $env:COMPUTERNAME
    )

    begin{
        $masterKeys = [System.Collections.Generic.List[psobject]]::new()
        $computers = [System.Collections.Generic.List[string]]::new()

        $lmKeys = "Software\Microsoft\Windows\CurrentVersion\Uninstall","SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
        $lmReg = [Microsoft.Win32.RegistryHive]::LocalMachine
        $cuKeys = "Software\Microsoft\Windows\CurrentVersion\Uninstall"
        $cuReg = [Microsoft.Win32.RegistryHive]::CurrentUser
    }

    process{
        $computers.Add($Name)
    }

    end{
        $computers | ForEach-Object -Parallel {
            if((Test-Connection -ComputerName $_ -Count 1 -Quiet)){
                $remoteLMRegKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($using:lmReg,$_)

                foreach($key in $using:lmKeys){
                    $regKey = $remoteLMRegKey.OpenSubkey($key)
                    
                    foreach ($subName in $regKey.GetSubkeyNames()){
                    
                        foreach($sub in $regKey.OpenSubkey($subName)){
                            New-Object PSObject -Property @{
                                "ComputerName" = $_;
                                "Name" = $sub.getvalue("displayname");
                                "SystemComponent" = $sub.getvalue("systemcomponent");
                                "ParentKeyName" = $sub.getvalue("parentkeyname");
                                "Version" = $sub.getvalue("DisplayVersion");
                                "UninstallCommand" = $sub.getvalue("UninstallString");
                                "InstallDate" = $sub.getvalue("InstallDate");
                                "RegPath" = $sub.ToString()
                            }
                        }
                    }
                }
            }
        } | ForEach-Object {$masterKeys.Add($_)}

        $computers | ForEach-Object -Parallel {
            if(Test-Connection -ComputerName $_ -Count 1 -Quiet){
                $remoteCURegKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($using:cuReg,$_)

                foreach ($key in $using:cuKeys){
                    $regKey = $remoteCURegKey.OpenSubkey($key)

                    if($null -ne $regKey){

                        foreach($subName in $regKey.getsubkeynames()){

                            foreach ($sub in $regKey.opensubkey($subName)){
                                New-Object PSObject -Property @{
                                    "ComputerName" = $_;
                                    "Name" = $sub.getvalue("displayname");
                                    "SystemComponent" = $sub.getvalue("systemcomponent");
                                    "ParentKeyName" = $sub.getvalue("parentkeyname");
                                    "Version" = $sub.getvalue("DisplayVersion");
                                    "UninstallCommand" = $sub.getvalue("UninstallString");
                                    "InstallDate" = $sub.getvalue("InstallDate");
                                    "RegPath" = $sub.ToString()
                                }
                            }
                        }
                    }
                }
            }
        } | ForEach-Object {$masterKeys.Add($_)}

        $woFilter = {$null -ne $_.name -AND $_.SystemComponent -ne "1" -AND $null -eq $_.ParentKeyName}
        $props = 'ComputerName','Name','Version','Installdate','UninstallCommand','RegPath'
        $masterKeys = $masterKeys | Where-Object $woFilter | Select-Object -Property $props
        return $masterKeys
    }
}

function Get-ComputerSystemEvent{
    <#
    .SYNOPSIS
    Gets system events from a computer.

    .DESCRIPTION
    Gets system errors from computers. By default returns errors from local computer. Can return errors from remote computer(s). Default number of errors returned is 5, but is adjustable.

    .PARAMETER Name
    Specifies which computer to pull errors from.

    .PARAMETER Newest
    Specifies the number of most recent errors to be returned.

    .INPUTS
    Host names or AD computer objects.

    .OUTPUTS
    PS objects for computer system errors with Computer, TimeWritten, EventID, InstanceId, and Message.

    .NOTES
    Requires "run as administrator".

    Requires "Printer and file sharing", "Network Discovery", and "Remote Registry" to be enabled on computers that are searched. This funtion can take a long time to complete if more than 5 computers are searched.

    .EXAMPLE
    Get-ComputerSystemEvent

    This cmdlet returns the last 5 system events from localhost.

    .EXAMPLE
    Get-ComputerSystemEvent -Name Server -Newest 2

    This cmdlet returns the last 2 system events from server.

    .EXAMPLE
    "computer1","computer2" | Get-ComputerSystemEvent

    This cmdlet returns newest 5 system events from "computer1" and "computer2".

    .EXAMPLE
    Get-ADComputer Computer1 | Get-ComputerSystemEvent

    This cmdlet returns the last 5 system events from Computer1.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [Alias('ComputerName')]
        [string]$Name = "$env:COMPUTERNAME",
        [int]$Newest = 5
    )

    begin{
        $eventLog = [System.Collections.Generic.List[psobject]]::new()
        $computers = [System.Collections.Generic.List[string]]::new()
    }

    process{
        $computers.Add($Name)        
    }

    end{
        $computers | ForEach-Object -Parallel {
            Get-WinEvent -LogName System -ComputerName $_ -MaxEvents $using:Newest | 
            Select-Object -Property MachineName,TimeCreated,Id,LevelDisplayName,Message
        } | ForEach-Object { $eventLog.Add($_) }

        return $eventLog
    }
}

function Get-CredentialExportToXML{
    <#
    .SYNOPSIS
    Gets credentials from the user and exports them to location provided by the user.

    .DESCRIPTION
    This function promps the user for a user name and password. It encrypts the password and saves it all to an XML file at the path provided to the function. You can then import these credentials in other functions and scripts that require credentials without having to hard code them in.
    
    .PARAMETER FileName
    The name that will be given to the file containing the credentials. Do not include file extention.

    .PARAMETER Path
    The directory the credentials will be saved. Do not include trailing "\".

    .INPUTS
    None.

    .OUTPUTS
    XML file with credentials.

    .NOTES

    .EXAMPLE
    Get-CredentialExportToXML -FileName Creds -Path C:\ScriptCreds

    Promps user for user name and password. Encryps the password and saves the credentials at C:\ScriptCreds\Creds.clixml

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FileName,

        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    $credential = Get-Credential
    Export-Clixml -Path "$Path\$FileName.xml" -InputObject $credential
}

function Get-DirectorySize{
    <#
    .SYNOPSIS
    Gets the size of a directory.

    .DESCRIPTION
    Gets the size of a directory or directories in GB.

    .PARAMETER Path
    Path to the directory to be measured.

    .INPUTS
    None.

    .OUTPUTS
    Returns object with directory and size in GB.

    .NOTES
    Command needs to be run as an administrator to ensure all files are checked.

    .EXAMPLE
    Get-DirectorySize -Path 'C:\Users'

    Returns the size of the Users folder.

    .EXAMPLE
    '\\FileShareServer\Folder1','\\FileShareServer\Folder2' | Get-DirectorySize

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically

    .Link
    Based on: https://www.gngrninja.com/script-ninja/2016/5/24/powershell-calculating-folder-sizes
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [Alias('Directory')]
        [string] $Path
    )

    begin{
        $directorySizes = @()
    }

    process{
        $directorySize = (Get-ChildItem -Path $Path -File -Recurse -Force | Measure-Object -Sum Length).sum

        $directorySizes += [PSCustomObject]@{
            Directory = $Path;
            SizeGB = [math]::round(($directorySize / 1GB),2)
        }
    }

    end{
        return $directorySizes
    }
}

function Get-DisabledComputer{
    <#
    .SYNOPSIS
    Gets a list of all computers that are disabled.

    .DESCRIPTION
    Gets a list of computers from AD that are disabled with information including name, enabled status, DNSHostName, and DistinguishedName.

    .PARAMETER OrganizationalUnit
    Focuses the function on a specific AD organizational unit.

    .INPUTS
    None.

    .OUTPUTS
    PS objects with information including Name, Enabled status, DNSHostName, and DistinguishedName.

    .NOTES
    
    .EXAMPLE
    Get-DisabledComputer

    Returns a list of all AD computers that are currently disabled.

    .EXAMPLE
    Get-DisabledComputer -OrganizationalUnit "Servers"

    Returns a list of all AD computers in the organizational unit "Servers" that are currently disabled.


    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [CmdletBinding()]
    Param(
        [string]$OrganizationalUnit = ""
    )
    
    if($OrganizationalUnit -eq ""){
        $disabledComputers = Get-ADComputer -Filter * | Where-Object -Property Enabled -EQ $False
    }else{
        $disabledComputers = Get-OUComputer -OrganizationalUnit $OrganizationalUnit | 
            Where-Object -Property Enabled -EQ $False
    }

    return $disabledComputers
}

function Get-DisabledUser{
    <#
    .SYNOPSIS
    Gets a list of all users that are disabled.  

    .DESCRIPTION
    Returns a list of users from AD that are disabled with information including name, enabled, and user principal name. Function can be limited in scope to a specific organizational unit.

    .PARAMETER OrganizationalUnit
    Focuses the function on a specific AD organizational unit.

    .INPUTS
    None.

    .OUTPUTS
    PS objects with information including name, DNSHostName, and DistinguishedName.

    .NOTES
    
    .EXAMPLE
    Get-DisabledUser

    Returns a list of all AD users that are currently disabled.

    .EXAMPLE
    Get-DisabledUser -OrganizationalUnit "Employees"

    Returns a list of all AD users that are currently disabled in the "Employees" organizational unit.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [CmdletBinding()]
    Param(
        [string]$OrganizationalUnit = ""
    )

    if($OrganizationalUnit -eq ""){
        $disabledUsers = Get-ADUser -Filter * | Where-Object -Property Enabled -EQ $False
    }else{
        $disabledUsers = Get-OUUser -OrganizationalUnit $OrganizationalUnit | Where-Object -Property Enabled -EQ $False
    }

    return $disabledUsers
}

function Get-InactiveComputer{
    <#
    .SYNOPSIS
    Gets computers that have not logged onto the domain for more than 30 days.

    .DESCRIPTION
    Gets computers from Active Directory that have not logged onto the domain for more than 30 days. The default amount of days is 30. Can be limited to a specific organizational unit.

    .PARAMETER Days
    Sets minimum age for last logon time.

    .PARAMETER OrganizationalUnit
    Focuses the function on a specific organizational unit.

    .INPUTS
    None.

    .OUTPUTS
    PS objects with information including computer Name and LastLogonTime.

    .NOTES

    .EXAMPLE
    Get-InactiveComputer

    Lists all computers in the domain that have not been online for more than 30 days.

    .EXAMPLE
    Get-InactiveComputer -Days 35 -OrganizationalUnit 'Department X'

    Lists all computers in the 'Department X' organizational unit that have not been on the network for 35 days.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [CmdletBinding()]
    Param(
        [int]$Days = 30,
        [string]$OrganizationalUnit = ""
    )

    if($OrganizationalUnit -eq ""){
        $computers = Get-ADComputer -Filter * | 
            Get-ComputerLastLogonTime | 
            Where-Object -Property LastLogon -LT ((Get-Date).AddDays(($Days * -1)))
    }else{
        $computers = Get-OUComputer -OrganizationalUnit $OrganizationalUnit | 
            Get-ComputerLastLogonTime |
            Where-Object -Property LastLogon -LT ((Get-Date).AddDays(($Days * -1)))
    }

    return $computers
}

function Get-InactiveFile{
    <#
    .SYNOPSIS
    Gets all files in a directory that have not been accessed in the last 24 hours.
    
    .DESCRIPTION
    Gets all files in a directory recursively that have not been access recently. Returns file name, last access time, size in MB, and full name.
    
    .PARAMETER Path
    Function will gather all files recursively from this directory.

    .PARAMETER Days
    Function will return only files that have not been accessed for over this many days. By default is set to 1 and function returns all files.

    .INPUTS
    You can pipe multiple paths to this function.
    
    .OUTPUTS
    Array of PS objects that includes file names, last access time, size in MB, and full name.
    
    .NOTES

    .EXAMPLE
    Get-InactiveFiles -Path C:\Directory1 -DaysInactive 5

    Gathers all files recursively in the "Directory1" folder that have not been accessed in over 5 days.

    .EXAMPLE
    "C:\Directory1","C:\Directory2" | Get-InactiveFiles

    Gathers all files recursively in the "Directory1" and "Directory2" folders.
    
    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true,Mandatory=$True)]
        [Alias('FullName')]
        [string]$Path,
        [int]$Days = 1
    )

    begin{
        $files = @()
        $fileAge = (Get-Date).AddDays(-1 * $Days)
    }

    process{
        $files += Get-ChildItemLastWriteTime -Path $Path | 
            Where-Object -Property LastWriteTime -LT $fileAge
    }

    end{
        return $files
    }
}

function Get-InactiveUser{
    <#
    .SYNOPSIS
    Gets a list of all users that have not logged on to the domain for 30 days.

    .DESCRIPTION
    Gets a list of users in active directory that have been inactive for a number of days. The default number of days is 30. Function can also be focused on a specific OU.

    .PARAMETER Days
    Determines how long the user account has to be inactive for it to be returned.

    .PARAMETER OrganizationalUnit
    Focuses the function on a specific AD organizational unit.

    .INPUTS
    None.

    .OUTPUTS
    PS objects with SamAccountName and LastLogonTime.

    .NOTES

    .EXAMPLE
    Get-InactiveUser

    Lists all users in the domain that have not checked in for more than 30 days.

    .EXAMPLE
    Get-InactiveUser -Days 2

    Lists all users in the domain that have not checked in for more than 2 days.

    .EXAMPLE
    Get-InactiveUser -Days 45 -OrganizationalUnit "Department X Users"

    Lists all users in the domain that have not checked in for more than 45 days in the "Department X Users" organizational unit.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [CmdletBinding()]
    Param(
        [int]$Days = 30,
        [string]$OrganizationalUnit = ""
    )

    if($OrganizationalUnit -eq ""){
        $users = Get-ADUser -Filter * | 
            Get-UserLastLogonTime |
            Where-Object -Property LastLogon -LT ((Get-Date).AddDays($Days * -1))
    }else{
        $users = Get-OUUser -OrganizationalUnit $OrganizationalUnit | 
            Get-UserLastLogonTime |
            Where-Object -Property LastLogon -LT ((Get-Date).AddDays($Days * -1))
    }

    return $users
}

function Get-LargeFile{
    <#
    .SYNOPSIS
    Gets files larger than 500 MB from a directory.
 
    .DESCRIPTION
    Gets files from a directory recursively that are larger than 500 MB. Directory and file size can be set.
 
    .PARAMETER Path
    Sets the directory the function searches.

    .PARAMETER Megabytes
    Sets the file size minimum for files that are returned.
 
    .INPUTS
    Directories can be piped to this function.
 
    .OUTPUTS
    PS objects with name, fileSizeMB, and full name.
 
    .NOTES

    .EXAMPLE
    Get-LargeFiles -Path "C:\Folder1" -FileSizeMB 1000

    Returns all files over 1000MB from the "folder1" directory.
 
    .EXAMPLE
    "C:\Folder1","C:\Folder2" | Get-LargeFiles -FileSizeMB 5000

    Returns all files over 5000MB from the "folder1" and "folder2" directories.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true,Mandatory=$True)]
        [Alias('Directory','FullName')]
        [string]$Path,
        [int]$Megabytes = 500
    )

    begin{
        $largeFiles = @()
    }

    process{
        $largeFiles += Get-ChildItem -Path $Path -File -Recurse -Force | Where-Object -Property Length -GT ($Megabytes * 1000000)
    }

    end{
        $largeFiles = $largeFiles | Select-Object -Property Name,@{n="SizeMB";e={[math]::round(($_.Length / 1MB),1)}},FullName
        return $largeFiles
    }
}

function Get-LockedOutUser{
    <#
    .SYNOPSIS
    Gets locked out users from Active Directory.

    .DESCRIPTION
    Gets all locked users accounts in Active Directory. Function can be limited to a single organizational unit.

    .PARAMETER OrganizationalUnit
    Only returns user AD objects from this organizational unit.

    .INPUTS
    None.

    .OUTPUTS
    User AD objects.

    .NOTES

    .EXAMPLE
    Get-LockedOutUser

    Gets all locked out users in AD.

    .EXAMPLE
    Get-LockedOutUser -OrganizationalUnit 'Department X Users'

    Gets all locked out users in the 'Department X Users' organizational unit.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    Used information from: https://social.technet.microsoft.com/wiki/contents/articles/52327.windows-track-down-an-account-lockout-source-and-the-reason-with-powershell.aspx
    #>

    [CmdletBinding()]
    Param(
        [string]$OrganizationalUnit = ""
    )
    
    $lockedOutUsers = @()
    $lockedOutUsersFiltered = @()
    $lockedOutUsersRaw = Search-ADAccount -LockedOut -UsersOnly
    
    if($OrganizationalUnit -ne ""){
        $ouUsers = Get-OUUser -OrganizationalUnit $OrganizationalUnit

        foreach($user in $ouUsers){
            foreach($lockedOutUser in $lockedOutUsersRaw){
                if($user.SamAccountName -eq $lockedOutUser.SamAccountName){
                    $lockedOutUsersFiltered += $lockedOutUser
                }
            }
        }
    }else{
        $lockedOutUsersFiltered = $lockedOutUsersRaw
    }

    $lockedOutUsers = $lockedOutUsersFiltered

    return $lockedOutUsers    
}

function Get-LockedOutUserEvent{
    <#
    .SYNOPSIS
    Gets events about user accounts getting locked in Active Directory.

    .DESCRIPTION
    Gets events about user account getting locked in Active Directory from all domain contollers.

    .PARAMETER OrganizationalUnit
    Only gets lockout events for users in this OU.

    .INPUTS
    None.

    .OUTPUTS
    PowerShell objects with the following properties: 
        TimeCreated - Date time the event was recorded
        Id - Event ID
        User - SamAccountName
        Source - Computer where the lockout occured
        DomainController - Domain controller that recorded the event
        Domain - Domain that the user belongs to. Can be a domain or local machine

    .NOTES
    There my be duplicate results returned if the event has been recorded on multiple domain controllers.

    .EXAMPLE
    Get-LockedOutUserEvent

    Gets all events for user account lockouts from all domain controllers.

    .EXAMPLE
    Get-LockedOutUserEvent -OrganizationalUnit 'Department X Users'

    Gets all events for user account lockouts for users in the 'Department X Users' OU from all domain controllers.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    https://social.technet.microsoft.com/wiki/contents/articles/52327.windows-track-down-an-account-lockout-source-and-the-reason-with-powershell.aspx
    #>

    [CmdletBinding()]
    Param(
        [string]$OrganizationalUnit = "",
        [int]$DaysBack = 1
    )

    $lockedOutUsers = @()
    $lockedOutUsersRaw = @()
    $lockedOutUsersFiltered = @()
    $domainControllers = (Get-ADDomainController -Filter *).Name
    $eventAge = (Get-Date).AddDays(-1 * $DaysBack)

    if($OrganizationalUnit -eq ""){
        foreach ($dc in $domainControllers){
            $lockedOutUsersFiltered += Get-WinEvent -ComputerName $dc -FilterHashtable @{LogName = 'Security'; ID = 4740} | 
                Where-Object -Property TimeCreated -GT $eventAge
        }
    }else{
        foreach ($dc in $domainControllers){
            $lockedOutUsersRaw += Get-WinEvent -ComputerName $dc -FilterHashtable @{LogName = 'Security'; ID = 4740} | 
                Where-Object -Property TimeCreated -GT $eventAge
        }

        $ouUsers = Get-OUUser -OrganizationalUnit $OrganizationalUnit

        foreach ($user in $ouUsers){
            foreach($lockedOutUser in $lockedOutUsersRaw){
                if($user.SamAccountName -eq $lockedOutUser.Properties[0].Value){
                    $lockedOutUsersFiltered += $lockedOutUser
                }
            }            
        }
    }

    foreach($user in $lockedOutUsersFiltered){
        $lockedOutUsers += [PSCustomObject]@{
            TimeCreated = $user.TimeCreated
            Id = $user.Id
            User = $user.Properties[0].Value
            Source = $user.Properties[1].Value
            DomainController = $user.Properties[4].Value
            Domain = $user.Properties[5].Value
        }
    }

    return $lockedOutUsers    
}

function Get-OfflineComputer{
    <#
    .SYNOPSIS
    Gets all computers that are offline.  

    .DESCRIPTION
    Gets all computers in Active Directory that are offline with information including name, DNS host name, and distinguished name. By default searches the whole AD. Can be limited to a specific organizational unit.

    .PARAMETER OrganizationalUnit
    Focuses the function on a specific AD organizational unit.

    .INPUTS
    None.

    .OUTPUTS
    PS objects with information including Name, DNSHostName, and DistinguishedName.

    .NOTES
    Firewalls must be configured to allow ping requests.

    .EXAMPLE
    Get-OfflineComputer

    Returns computer AD Objects for all AD computers that are offline.

    .EXAMPLE
    Get-OfflineComputer -OrganizationalUnit "WorkStations"

    Returns computer AD objects for all AD computers that are offline in the "Workstations" organizational unit.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [CmdletBinding()]
    Param(
        [string]$OrganizationalUnit = ""
    )

    if($OrganizationalUnit -eq ""){
        $computers = Get-ADComputer -Filter *
    }else{
        $computers = Get-OUComputer -OrganizationalUnit $OrganizationalUnit
    }

    $offlineComputers = @()
    
    foreach($computer in $computers){
    
        if(!(Test-Connection -ComputerName ($computer).name -Count 1 -Quiet)){
            $offlineComputers += $computer
        }
    }
    
    return $offlineComputers
}

function Get-OnlineComputer{
    <#
    .SYNOPSIS
    Gets computers that are online.

    .DESCRIPTION
    Gets computers that are online with information including name, DNS host name, and distinguished name. 

    .PARAMETER OrganizationalUnit
    Focuses the function on a specific AD organizational unit.

    .PARAMETER PingTimeoutMS
    The time in milliseconds to wait for each server to respond to the ping. Default is 100.

    .INPUTS
    None.

    .OUTPUTS
    PS objects containing Name, DNSHostName, and DistinguishedName.

    .NOTES
    Firewalls must be configured to allow ping requests.

    .EXAMPLE
    Get-OnlineComputer

    Returns list of all AD computers that are currently online.

    .EXAMPLE
    Get-OnlineComputer -OrganizationalUnit 'Department X'

    Returns the online computers from the 'Department X' organizational unit.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [CmdletBinding()]
    Param (
        [string]$OrganizationalUnit = "",
        [int]$PingTimeoutMS = 100
    )

    begin {
        if ($OrganizationalUnit -eq "") {
            $computers = Get-ADComputer -Filter *
        } else {
            $computers = Get-OUComputer -OrganizationalUnit $OrganizationalUnit
        }
        $pingTasks = New-Object 'System.Collections.Generic.Dictionary[string, System.Threading.Tasks.Task]'
    }

    process {
        foreach ($computer in $computers) {
            $ping = New-Object -TypeName 'System.Net.NetworkInformation.Ping'
            $pingTasks.Add($computer.Name, $ping.SendPingAsync($computer.Name, $PingTimeoutMS))
        }
    }

    end {
        while ($pingTasks.Values.IsCompleted -contains $false) {
            Start-Sleep -Milliseconds $PingTimeoutMS
        }

        $computers | Where-Object {
            $pingTasks[$_.Name].Result.Status -eq 0
        }
    }
}

function Get-OUComputer{
    <#
    .SYNOPSIS
    Gets computers from a specific organizational unit.
    
    .DESCRIPTION
    Gets computer AD objects for each computer in an AD organizaitional unit. 
    
    .PARAMETER OrganizationalUnit
    Sets the scope of the function to the provided organizational unit.

    .INPUTS
    None.

    .OUTPUTS
    Array of AD computer objects.
    
    .NOTES

    .EXAMPLE
    Get-OUComputer -OrganizationalUnit "Workstations"

    Returns AD objects for all computers in the Workstations organizational unit. 
    
    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline=$True,Mandatory=$True)]
        [string]$OrganizationalUnit
    )

    begin{
        $domainInfo = (Get-ADDomain).DistinguishedName
        $computers = @()
    }

    process{
        $computers += Get-ADComputer -Filter * -SearchBase "ou=$OrganizationalUnit,$domainInfo"
    }

    end{
        return $computers
    }
}

function Get-OUUser{
    <#
    .SYNOPSIS
    Gets users from a specific organizational unit.
    
    .DESCRIPTION
    Gets user AD objects for each user in an AD organizaitional unit. 
    
    .PARAMETER OrganizationalUnit
    Sets the scope of the function to the provided organizational unit.

    .INPUTS
    None.

    .OUTPUTS
    Array of AD user objects.
    
    .NOTES

    .EXAMPLE
    Get-OUUser -OrganizationalUnit "Users"

    Returns AD objects for all users in the Users organizational unit. 
    
    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline=$True,Mandatory=$True)]
        [string]$OrganizationalUnit
    )

    begin{
        $domainInfo = (Get-ADDomain).DistinguishedName
        $users = @()
    }

    process{
        $users += Get-ADUser -Filter * -SearchBase "ou=$OrganizationalUnit,$domainInfo"
    }

    end{
        return $users
    }
}

function Get-SubDirectorySize{
    <#
    .SYNOPSIS
    Gets directory names and sizes.

    .DESCRIPTION
    Gets a list of directories and their sizes located at the submitted path.

    .PARAMETER Path
    Path to the directory to be searched.

    .INPUTS
    None.

    .OUTPUTS
    PS objects with directory name and size in GB.

    .NOTES

    .EXAMPLE
    Get-SubDirectorySize -Path 'C:\Users'

    Gets the name and size of all folders contained in the Users directory.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [alias('FullName')]
        [string] $Path
    )

    begin{
        $directorySizes = @()
    }

    process{
        $directories = Get-ChildItem -Path $Path -Directory -Force

        foreach($dir in $directories){
            $directorySizes += Get-DirectorySize -Path $dir.FullName
        }
    }

    end{
        return $directorySizes
    }
}

function Get-UserActiveLogon{
    <#
    .SYNOPSIS
    Gets all computers where a user is logged in.

    .DESCRIPTION
    Searches domain computers and returns a list of computers where a specific user is logged in. 
    
    .PARAMETER SamAccountName
    Takes the SamAccountName of an AD user.

    .PARAMETER OrganizationalUnit
    Limits the function's search to an organizational unit.

    .INPUTS
    String with SamAccountName or AD user object. Can pipe input to the function.

    .OUTPUTS
    List of objects with the user name and the names of the computers they are logged into.

    .NOTES
    Compatible with Windows 7 and newer.

    .EXAMPLE
    Get-UserActiveLogon -Name Thor

    Returns a list of computers where Thor is logged in.  

    .EXAMPLE
    "Thor","Loki","Oden" | Get-UserActiveLogon 

    Returns a list of computer where each of these users are logged in. 

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [string]$SamAccountName,
        [string]$OrganizationalUnit = ""
    )

    begin{
        $computerList = @()

        if($OrganizationalUnit -eq ""){
            $computers = (Get-ADComputer -Filter *).Name
        }else{
            $computers = (Get-OUComputer -OrganizationalUnit $OrganizationalUnit).Name
        }

        foreach ($computer in $computers){
            $computerList += [PSCustomObject]@{
                Computer = $computer;
                UserName = ""
            }
        }
    }

    process{
        $computerList | ForEach-Object -Parallel {
            $currentUser = (Get-ComputerCurrentUser -Name $_.Computer).UserName
            
            if($using:SamAccountName -eq $currentUser){
                $_.UserName = $currentUser
            }
        }
    }

    end{
        $computerList = $computerList | Where-Object -Property UserName -NE ""
        return $computerList
    }
}

function Get-UserLastLogonTime{
    <#
    .SYNOPSIS
    Gets the last time a user logged onto the domain.

    .DESCRIPTION
    Returns the last time a user or group of users logged onto the domain.

    .PARAMETER SamAccountName
    User name.

    .INPUTS
    You can pipe user names and user AD objects to this function.

    .OUTPUTS
    PS objects with user name and last logon date.

    .NOTES
    None.

    .EXAMPLE
    Get-UserLastLogonTime -Name "Fred"

    Returns the last time Fred logged into the domain.

    .EXAMPLE
    Get-ADUser -Filter * | Get-UserLastLogonTime

    Gets the last time all users in AD logged onto the domain.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [string]$SamAccountName = $env:UserName
    )

    begin{
        $lastLogonList = @()

        #When looking for AD User LastLogon we need to check all domain controllers because this information is not synced between them.
        $domainControllers = (Get-ADDomainController -Filter *).Name
    }

    process{
        $dcCount = $domainControllers.Count
        
        if($dcCount -eq 1){
            $lastLogonList += Get-ADUser $SamAccountName | 
                Get-ADObject -Properties LastLogon | 
                Select-Object -Property @{n="SamAccountName";e={$SamAccountName}},@{n="LastLogon";e={([datetime]::fromfiletime($_.LastLogon))}}
        }else{
            $lastLogonTime = Get-ADuser $SamAccountName -Server $domainControllers[0] | 
                Get-ADObject -Properties LastLogon | 
                Select-Object -Property @{n="SamAccountName";e={$SamAccountName}},@{n="LastLogon";e={([datetime]::fromfiletime($_.LastLogon))}}
            
            for($i = 1; $i -LT $dcCount; $i++){
                $nextlogonTime = Get-ADuser $SamAccountName -Server $domainControllers[$i] | 
                    Get-ADObject -Properties LastLogon | 
                    Select-Object -Property @{n="SamAccountName";e={$SamAccountName}},@{n="LastLogon";e={([datetime]::fromfiletime($_.LastLogon))}}


                if($nextlogonTime.LastLogon -GT $lastLogonTime.LastLogon){
                    $lastLogonTime = $nextlogonTime
                }
            }
            
            $lastLogonList += $lastLogonTime
        }
    }

    end{
        return $lastLogonList
    }
}

function Move-Computer{
    <#
    .SYNOPSIS
    Moves a computer to an organizational unit.
    
    .DESCRIPTION
    Moves a computer or computers to an AD organizational unit. 
    
    .PARAMETER Name
    This is the computer the function will move.

    .PARAMETER OrganizationalUnit
    Destination organizational unit.

    .INPUTS
    Host names or AD computer objects.

    .OUTPUTS
    An array of AD computer objects. One for each computer moved by the function.

    .NOTES

    .EXAMPLE
    Move-Computer -Name "Computer1" -OrganizationalUnit "Work Computers"

    Moves "Computer1" to the "Work Computers" OU.

    .EXAMPLE
    "Computer1","Computer2" | Move-Computer -OrganizationalUnit "Work Computers"

    Moves "Computer1" and "Computer2" to the "Work Computers" OU.

    .EXAMPLE
    Get-ADComputer -Filter * | Move-Computer -OrganizationalUnit "Work Computers"

    Moves all computers in AD to the "Work Computers" OU.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [Alias('ComputerName')]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [string]$DestinationOU
    )
    
    begin{
        $domainInfo = (Get-ADDomain).DistinguishedName
        $movedComputers = @()
    }

    process{
        $computer = Get-ADComputer -Identity $Name
        $computer | Move-ADObject -TargetPath "ou=$DestinationOU,$domainInfo"

        #Update AD computer object to show new location
        Start-Sleep -Seconds 1
        $computer = Get-ADComputer -Identity $Name
        $movedComputers += $computer
    }

    end{
        return $movedComputers
    }
}

function Move-User{
    <#
    .SYNOPSIS
    Moves a user to an organizational unit.
    
    .DESCRIPTION
    Moves a user or users to an AD organizational unit. 
    
    .PARAMETER SamAccountName
    This is the user the function will move.

    .PARAMETER OrganizationalUnit
    Destination organizational unit.

    .INPUTS
    Sam account names or AD user objects.

    .OUTPUTS
    An array of AD user objects. One for each user moved by the function.

    .NOTES

    .EXAMPLE
    Move-User -SamAccountName "User1" -OrganizationalUnit "Work Users"

    Moves "User1" to the "Work Users" OU.

    .EXAMPLE
    "User1","User2" | Move-User -OrganizationalUnit "Work Users"

    Moves "User1" and "User2" to the "Work Users" OU.

    .EXAMPLE
    Get-ADUser -Filter * | Move-User -OrganizationalUnit "Work Users"

    Moves all users in AD to the "Work Users" OU.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [Alias("SamAccountName")]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [string]$DestinationOU
    )
    
    begin{
        $domainInfo = (Get-ADDomain).DistinguishedName
        $movedUsers = @()
    }

    process{
        $user = Get-ADUser -Identity $Name
        $user | Move-ADObject -TargetPath "ou=$DestinationOU,$domainInfo"

        #Get updated AD user location
        Start-Sleep -Seconds 1
        $user = Get-ADUser -Identity $Name
        $movedUsers += $user
    }

    end{
        return $movedUsers
    }
}

function Remove-Computer{
    <#
    .SYNOPSIS
    Removes a computer from Active Directory.

    .DESCRIPTION
    Remove a computer or computers from AD. Also returns a list of computers that have been removed.

    .PARAMETER Name
    Name of the computer being removed.

    .INPUTS
    Host names or AD computer objects.

    .OUTPUTS
    Returns an AD computer object for each computer removed from AD.

    .NOTES

    .EXAMPLE
    Remove-Computer -Name "Computer1"

    Removes "Computer1" from AD.

    .EXAMPLE
    "Computer1","Computer2" | Remove-Computer

    Removes "Computer1" and "Computer2" from AD.

    .EXAMPLE
    Get-ADComputer -Filter * | Remove-Computer

    Removes all computers from AD.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [Alias('ComputerName')]
        [string]$Name
    )

    begin{
        $computers = @()
    }

    process{
        $computers += Get-ADComputer $Name
    }

    end{
        $computers | Remove-ADComputer
        return $computers
    }
}

function Remove-DHCPReservation{
    <#
    .SYNOPSIS
    Removes a reservation for a computer in DHCP.

    .DESCRIPTION
    This function removes an IPv4 reservation for a computer in all DHCP servers in a domain.

    .PARAMETER ComputerName
    Host name of the computer in the reservation that will be removed.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .NOTES
    This function is meant to be used in a domain with one DHCP scope.

    This function will attempt to remove the reservation in each available DHCP server. If it is unable to reach every DHCP server, then the reservation will remain on that server if it exists there.

    .EXAMPLE
    Remove-DHCPReservation -ComputerName "Computer1"

    Removes any reservations for "Computer1" in all available DHCP servers in the domain.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ComputerName
    )

    $dhcpServers = (Get-DhcpServerInDC).DnsName
    $hostName = (Get-ADComputer -Identity $ComputerName).DNSHostName

    foreach($server in $dhcpServers){
        $dhcpServer = $server.split(".")[0]
        $scopeId = (Get-DhcpServerv4Scope -ComputerName $dhcpServer | Select-Object -First 1).ScopeId
        $dhcpLeases = Get-DhcpServerv4Lease -ComputerName $dhcpServer -ScopeId $scopeId -AllLeases
        $clientId = ($dhcpLeases | Where-Object -Property HostName -EQ $hostName | Select-Object -First 1).ClientId
        $reservations = Get-DhcpServerv4Reservation -ScopeId $scopeId -ComputerName $dhcpServer

        # Check if there is a reservation for the computer.
        $isReserved = $false
        foreach($r in $reservations){
            if($r.Name -EQ $hostName){
                $isReserved = $true
                break
            }
        }

        if($isReserved -EQ $true){
            Remove-DhcpServerv4Reservation -ScopeId $scopeId -ClientId $clientId -ComputerName $dhcpServer
        }
    }
}

function Remove-User{
    <#
    .SYNOPSIS
    Removes a user from Active Directory.

    .DESCRIPTION
    Removes a user or users from AD and returns a list of users that were removed. This function will not ask to confirm the deletion of accounts.

    .PARAMETER SamAccountName
    User that will be removed.

    .INPUTS
    None. You cannot pipe paramters to this function.

    .OUTPUTS
    Returns an AD user object for each user removed from AD.

    .NOTES

    .EXAMPLE
    Remove-User -Name "User1"

    Removes "User1" from AD.

    .EXAMPLE
    "User1","User2" | Remove-User

    Removes "User1" and "User2" from AD.

    .EXAMPLE
    Get-ADUser -Filter * | Remove-User

    Removes all Users from AD.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [string]$SamAccountName
    )

    begin{
        $users = @()
    }

    process{
        $users += Get-ADUser $SamAccountName
    }

    end{
        $users | Remove-ADUser -Confirm:$false
        return $users
    }
}

function Set-ComputerIPAddress{
    <#
    .SYNOPSIS
    Sets the IP address of a computer.

    .DESCRIPTION
    This function will set the IP address, subnet, DNS, and default gateway of a domain computer. The IP addresss is user provided and all the other information is
    gathered from the computer executing the command.

    .PARAMETER ComputerName
    The name of the remote computer that will be assigned the submitted IP address.

    .PARAMETER IPAddress
    IP address that will be applied to the remote computer.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .NOTES
    This function attempts to change the IP settings on the remote computer using PowerShell commands. If that fails it will use netsh.

    This function only works on a computer that is set to use DHCP. Does not work on computers with a static IP address.

    Due to the nature of how this function connects to the remote computer, after changing the IP settings the function will say that the connection has been broken. This is a sign that the IP changes have worked.

    .EXAMPLE
    Set-ComputerIPAddress -ComputerName "Computer2" -IPAddress 10.10.10.10

    Sets Computer2's IP address to 10.10.10.10 and copies over DNS, subnet, and default gateway information from the host computer.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,

        [Parameter(Mandatory=$true)]
        [string]$IPAddress
    )

    Write-Host "Setting $ComputerName's IP address to $IPAddress. Connection to $ComputerName will be lost when the new IP address is active."
    
    #Self adapter
    $SelfIPAddress = (Resolve-DnsName -Type A -Name $env:COMPUTERNAME).IPAddress
    $SelfIPInterfaceIndex = (Get-NetIPAddress | Where-Object -Property IPAddress -eq $SelfIPAddress).InterfaceIndex

    #Subnetmask / Prefixlength
    $SelfPrefixlength = (Get-NetIPAddress | Where-Object -Property IPAddress -eq $SelfIPAddress).PrefixLength

    #Default Gateway
    $SelfDefaultGateway = (Get-NetRoute | Where-Object -Property DestinationPrefix -eq '0.0.0.0/0').NextHop

    #DNS
    $SelfDNS = (Get-DnsClientServerAddress -InterfaceIndex $SelfIPInterfaceIndex -AddressFamily IPv4).ServerAddresses
    $TargetIPAddress = (Resolve-DnsName -Type A -Name $ComputerName).IPAddress

    try{
        #Target interface index
        $TargetIPInterfaceIndex = (Get-NetIPAddress -CimSession $ComputerName | Where-Object -Property IPAddress -eq $TargetIPAddress).InterfaceIndex
        Set-DnsClientServerAddress -CimSession $ComputerName -InterfaceIndex $TargetIPInterfaceIndex -ServerAddresses $SelfDNS
        New-NetIPAddress -CimSession $ComputerName -InterfaceIndex $TargetIPInterfaceIndex -IPAddress $IPAddress -AddressFamily IPv4 -PrefixLength $SelfPrefixlength -DefaultGateway $SelfDefaultGateway
    }catch{
        switch($SelfPrefixlength){
            30 {$SubnetMask = "255.255.255.252"}
            29 {$SubnetMask = "255.255.255.248"}
            28 {$SubnetMask = "255.255.255.240"}
            27 {$SubnetMask = "255.255.255.224"}
            26 {$SubnetMask = "255.255.255.192"}
            25 {$SubnetMask = "255.255.255.128"}
            24 {$SubnetMask = "255.255.255.0"}
            23 {$SubnetMask = "255.255.254.0"}
            22 {$SubnetMask = "255.255.252.0"}
            21 {$SubnetMask = "255.255.248.0"}
            20 {$SubnetMask = "255.255.240.0"}
            19 {$SubnetMask = "255.255.224.0"}
            18 {$SubnetMask = "255.255.192.0"}
            17 {$SubnetMask = "255.255.128.0"}
            16 {$SubnetMask = "255.255.0.0"}
        }

        $TargetIPInterfaceAlias = "Local Area Connection"

        if($SelfDNS.count -gt 1){
            $SelfDNS1 = $SelfDNS[0]
            $SelfDNS2 = $SelfDNS[1]
        }
        
        Invoke-Command -ComputerName $ComputerName -ScriptBlock {netsh interface ip set dnsservers name="$using:TargetIPInterfaceAlias" address="$using:SelfDNS1" static primary}
            
        if($SelfDNS.count -gt 1){
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {netsh interface ip add dnsservers name="$using:TargetIPInterfaceAlias" address="$using:SelfDNS2"}
        }

        Invoke-Command -ComputerName $ComputerName -ScriptBlock {netsh interface ip set address $using:TargetIPInterfaceAlias static $using:IPAddress $using:SubnetMask $using:SelfDefaultGateway}
    }
}

function Set-UserChangePassword{
    <#
    .SYNOPSIS
    Sets user account to require a password change at the next log on.
    
    .DESCRIPTION
    This function requires the AD user accounts passed to it to require the user to create a new password at the their next login. 
    If the account's 'PasswordNeverExpires' tag is set to true, then it is not affected by this function.
    
    .PARAMETER Name
    This is the SamAccountName of the user you want to require a new password for.
    
    .INPUTS
    Can take AD user objects as input.
    
    .OUTPUTS
    AD user objects that have been tagged for creating a new password on log in.
    
    .NOTES

    .EXAMPLE 
    Reset-UserPassword -Name 'billy'

    Requires the AD account with the SamAccountID of 'billy' to create a new password on next login.
    
    .EXAMPLE
    Get-ADUser -Filter * | Reset-UserPassword

    Requires all users in AD to create a new password on next login.

    .Example
    Get-OUUser -OrganizationalUnit 'Users' | Reset-UserPassword

    Requires all users in the 'Users' OU to create a new password when they log in next. Get-OUUser
    is a function from the PSSystemAdministrator module.
    
    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically
    #>

    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
        [Alias("Name")]
        [string]$SamAccountName
    )

    begin{
        $userList = @()
    }

    process{
        $user = Get-ADUser $SamAccountName
        Set-ADUser -Identity $user -ChangePasswordAtLogon $true
        $userList += $user
    }

    end{
        return $userList
    }
    
}

function Start-Computer{
    <#
    .SYNOPSIS
    Starts a remote computer by sending a magic packet.
    
    .DESCRIPTION
    Can start a single or multiple computers on a Windows domian.
    
    .PARAMETER Name
    Name of the computer this function will start.

    .INPUTS
    You can pipe AD computer PS objects to this function.

    .OUTPUTS
    None.

    .NOTES
    Run Enable-WakeOnLan, a function in the PSSystemAdministrator module, on computers that you want to start using this function. This will ensure Start-Computer will work on them.

    May not work on computers with manually set static IP addresses. DHCP reservations should work.

    .EXAMPLE
    Start-Computer -Name SERVER1

    Starts SERVER1 if it is powered down.

    .EXAMPLE
    "Computer1","Computer2" | Start-Computer

    .EXAMPLE
    Get-ADComputer -Filter * | Start-Computer

    Attempts to start all computers that are part of the domain.

    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically

    .LINK
    Based on: https://gallery.technet.microsoft.com/scriptcenter/Send-WOL-packet-using-0638be7b/view/Discussions#content 
    #>

    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [Alias("ComputerName")]
        [string]$Name
    )

    begin{
        $domainController = (Get-ADDomainController).Name
        $scopeID = (Get-DhcpServerv4Scope -ComputerName $domainController).ScopeID
        $UdpClient = New-Object System.Net.Sockets.UdpClient
        $UdpClient.Connect(([System.Net.IPAddress]::Broadcast),7)
    }

    process{
        $computerMAC = (Get-DhcpServerv4Lease -ComputerName $domainController -ScopeId $scopeID | Where-Object -Property hostname -match $Name).clientid
        $MacByteArray = $computerMAC -split "-" | ForEach-Object { "0x$_"}
        $MagicPacketHeader = "0xFF","0xFF","0xFF","0xFF","0xFF","0xFF"
        $MagicPacketRaw = $MagicPacketHeader + ($MacByteArray  * 16)
        $MagicPacket = $MagicPacketRaw | ForEach-Object { [Byte]$_ }
        $UdpClient.Send($MagicPacket,$MagicPacket.Length) | Out-Null
        Write-Host "Magic packet sent to $Name."
    }
    
    end{
        $UdpClient.Close()
    }
}

function Test-NetworkSpeed{
    <#
    .SYNOPSIS
        
    .DESCRIPTION
        
    .PARAMETER Name
    
    .INPUTS
    
    .OUTPUTS
    
    .NOTES
    
    .EXAMPLE
    
    .LINK
    By Ben Peterson
    linkedin.com/in/benponline
    github.com/benponline
    twitter.com/benponline
    paypal.me/teknically 
    #>

    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [Alias("FullName")]
        [string[]]$DestinationDirectory,

        [int]$Count = 5,

        [int]$FileSizeMB = 100
    )

    begin{
        $sourceFilePath = "$PSScriptRoot\TextFile.txt"
        $fileContent = "1" * (1MB * $FileSizeMB)
        New-Item -Path $sourceFilePath -ItemType File -Value $fileContent -Force | Out-Null
        $results = @()
    }

    process{
        foreach($dir in $DestinationDirectory){
            $destinationFilePath = "$dir\TextFile.txt"
            $totalMBPerSecond = 0
         
            for ($i = 0; $i -lt $Count; $i++) {
                $copy = Measure-Command -Expression { Copy-Item -Path $sourceFilePath -Destination $destinationFilePath -Force }
                $copyMilliseconds = $copy.Milliseconds
                $MBPerSecond = [Math]::Round($FileSizeMB / $copyMilliseconds * 1000) 
                $totalMBPerSecond += $MBPerSecond
            }

            $averageMBPerSecond = [Math]::Round($totalMBPerSecond / $count)

            $results += [PSCustomObject]@{
                SourceMachine = $env:ComputerName;
                DestinationDirectory = $dir;
                FileSizeMB = $FileSizeMB;
                MbPerSecond = $averageMBPerSecond
            }

            Remove-Item -Path $destinationFilePath -Force
        }
    }

    end{
        Remove-Item -Path $sourceFilePath -Force
        return $results            
    }
}