<#
PSSystemAdministrator

Ben Peterson
linkedin.com/in/benponline
github.com/benponline
twitter.com/benponline
paypal.me/teknically
#>

function Disable-Computer{
    <#
    .SYNOPSIS
    Disables a computer or group of computers.

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
        $computer = Get-ADComputer $Name
        $disabledComputers += $computer
    }

    end{
        return $disabledComputers | Sort-Object -Property Name
    }
}

function Disable-User{
    <#
    .SYNOPSIS
    Disables a user or group of users.

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
        $user = Get-ADUser $SamAccountName
        $disabledUsers += $user
    }

    end{
        return $disabledUsers | Sort-Object -Property SamAccountName
    }
}

function Get-AccessedFile{
    <#
    .SYNOPSIS
    Gets all files in a directory that have been accessed recently.
    
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
        return $files | Sort-Object -Property LastAccessTime
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

    return $computers | Sort-Object -Property Name
}

function Get-ActiveFile{
    <#
    .SYNOPSIS
    Gets all files in a directory that have been written to recently.
    
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
        return $files | Sort-Object -Property LastWriteTime
    }
}

function Get-ActiveUser{
    <#
    .SYNOPSIS
    Gets a list of all users in Active Directory that have logged onto the domain within a number of days.

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

    return $users | Sort-Object -Property SamAccountName
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
        return $files | Sort-Object -Property LastAccessTime
    }
}

function Get-ChildItemLastWriteTime{
    <#
    .SYNOPSIS
    This function gathers all files in a directory and returns information including last write time.
    
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
        return $files | Sort-Object -Property LastWriteTime
    }
}

function Get-ComputerCurrentUser{
    <#
    .SYNOPSIS
    Gets the currently logged in user on a computer.

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
        $computerUserList += [PSCustomObject]@{
            Name = $Name;
            CurrentUser = (Get-CimInstance -ComputerName $Name -ClassName Win32_ComputerSystem -Property UserName).UserName
        }
    }

    end{
        return $computerUserList
    }
}

function Get-ComputerDriveInformation{
    <#
    .SYNOPSIS
    Gets information about the drives on a computer or computers.

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
        $driveInformationList = $driveInformationList | Where-Object -Property SizeGB -NE 0 #| Where-Object -Property VolumeName -NotMatch "Recovery"
        return $driveInformationList | Select-Object -Property Computer,DeviceID,VolumeName,SizeGB,FreeGB,Under20Percent | Sort-Object -Property Computer
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
    #>

    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [Alias('ComputerName')]
        [string]$Name = "$env:COMPUTERNAME",
        [int]$DaysBack = 1
    )

    begin{
        $failedLoginList = @()
        $date = (Get-Date).AddDays($DaysBack * -1)
    }

    process{
        try{
            $failedLoginList += Get-WinEvent -ComputerName $Name -FilterHashtable @{LogName='Security';ID=4625; StartTime=$date} | 
                Select-Object -Property @{n='Name';e={$Name}},TimeCreated,Id,Message
        }catch{

        }
    }

    end{
        return $failedLoginList
    }
}

function Get-ComputerInformation{
    <#
    .SYNOPSIS
    Gets infomation about a computer or computers.

    .DESCRIPTION
    This function gathers infomation about a computer or computers. By default it gathers info from the local host.

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
        $computerInfoList = @()
    }

    process{
        $computerObjectProperties = @{
            "Name" = "";
            "Model" = "";
            "Processor" = "";
            "MemoryGB" = "";
            "CDriveGB" = "";
            "CurrentUser" = "";
            "IPAddress" = "";
            "LastBootupTime" = "";
            "LastLogonTime" = ""
        }

        if(Test-Connection -ComputerName $Name -Count 1 -Quiet){

            $computerInfo = New-Object -TypeName PSObject -Property $computerObjectProperties
            $computerInfo.Name = $Name
            $computerInfo.Model = (Get-ComputerModel -Name $Name).Model
            $computerInfo.Processor = (Get-ComputerProcessor -Name $Name).Processor
            $computerInfo.MemoryGB = (Get-ComputerMemory -Name $Name).MemoryGB
            $computerInfo.CDriveGB = (Get-ComputerDriveInformation -Name $Name | Where-Object -Property DeviceID -Match 'C').SizeGB
            $computerInfo.CurrentUser = (Get-ComputerCurrentUser -Name $Name).CurrentUser
            $computerInfo.IPAddress = (Get-ComputerIPAddress -Name $Name).IPAddress
            $computerInfo.LastBootupTime = (Get-ComputerLastBootUpTime -Name $Name).LastBootupTime
            $computerInfo.LastLogonTime = (Get-ComputerLastLogonTime -Name $Name).LastLogonTime
            $computerInfoList += $computerInfo
        }
    }

    end{
        return $computerInfoList | Select-Object -Property Name,Model,Processor,MemoryGB,CDriveGB,CurrentUser,IPAddress,LastBootupTime,LastLogonTime | Sort-Object -Property Name
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

        if($Name -eq $env:COMPUTERNAME){
            $ipAddress = (Get-NetIPAddress | Where-Object {$_.PrefixOrigin -eq 'dhcp'}).IPAddress
        }else{
            $ipAddress = (Test-Connection -TargetName $Name -Count 1).Address.IPAddressToString
        }

        $computerIPList += [PSCustomObject]@{
            Name = $Name;
            IPAddress = $ipAddress 
        }
    }

    end{
        return $computerIPList
    }
}

function Get-ComputerLastBootUpTime{
    <#
    .SYNOPSIS
    Gets the last time a computer or computers has booted up.

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
        $lastBootUpTimeList += Get-CimInstance -ComputerName $Name -Class win32_operatingsystem -Property LastBootUpTime | 
            Select-Object -Property @{n='Name';e={$_.pscomputername}},LastBootUpTime
    }

    end{
        return $lastBootUpTimeList | Select-Object -Property Name,LastBootUpTime | Sort-Object -Property Name
    }
}

function Get-ComputerLastLogonTime{
    <#
    .SYNOPSIS
    Gets the last time a computer, or group of computers, logged onto the domain.

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
    }

    process{
        $lastLogonList += Get-ADComputer $Name | 
            Get-ADObject -Properties lastlogon | 
            Select-Object -Property @{n="Name";e={$Name}},@{n="LastLogonTime";e={([datetime]::fromfiletime($_.lastlogon))}}
    }

    end{
        return $lastLogonList | Select-Object -Property Name,LastLogonTime | Sort-Object -Property Name
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
    The memory in GB of the computer with this name will be returned. By defualt it is the local computers.

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
    Get the operating system name of a computer or computers.

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
    Gets the health status of the physical disks of a computer or computers.

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
        return $physicalDiskList | Select-Object -Property ComputerName,FriendlyName,MediaType,OperationalStatus,HealthStatus,SizeGB | Sort-Object -Property ComputerName
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
    This function returns all of the share folders on a computer.
    
    .DESCRIPTION
    This function returns all of the share folders on a computer or remote computer.
    
    .PARAMETER Name
    This is the computer that the function will search for share folders.
    
    .INPUTS
    Can accept AD computer objects from the pipeline.
    
    .OUTPUTS
    PS objects with the computer name, share folder name, path to the folder, and status of the folder.
    
    .NOTES

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
        $computerShareList = @()
    }

    process{
        $computerShares = Get-FileShare -CimSession $Name
        
        foreach($rawShare in $computerShares){

            $computerShareList += [PSCustomObject]@{
                Name = $Name;
                ShareName = $rawShare.Name;
                Path = $rawShare.VolumeRelativePath;
                Status = $rawShare.OperationalStatus
            }
        }
    }

    end{
        return $computerShareList | Sort-Object -Property Name
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
        $masterKeys = @()
    }

    process{
        $lmKeys = "Software\Microsoft\Windows\CurrentVersion\Uninstall","SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
        $lmReg = [Microsoft.Win32.RegistryHive]::LocalMachine
        $cuKeys = "Software\Microsoft\Windows\CurrentVersion\Uninstall"
        $cuReg = [Microsoft.Win32.RegistryHive]::CurrentUser

        if((Test-Connection -ComputerName $Name -Count 1)){
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

                if($null -ne $regKey){

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
        }
    }

    end{
        $woFilter = {$null -ne $_.name -AND $_.SystemComponent -ne "1" -AND $null -eq $_.ParentKeyName}
        $props = 'ComputerName','Name','Version','Installdate','UninstallCommand','RegPath'
        $masterKeys = ($masterKeys | Where-Object $woFilter | Select-Object -Property $props | Sort-Object -Property ComputerName)
        return $masterKeys
    }
}

function Get-ComputerSystemEvent{
    <#
    .SYNOPSIS
    Gets system errors from a computer or computers.

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

    This cmdlet returns the last 5 system errors from localhost.

    .EXAMPLE
    Get-ComputerError -ComputerName Server -Newest 2

    This cmdlet returns the last 2 system errors from server.

    .EXAMPLE
    "computer1","computer2" | Get-ComputerError

    This cmdlet returns newest 5 system errors from "computer1" and "computer2".

    .EXAMPLE
    Get-ADComputer Computer1 | Get-ComputerError

    This cmdlet returns the last 5 system errors from Computer1.

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
        $errorLog = @()
    }

    process{
        $errorLog += Get-WinEvent -LogName System -ComputerName $Name -MaxEvents $Newest | 
            Select-Object -Property @{n='Name';e={$Name}},TimeCreated,Id,LevelDisplayName,Message
    }

    end{
        return $errorLog
    }
}

function Get-CredentialExportToXML{
    <#
    .SYNOPSIS
    This function gets credentials from the user and exports them to location provided by the user.

    .DESCRIPTION
    This function promps the user for a user name and password. It encryps the password and saves it all to an XML file at the path provided to the function. You can then import these credentials in other functions and scripts that require credentials without having to hard code them in.
    
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
    Source: https://www.gngrninja.com/script-ninja/2016/5/24/powershell-calculating-folder-sizes
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
        $directorySize = (Get-ChildItem -Path $Path -File -Recurse | Measure-Object -Sum Length).sum

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
    Gets a list of all computers in AD that are currently disabled.

    .DESCRIPTION
    Gets a list of computers from AD that are disabled with information including name, enabled status, DNSHostName, and DistinguishedName.

    .PARAMETER OrganizationalUnit
    Focuses the function on a specific AD organizational unit.

    .INPUTS
    None.

    .OUTPUTS
    PS objects with information including Name, Enabled status, DNSHostName, and DistinguishedName.

    .NOTES
    Firewalls must be configured to allow ping requests.

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
        $disabledComputers = Get-ADComputer -Filter * | Where-Object -Property Enabled -Match False
    }else{
        $disabledComputers = Get-OUComputer -OrganizationalUnit $OrganizationalUnit | 
            Where-Object -Property Enabled -Match False
    }

    return $disabledComputers | Select-Object -Property Name,Enabled,DNSHostName,DistinguishedName | Sort-Object -Property Name
}

function Get-DisabledUser{
    <#
    .SYNOPSIS
    Gets a list of all users in AD that are currently disabled. 

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
        $disabledUsers = Get-ADUser -Filter * | Where-Object -Property Enabled -Match False
    }else{
        $disabledUsers = Get-OUUser -OrganizationalUnit $OrganizationalUnit | Where-Object -Property Enabled -Match False
    }

    return $disabledUsers | Select-Object -Property Name,Enabled,UserPrincipalName | Sort-Object -Property Name
}

###
function Get-InactiveComputer{
    <#
    .SYNOPSIS
    Gets a list of computers that have been offline for a specific number of days.

    .DESCRIPTION
    Gets a list of computers in AD that have not been online a number of days. The default amount of days is 30. By default all computers are checked. Can be limited to a specific organizational unit.

    .PARAMETER Days
    Determines how long the computer account has to be inactive for it to be returned.

    .PARAMETER OrganizationalUnit
    Focuses the function on a specific organizational unit.

    .INPUTS
    None.

    .OUTPUTS
    PS objects with information including computer names and the date they were last connected to the domain.

    .NOTES

    .EXAMPLE
    Get-InactiveComputer

    Lists all computers in the domain that have not been online for more than 6 months.

    .EXAMPLE
    Get-InactiveComputer -Days 35

    Lists all computers in the domain that have not been on the network for 35 days.

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

    return $computers | Sort-Object -Property Name
}

function Get-InactiveFile{
    <#
    .SYNOPSIS
    Gets all files in a directory that have not been accessed recently.
    
    .DESCRIPTION
    Gets all files in a directory recursively that have not been access recently. Returns file name, last access time, size in MB, and full name.
    
    .PARAMETER Path
    Function will gather all files recursively from this directory.

    .PARAMETER Days
    Function will return only files that have not been accessed for over this many days. By default is set to 0 and function returns all files.

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
        return $files | Sort-Object -Property LastWriteTime
    }
}

function Get-InactiveUser{
    <#
    .SYNOPSIS
    Gets a list of all the users in AD that have logged on for a period of time.

    .DESCRIPTION
    Gets a list of users in active directory that have been inactive for a number of days. The default number of days is 30. Function can also be focused on a specific OU.

    .PARAMETER Days
    Determines how long the user account has to be inactive for it to be returned.

    .PARAMETER OrganizationalUnit
    Focuses the function on a specific AD organizational unit.

    .INPUTS
    None.

    .OUTPUTS
    PS objects with user names and last logon date.

    .NOTES
    Function is intended to help find inactive user accounts.

    .EXAMPLE
    Get-InactiveUser

    Lists all users in the domain that have not checked in for more than 30 days.

    .EXAMPLE
    Get-InactiveUser -Days 2

    Lists all users in the domain that have not checked in for more than 2 days.

    .EXAMPLE
    Get-InactiveUser -Days 45 -OrganizationalUnit "Company Servers"

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
            Where-Object -Property LastLogon -LT ((Get-Date).AddDays($Days * -1))
    }else{
        $users = Get-OUUser -OrganizationalUnit $OrganizationalUnit | 
            Get-UserLastLogonTime |
            Where-Object -Property LastLogon -LT ((Get-Date).AddDays($Days * -1))
    }

    return $users | Sort-Object -Property SamAccountName
}

function Get-LargeFile{
    <#
    .SYNOPSIS
    Gets files larger than 500 MB.
 
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
        $largeFiles += Get-ChildItem -Path $Path -File -Recurse | Where-Object -Property Length -GT ($Megabytes * 1000000)
    }

    end{
        $largeFiles = $largeFiles | Select-Object -Property Name,@{n="SizeMB";e={[math]::round(($_.Length / 1MB),1)}},FullName
        return $largeFiles | Sort-Object -Property Name
    }
}

function Get-OfflineComputer{
    <#
    .SYNOPSIS
    Gets a list of all computers in AD that are currently offline. 

    .DESCRIPTION
    Gets a list of computers from AD that are offline with information including name, DNS host name, and distinguished name. By default searches the whole AD. Can be limited to a specific organizational unit.

    .PARAMETER OrganizationalUnit
    Focuses the function on a specific AD organizational unit.

    .INPUTS
    None.

    .OUTPUTS
    PS objects with information including name, DNS host name, and distinguished name.

    .NOTES
    Firewalls must be configured to allow ping requests.

    .EXAMPLE
    Get-OfflineComputer

    Returns a list of all AD computers that are currently offline.

    .EXAMPLE
    Get-OfflineComputer -OrganizationalUnit "WorkStations"

    Returns a list of all AD computers that are currently offline in the "Workstations" organizational unit.

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
    
    return $offlineComputers | Select-Object -Property Name,DNSHostName,DistinguishedName | Sort-Object -Property Name
}

function Get-OnlineComputer{
    <#
    .SYNOPSIS
    Gets a list of AD computers that are currently online.

    .DESCRIPTION
    Gets an array of PS objects containing the name, DNS host name, and distinguished name of AD computers that are currently online. 

    .PARAMETER OrganizationalUnit
    Focuses the function on a specific AD organizational unit.

    .INPUTS
    None.

    .OUTPUTS
    PS objects containing name, DNS host name, and distinguished name.

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
    Param(
        [string]$OrganizationalUnit = ""
    )

    if($OrganizationalUnit -eq ""){
        $computers = Get-ADComputer -Filter *
    }else{
        $computers = Get-OUComputer -OrganizationalUnit $OrganizationalUnit
    }

    $onlineComputers = @()
    
    foreach($computer in $computers){
        if(Test-Connection -ComputerName ($computer.name) -Count 1 -Quiet){
            $onlineComputers += $computer
        }
    }
    
    #$onlineComputers | Select-Object -Property Name,DNSHostName,DistinguishedName
    return $onlineComputers
}

function Get-OUComputer{
    <#
    .SYNOPSIS
    Gets computers from a specific organizational unit in Active Directory.
    
    .DESCRIPTION
    Gets a computer AD objects for each computer in an AD organizaitional unit. 
    
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
    Gets users from a specific organizational unit in Active Directory.
    
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
    Gets sub directory names and sizes.

    .DESCRIPTION
    Returns a list of directories and their sizes from the submitted path.

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
        $directories = Get-ChildItem -Path $Path -Directory

        foreach($dir in $directories){
            $directorySizes += Get-DirectorySize -Path $dir.FullName
        }
    }

    end{
        return $directorySizes
    }
}

function Get-UserActiveLogon{ #add message to host when computer can't be reached.
    <#
    .SYNOPSIS
    Finds all computers where a specific user, or users, is logged in.

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
            $computers = (Get-ADComputer -Filter *).Name | Sort-Object
        }else{
            $computers = (Get-OUComputer -OrganizationalUnit $OrganizationalUnit).Name | Sort-Object
        }
    }

    process{

        foreach($computer in $computers){
            $currentUser = (Get-ComputerCurrentUser -Name $computer).CurrentUser

            if(!$null -eq $currentUser){
                $currentUser = $currentUser.split('\')[-1]

                if($SamAccountName -eq $currentUser){
                    $computerList += New-Object -TypeName PSObject -Property @{"User"="$currentUser";"Computer"="$computer"}
                }
            }
        }
    }

    end{
        return $computerList
    }
}

function Get-UserLastLogonTime{
    <#
    .SYNOPSIS
    Gets the last time a user, or group of users, logged onto the domain.

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
    }

    process{
        $lastLogonList += Get-ADuser $SamAccountName | 
            Get-ADObject -Properties lastlogon | 
            Select-Object -Property @{n="SamAccountName";e={$SamAccountName}},@{n="LastLogon";e={([datetime]::fromfiletime($_.lastlogon))}}
    }

    end{
        return $lastLogonList | Select-Object -Property SamAccountName,LastLogon | Sort-Object -Property SamAccountName
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
        $user = Get-ADUser -Identity $Name
        $movedUsers += $user
    }

    end{
        return $movedUsers | Sort-Object -Property SamAccountName
    }
}

function Remove-Computer{
    <#
    .SYNOPSIS
    Removes a computer from AD.

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
        [string]$Name = $env:COMPUTERNAME
    )

    begin{
        $computers = @()
    }

    process{
        $computers += Get-ADComputer $Name
    }

    end{
        $computers | Remove-ADComputer
        return $computers | Sort-Object -Property Name
    }
}

function Remove-User{
    <#
    .SYNOPSIS
    Removes a user from AD.

    .DESCRIPTION
    Removes a user or users from AD and returns a list of users that were removed.

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
        [string]$SamAccountName = $env:USERNAME
    )

    begin{
        $users = @()
    }

    process{
        $users += Get-ADUser $Name
    }

    end{
        $users | Remove-ADUser
        return $users | Sort-Object -Property SamAccountName
    }
}

function Reset-UserPassword{
    <#
    .SYNOPSIS
    This function triggers an AD user account to require a password change at the next log in.
    
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

    [cmdletbinding()]#Does not take objects from the pipeline
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
        return $userList | Sort-Object -Property Name
    }
    
}

function Set-ComputerIP{
    <#
    .SYNOPSIS
    Sets the IP address of a domain computer.

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

    .EXAMPLE
    Set-ComputerIP -ComputerName "Computer2" -IPAddress 10.10.10.10

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
            
    #Self adapter
    $SelfIPAddress = (Test-Connection -ComputerName $env:COMPUTERNAME -Count 1 -IPv4).Address.IPAddressToString
    $SelfIPInterfaceIndex = (Get-NetIPAddress | Where-Object -Property IPAddress -eq $SelfIPAddress).InterfaceIndex

    #Subnetmask / Prefixlength
    $SelfPrefixlength = (Get-NetIPAddress | Where-Object -Property IPAddress -eq $SelfIPAddress).PrefixLength

    #Default Gateway
    $SelfDefaultGateway = (Get-NetRoute | Where-Object -Property DestinationPrefix -eq '0.0.0.0/0').NextHop

    #DNS
    $SelfDNS = (Get-DnsClientServerAddress -InterfaceIndex $SelfIPInterfaceIndex -AddressFamily IPv4).ServerAddresses
    $TargetIPAddress = (Test-Connection -ComputerName $ComputerName -Count 1 -IPv4).Address.IPAddressToString

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
        #Invoke-Command -ComputerName $ComputerName -ScriptBlock {netsh interface ip set dnsservers name="$TargetIPInterfaceAlias" address="$SelfDNS1" static primary}
        
        if($SelfDNS.count -gt 1){
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {netsh interface ip add dnsservers name="$using:TargetIPInterfaceAlias" address="$using:SelfDNS2"}
        }

        Invoke-Command -ComputerName $ComputerName -ScriptBlock {netsh interface ip set address $using:TargetIPInterfaceAlias static $using:IPAddress $using:SubnetMask $using:SelfDefaultGateway}
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
        [string]$BroadcastIP=([System.Net.IPAddress]::Broadcast)
        [int]$port=9
        $broadcast = [Net.IPAddress]::Parse($BroadcastIP)
        $domainController = (Get-ADDomainController).Name
        $scopeID = (Get-DhcpServerv4Scope -ComputerName $domainController).ScopeID
    }

    process{
        $ComputerMACs = (Get-DhcpServerv4Lease -ComputerName $domainController -ScopeId $scopeID | Where-Object -Property hostname -match $Name).clientid

        ForEach($ComputerMAC in $ComputerMACs){

            try{
                $ComputerMAC = (($ComputerMAC.replace(":","")).replace("-","")).replace(".","")
                $target = 0,2,4,6,8,10 | ForEach-Object {[convert]::ToByte($ComputerMAC.substring($_,2),16)}
                $packet = (,[byte]255 * 6) + ($target * 16)
                $UDPclient = new-Object System.Net.Sockets.UdpClient
                $UDPclient.Connect($broadcast,$port)
                [void]$UDPclient.Send($packet, 102)
            }catch{}
        }

        Write-Host "Magic packet sent to $Name."
    }

    end{}
}