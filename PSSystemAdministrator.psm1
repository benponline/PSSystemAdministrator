############################

function Disable-Computer{

    <#

    .SYNOPSIS
    This function disables computers that are passed to it.

    .DESCRIPTION
    Users can pass host names or computer AD objects to this function. It will disable these computers in Active Directory and return an array of computer objects to the host. 

    .PARAMETER Name
    This is the host name of the computer that the user wants to disable.

    .INPUTS
    Computer AD objects can be passed to this function.

    .OUTPUTS
    An array of computer AD objects. One for each computer that this function disables.

    .NOTES

    .EXAMPLE 
    Disable-Computer -Name Computer1

    Disables the computer named Computer1 in Active Directory.

    .EXAMPLE
    "Computer1","Computer2" | Disable-Computer

    Disables computers Computer1 and Computer2 in Active Directory.

    .EXAMPLE
    Get-ADComputer Computer1 | Disable-Computer

    Disables Computer1 in Active Directory.

    .LINK
    By Ben Peterson
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

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

        #Update computer object to show disabled status.
        $computer = Get-ADComputer $Name
        $disabledComputers += $computer
    }

    end{
        $disabledComputers | Sort-Object -Property Name
        return
    }
}

function Disable-User{

    <#

    .SYNOPSIS
    This function disables users that are passed to it.

    .DESCRIPTION
    Users can pass sam account names  or user AD objects to this function. It will disable these users in Active Directory and return an array of user objects to the host. 

    .PARAMETER Name
    This is the user name, sam account name, of the user that will be disabled.

    .INPUTS
    User AD objects can be passed to this function.

    .OUTPUTS
    An array of user AD objects. One for each user that this function disables.

    .NOTES

    .EXAMPLE 
    Disable-User -Name User1

    Disables the user named User1 in Active Directory.

    .EXAMPLE
    "User1","User2" | Disable-User

    Disables users User1 and User2 in Active Directory.

    .EXAMPLE
    Get-ADUser User1 | Disable-User

    Disables User1 in Active Directory.

    .LINK
    By Ben Peterson
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

    #>

    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true,Mandatory=$True)]
        [Alias('SamAccountName')]
        [string]$Name
    )

    begin{
        $disabledUsers = @()
    }

    process{
        $user = Get-ADUser $Name
        $user | Disable-ADAccount
        $user = Get-ADUser $Name
        $disabledUsers += $user
    }

    end{
        $disabledUsers | Sort-Object -Property SamAccountName
        return
    }
}

function Get-ActiveFiles{

    <#

    .SYNOPSIS
    This function gathers all files in a directory that have been accessed recently.
    
    .DESCRIPTION
    This function gathers all files in a directory recursively that have been active recently. Returns file name, last access time, size in MB, and full name.
    
    .PARAMETER Path
    Function will gather all files recursively from this directory.

    .PARAMETER ActivityWindowInDays
    Function will return only files that have been accessed within this window.

    .INPUTS
    You can pipe multiple paths to this function.
    
    .OUTPUTS
    Array of PS objects that includes file names, last access time, size in MB, and full name.
    
    .NOTES

    .EXAMPLE
    Get-ActiveFiles -Path C:\Directory1 -ActivityWindowInDays 5

    Gathers all files recursively in the "Directory1" folder that have been accessed within 5 days.

    .EXAMPLE
    "C:\Directory1","C:\Directory2" | Get-ActiveFiles

    Gathers all files recursively in the "Directory1" and "Directory2" folders that have been accessed in the last day.
    
    .LINK
    By Ben Peterson
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

    #>

    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true,Mandatory=$True)]
        [Alias('FullName')]
        [string]$Path,
        [int]$ActivityWindowInDays = 1
    )

    begin{
        $files = @()
        $fileAge = (Get-Date).AddDays(-1*$ActivityWindowInDays)
    }

    process{
        $files += Get-ChildItem -Path $Path -File -Recurse | 
            Where-Object -Property LastAccessTime -GT $fileAge | 
            Select-Object -Property Name,LastAccessTime,@{n='SizeMB';e={[math]::Round(($_.Length/1MB),3)}},FullName
    }

    end{
        $files | Sort-Object -Property Name
        return
    }
}

function Get-ChildItemLastAccessTime{
    <#

    .SYNOPSIS
    This function gathers all files in a directory and returns information including last access time.
    
    .DESCRIPTION
    This function gathers all files in a directory recursively. Returns file name, last access time, size in MB, and full name.
    
    .PARAMETER Path
    Function will gather all files recursively from this directory.

    .INPUTS
    You can pipe multiple paths to this function.
    
    .OUTPUTS
    Array of PS objects that includes file names, last access time, size in MB, and full name.
    
    .NOTES

    .EXAMPLE
    Get-ChildItemLastAccessTime -Path C:\Directory1 -DaysInactive 5

    Gathers all files recursively in the "Directory1" folder that have not been accessed in over 5 days.

    .EXAMPLE
    "C:\Directory1","C:\Directory2" | Get-ChildItemLastAccessTime

    Gathers all files recursively in the "Directory1" and "Directory2" folders.
    
    .LINK
    By Ben Peterson
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

    #>

    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true,Mandatory=$True)]
        [Alias('FullName')]
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
        $files
        return
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
    You can pipe multiple paths to this function.
    
    .OUTPUTS
    Array of PS objects that includes file names, last write time, size in MB, and full name.
    
    .NOTES

    .EXAMPLE
    Get-ChildItemLastWriteTime -Path C:\Directory1 -DaysInactive 5

    Gathers all files recursively in the "Directory1" folder that have not been accessed in over 5 days.

    .EXAMPLE
    "C:\Directory1","C:\Directory2" | Get-ChildItemLastWriteTime

    Gathers all files recursively in the "Directory1" and "Directory2" folders.
    
    .LINK
    By Ben Peterson
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

    #>    

    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true,Mandatory=$True)]
        [Alias('FullName')]
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
        $files
        return
    }
}

function Get-ComputerError{

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
    Compatible with Windows 7 and newer. Not compatible with Powershell 7 or Core.

    Requires "Printer and file sharing", "Network Discovery", and "Remote Registry" to be enabled on computers that are searched. This funtion can take a long time to complete if more than 5 computers are searched.

    .EXAMPLE
    Get-ComputerError

    This cmdlet returns the last 5 system errors from localhost.

    .EXAMPLE
    Get-ComputerError -ComputerName Server -Newest 2

    This cmdlet returns the last 2 system errors from server.

    .EXAMPLE
    "computer1","computer2" | Get-ComputerError

    This cmdlet returns system errors from "computer1" and "computer2".

    .EXAMPLE
    Get-ADComputer Computer1 | Get-ComputerError

    This cmdlet returns the last 5 system errors from Computer1.

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

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
        #Get-WinEvent -LogName system -MaxEvents 10 | Where-Object -Property leveldisplayname -eq error
        $errorLog += Get-EventLog -ComputerName $Name -LogName System -EntryType Error -Newest $Newest | 
            Select-Object -Property @{n="ComputerName";e={$Name}},TimeWritten,EventID,InstanceID,Message
    }

    end{
        $errorLog | Sort-Object -Property ComputerName | Select-Object -Property ComputerName,TimeWritten,EventID,InstanceID,Message
        return
    }
}

function Get-ComputerInformation{

    <#

    .SYNOPSIS
    Gets infomation about a computer or computers.

    .DESCRIPTION
    This function gathers infomation about a computer or computers. By default it gathers info from the local host. The information includes computer name, model, CPU, memory in GB, storage in GB, the current user, IP address, and last bootuptime.

    .PARAMETER Name
    Specifies which computer's information is gathered.

    .INPUTS
    You can pipe host names or AD computer objects.

    .OUTPUTS
    Returns an object with computer name, model, CPU, memory in GB, storage in GB, the current user, IP address, and last boot time.

    .NOTES
    Compatible for Windows 7 and newer.

    Only returns information from computers running Windows 10 or Windows Server 2012 or higher.

    Will not return information on computers that are offline.

    .EXAMPLE
    Get-ComputerInformation

    Returns computer information for the local host.

    .EXAMPLE
    Get-ComputerInformation -Name Server1

    Returns computer information for Server1.

    .EXAMPLE
    Get-ADComputer -filter * | Get-ComputerInformation

    Returns computer information on all AD computers. 

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

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
            "ComputerName" = "";
            "Model" = "";
            "CPU" = "";
            "MemoryGB" = "";
            "StorageGB" = "";
            "CurrentUser" = "";
            "IPAddress" = "";
            "BootUpTime" = ""
        }

        if(Test-Connection -ComputerName $Name -Count 1 -Quiet){

            $computerInfo = New-Object -TypeName PSObject -Property $computerObjectProperties
            $computerInfo.computername = $Name
            $computerInfo.model = (Get-CimInstance -ComputerName $Name -ClassName Win32_ComputerSystem -Property Model).model
            $computerInfo.CPU = (Get-CimInstance -ComputerName $Name -ClassName Win32_Processor -Property Name).name
            $computerInfo.memoryGB = [math]::Round(((Get-CimInstance -ComputerName $Name -ClassName Win32_ComputerSystem -Property TotalPhysicalMemory).TotalPhysicalMemory / 1GB),1)
            $computerInfo.storageGB = [math]::Round((((Get-CimInstance -ComputerName $Name -ClassName win32_logicaldisk -Property Size) | 
                Where-Object -Property DeviceID -eq "C:").size / 1GB),1)

            if($Name -eq $env:COMPUTERNAME){
                $computerInfo.currentuser = [System.Security.Principal.WindowsIdentity]::GetCurrent().name
                $computerInfo.IPAddress = (Get-NetIPAddress -AddressFamily IPv4).IPAddress | Select-Object -First 1
            }else{
                $computerInfo.currentuser = (Get-CimInstance -ComputerName $Name -ClassName Win32_ComputerSystem -Property UserName).UserName
                $computerInfo.IPAddress = (Test-Connection -ComputerName $Name -Count 1).reply.address.ipaddresstostring
            }

            $computerInfo.BootUpTime = (Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $Name).LastBootUpTime
            $computerInfoList += $computerInfo
        }
    }

    end{
        $computerInfoList | Select-Object -Property ComputerName,Model,CPU,MemoryGB,StorageGB,CurrentUser,IPAddress,BootUpTime | Sort-Object -Property ComputerName
        return
    }
}

function Get-ComputerLastBootUpTime{

    <#

    .SYNOPSIS
    Gets the last time a computer or computers were connected to the domain.

    .DESCRIPTION
    Returns the name and last time a computer connected to the domain. By default targets localhost. Can target a remote computer, computers, or organizational unit.
    
    .PARAMETER Name
    Target computer.

    .PARAMETER OrganizationalUnit
    Targets computers in an organiational unit.

    .INPUTS
    Can pipe host names or AD computer objects to function.

    .OUTPUTS
    PS object with computer name and the last time is was connected to the domain.

    .NOTES
    Compatible with Windows 7 and newer.

    .EXAMPLE
    Get-ComputerLastLogon

    Returns the last time the local host logged onto the domain.

    .EXAMPLE
    Get-ComputerLastLogon -Name "Borg"

    Returns the last time the computer "Borg" logged onto the domain.

    .EXAMPLE
    Get-ComputerLastLog -OrganizationalUnit "Company Servers"

    Returns last logon time for computers in "Company Servers".

    .EXAMPLE
    "Computer1","Computer2" | Get-ComputerLastLogon

    Returns last logon time for "Computer1" and "Computer2".

    .LINK
    By Ben Peterson
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

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
            Select-Object -Property @{n='ComputerName';e={$_.pscomputername}},LastBootUpTime
    }

    end{
        $lastBootUpTimeList | Select-Object -Property ComputerName,LastBootUpTime | Sort-Object -Property ComputerName
        return
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
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

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

function Get-ComputerSoftware{

    <#

    .SYNOPSIS
    Gets all of the installed software on a computer or computers.

    .DESCRIPTION
    This function gathers all of the installed software on a computer or group of computers. By default gathers from the local host.

    .PARAMETER Name
    Specifies the computer this function will gather information from. 

    .PARAMETER OrganizationalUnit
    Targets computers in a specific organizational unit.

    .INPUTS
    You can pipe host names or computer AD objects input to this function.

    .OUTPUTS
    Returns PS objects containing computer name, software name, version, installdate, uninstall command, registry path.

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
    Get-ComputerSoftware -Filter * | Get-ComputerSoftware

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
        $masterKeys
        return
    }
}

function Get-CredentialExportToXML{

    <#
    
    .SYNOPSIS
    This function gets credentials from the user and exports them to location provided by the user.

    .DESCRIPTION
    This function promps the user for a user name and password. It encryps the password and saves it all to a CLIXML file at the path provided to the function. You can then import these credentials in other functions and scripts that require credentials without having to hard code them in.
    
    .PARAMETER FileName
    The name that will be given to the file containing the credentials. Do not include file extention.

    .PARAMETER Path
    The location the credentials will be saved. Do not include trailing "\".

    .INPUTS
    None.

    .OUTPUTS
    CLIXML file with credentials.

    .NOTES

    .EXAMPLE
    Get-CredentialExportToXML -FileName Creds -Path C:\ScriptCreds

    Promps user for user name and password. Encryps the password and saves the credentials at C:\ScriptCreds\Creds.clixml

    .LINK
    By Ben Peterson
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

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
    Returns the size of a directors in GB.

    .PARAMETER Path
    Path to the directory to be measured.

    .INPUTS
    None.

    .OUTPUTS
    Returns object with directory path and size in GB.

    .NOTES

    .EXAMPLE
    Get-DirectorySize -Path C:\Users

    Returns the size of the Users folder.

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    .Link
    Source: https://www.gngrninja.com/script-ninja/2016/5/24/powershell-calculating-folder-sizes

    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [Alias('Directory')]
        [string] $Path
    )

    $folderSize = (Get-ChildItem -Path $Path -File -Recurse | Measure-Object -Sum Length).sum
    $folderInfo += [PSCustomObject]@{
        Directory = $Path;
        SizeGB = [math]::round(($folderSize / 1GB),2)
    }

    $folderInfo
    return
}

function Get-DisabledComputers{

    <#

    .SYNOPSIS
    Gets a list of all computers in AD that are currently disabled.

    .DESCRIPTION
    Returns a list of computers from AD that are disabled with information including name, enabled status, DNSHostName, and DistinguishedName.

    .PARAMETER OrganizationalUnit
    Focuses the function on a specific AD organizational unit.

    .INPUTS
    None.

    .OUTPUTS
    PS objects with information including name, enabled status, DNSHostName, and DistinguishedName.

    .NOTES
    Firewalls must be configured to allow ping requests.

    .EXAMPLE
    Get-ADDisabledComputer

    Returns a list of all AD computers that are currently disabled.

    .EXAMPLE
    Get-ADDisabledComputer -OrganizationalUnit "Servers"

    Returns a list of all AD computers in the organizational unit "Servers" that are currently disabled.


    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    #>

    [CmdletBinding()]
    Param(
        [string]$OrganizationalUnit = ""
    )
    
    $domainInfo = (Get-ADDomain).DistinguishedName
    
    if($OrganizationalUnit -eq ""){
        $disabledComputers = Get-ADComputer -Filter * | Where-Object -Property Enabled -Match False
    }else{
        $disabledComputers = Get-ADComputer -Filter * -SearchBase "ou=$OrganizationalUnit,$domainInfo" | 
            Where-Object -Property Enabled -Match False
    }

    $disabledComputers | Select-Object -Property Name,Enabled,DNSHostName,DistinguishedName | Sort-Object -Property Name
    return
}

function Get-DisabledUsers{
    
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
    Get-DisabledUsers

    Returns a list of all AD users that are currently disabled.

    .EXAMPLE
    Get-DisabledUsers -OrganizationalUnit "Employees"

    Returns a list of all AD users that are currently disabled in the "Employees" organizational unit.

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    #>

    [CmdletBinding()]
    Param(
        [string]$OrganizationalUnit = ""
    )

    $domainInfo = (Get-ADDomain).DistinguishedName 
    
    if($OrganizationalUnit -eq ""){
        $disabledUsers = Get-ADUser -Filter * | Where-Object -Property Enabled -Match False
    }else{
        $disabledUsers = Get-ADUser -Filter * -SearchBase "ou=$OrganizationalUnit,$domainInfo" | Where-Object -Property Enabled -Match False
    }

    $disabledUsers | Select-Object -Property Name,Enabled,UserPrincipalName | Sort-Object -Property Name
    return
}

function Get-FailedLogon{

    <#

    .SYNOPSIS
    Gets a list of failed logon events from a computer or computers.

    .DESCRIPTION
    This function returns failed logon events from the local computer, remote computer, or group of computers.

    .PARAMETER Name
    Specifies the computer the function gathers information from.

    .PARAMETER DaysBack
    Determines how many days in the past the function will search for failed log ons.

    .INPUTS
    You can pipe host names or AD computer objects.

    .OUTPUTS
    PS objects with computer names, time written, and event IDs for failed logon events.

    .NOTES
    Compatible with Windows 10.

    Not compatible with Powershell 7 or Core.

    .EXAMPLE
    Get-FailedLogon

    Returns failed logon events from the local host.

    .EXAMPLE
    Get-FailedLogon -Name "Server1"

    Returns failed logon events from computer "Server1".

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    #>

    [CmdletBinding()]
    Param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [Alias('ComputerName')]
        [string]$Name = $env:COMPUTERNAME,
        [int]$DaysBack = 1
    )

    begin{
        $failedLoginList = @()
    }

    process{
        if(Test-Connection $Name -Count 1 -Quiet){
            #Get-WinEvent -LogName system -MaxEvents 10 | Where-Object -Property id -eq '4625' Where-Object -Property TimeCreated -GT Get-Date-1day
            $failedLoginList += Get-EventLog -ComputerName $Name -LogName Security -InstanceId 4625 -After ((Get-Date).AddDays($DaysBack * -1)) |
                Select-Object -Property @{n="ComputerName";e={$Name}},TimeWritten,EventID
        }
    }

    end{
        $failedLoginList | Select-Object -Property ComputerName,TimeWritten,EventID | Sort-Object -Property ComputerName
        return
    }
}

function Get-InactiveComputers{

    <#

    .SYNOPSIS
    Gets a list of computers that have been offline for a specific number of days.

    .DESCRIPTION
    Returns a list of computers in AD that have not been online a number of days. The default amount of days is 30. By default all computers are checked. Can be limited to a specific organizational unit.

    .PARAMETER DaysInactive
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
    Get-InactiveComputer -DaysInactive 35

    Lists all computers in the domain that have not been on the network for 35 days.

    .LINK
    By Ben Peterson
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

    #>

    [CmdletBinding()]
    Param(
        [int]$DaysInactive = 30,
        [string]$OrganizationalUnit = ""
    )

    $domainInfo = (Get-ADDomain).DistinguishedName
    
    if($OrganizationalUnit -eq ""){
        $computers = Get-ADComputer -Filter * | Get-ADObject -Properties lastlogon | Select-Object -Property name,lastlogon
    }else{
        $computers = Get-ADComputer -Filter * -SearchBase "ou=$OrganizationalUnit,$domainInfo" | Get-ADObject -Properties lastlogon | Select-Object -Property name,lastlogon
    }

    $lastLogonList = @()

    foreach($computer in $computers){

        if(!(Test-Connection -TargetName $computer.name -Count 1 -Quiet)){

            if(([datetime]::fromfiletime($computer.lastlogon)) -lt ((Get-Date).AddDays(($DaysInactive * -1)))){
                $lastLogonProperties = @{
                    "LastLogon" = ([datetime]::fromfiletime($computer.lastlogon));
                    "Name" = ($computer.name)
                }
        
                $lastLogonObject = New-Object -TypeName PSObject -Property $lastLogonProperties
                $lastLogonList += $lastLogonObject
            }
        }
    }
    
    $lastLogonList | Select-Object -Property Name,LastLogon | Sort-Object -Property Name
    return
}

function Get-InactiveFiles{

    <#

    .SYNOPSIS
    This function gathers all files in a directory that have not been accessed recently.
    
    .DESCRIPTION
    This function gathers all files in a directory recursively that have not been access recently. Returns file name, last access time, size in MB, and full name.
    
    .PARAMETER Path
    Function will gather all files recursively from this directory.

    .PARAMETER ActivityWindowInDays
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
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

    #>

    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true,Mandatory=$True)]
        [Alias('FullName')]
        [string]$Path,
        [int]$ActivityWindowInDays = 1
    )

    begin{
        $files = @()
        $fileAge = (Get-Date).AddDays(-1*$ActivityWindowInDays)
    }

    process{
        $files += Get-ChildItem -Path $Path -File -Recurse | 
            Where-Object -Property LastAccessTime -LT $fileAge | 
            Select-Object -Property Name,LastAccessTime,@{n='SizeMB';e={[math]::Round(($_.Length/1MB),3)}},FullName
    }

    end{
        $files
        return
    }
}

function Get-InactiveUsers{

    <#

    .SYNOPSIS
    Gets a list of all the users in AD that have been inactive for a period of time.

    .DESCRIPTION
    Returns a list of users in active directory that have been inactive for a number of days. The default number of days is 30. Function can also be focused on a specific OU.

    .PARAMETER MonthsOld
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

    Lists all users in the domain that have not checked in for more than 3 months.

    .EXAMPLE
    Get-InactiveUser -DaysInactive 2

    Lists all users in the domain that have not checked in for more than 2 days.

    .EXAMPLE
    Get-InactiveUser -DaysInactive 45 -OrganizationalUnit "Company Servers"

    Lists all users in the domain that have not checked in for more than 45 days in the "Company Servers" organizational unit.

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    #>

    [CmdletBinding()]
    Param(
        [int]$DaysInactive = 30,
        [string]$OrganizationalUnit = ""
    )

    $domainInfo = (Get-ADDomain).DistinguishedName 
    
    if($OrganizationalUnit -eq ""){
        $users = Get-ADUser -Filter * | Get-ADObject -Properties lastlogon | Select-Object -Property lastlogon,name
    }else{
        $users = Get-ADUser -Filter * -SearchBase "ou=$OrganizationalUnit,$domainInfo" | Get-ADObject -Properties lastlogon | Select-Object -Property lastlogon,name
    }
    
    $lastLogonList = @()

    foreach($user in $users){
    
        if(([datetime]::fromfiletime($user.lastlogon)) -lt ((Get-Date).AddDays($DaysInactive * -1))){
            $lastLogonProperties = @{
                "LastLogon" = ([datetime]::fromfiletime($user.lastlogon));
                "User" = ($user.name)
            }
            $lastLogonList += New-Object -TypeName PSObject -Property $lastLogonProperties
        }
    }
    
    $lastLogonList | Select-Object -Property User,LastLogon | Sort-Object -Property User
    return
}

function Get-LargeFiles{

    <#

    .SYNOPSIS
    This function returns files larger than a minimum set be the user.
 
    .DESCRIPTION
    Returns all files from a target directory that are larger than the minimum in MB set by the user. This function searches recursivly.
 
    .PARAMETER Path
    Sets the directory the function searches.

    .PARAMETER FileSizeMB
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
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

    #>

    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true,Mandatory=$True)]
        [Alias('Directory')]
        [string]$Path,
        [int]$FileSizeMB = 1000
    )

    begin{
        $largeFiles = @()
    }

    process{
        $largeFiles += Get-ChildItem -Path $Path -File -Recurse | Where-Object -Property Length -GT ($FileSizeMB * 1000000)
    }

    end{
        $largeFiles = $largeFiles | Select-Object -Property Name,@{n="FileSizeMB";e={[math]::round(($_.Length / 1MB),1)}},FullName
        $largeFiles | Sort-Object -Property Name
        return
    }
}

function Get-LocalDiskInformation{

    <#

    .SYNOPSIS
    Gets information about the local disks on a computer or computers.

    .DESCRIPTION
    Returns information from about the local disks on a computer, remote computer, or group of computers. The information includes computer name, drive, volume name, size, free space, and if the drive has less than 20% space left.

    .PARAMETER Name
    Specifies the computer the function will gather information from.

    .INPUTS
    You can pipe host names or AD computer objects.

    .OUTPUTS
    Returns PS objects to the host the following information about the drives on a computer: computer name, drive, volume name, size, free space, and indicates those under 20% desc space remaining.

    .NOTES
    Compatible with Window 7 and newer.

    Will only try to contact computers that are on and connected to the network.

    .EXAMPLE
    Get-LocalDiskInformation

    Gets local disk information for the local host.

    .EXAMPLE
    Get-LocalDiskInformation -computerName computer

    Gets local disk information for "computer".

    .EXAMPLE
    Get-LocalDiskInformation -Filter * | Get-DriveSpace

    Gets local disk information for all computers in AD.

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

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

        if(Test-Connection $Name -Count 1 -Quiet){
            $driveInformationList += Get-CimInstance -ComputerName $Name -ClassName win32_logicaldisk -Property deviceid,volumename,size,freespace,DriveType | 
            Where-Object -Property DriveType -EQ 3 | 
            Select-Object -Property @{n="Computer";e={$Name}},`
            @{n="Drive";e={$_.deviceid}},`
            @{n="VolumeName";e={$_.volumename}},`
            @{n="SizeGB";e={$_.size / 1GB -as [int]}},`
            @{n="FreeGB";e={$_.freespace / 1GB -as [int]}},`
            @{n="Under20Percent";e={if(($_.freespace / $_.size) -le 0.2){"True"}else{"False"}}}
        }
    }

    end{
        $driveInformationList = $driveInformationList | Where-Object -Property SizeGB -NE 0 | Where-Object -Property VolumeName -NotMatch "Recovery"
        $driveInformationList | Select-Object -Property Computer,Drive,VolumeName,SizeGB,FreeGB,Under20Percent | Sort-Object -Property Computer
        return
    }  
}

function Get-MappedNetworkDrive{

    <#

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
    Get-MappedNetworlDrive

    Gets mapped drive information for the local host.

    .EXAMPLE
    Get-MappedNetworlDrive -computerName computer

    Gets mapped drive information for "computer".

    .EXAMPLE
    Get-DriveInformation -Filter * | Get-DriveSpace

    Gets mapped drive information for all computers in AD.

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    #>

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
            $mappedDrives += Get-CimInstance -ComputerName $Name -ClassName win32_mappedlogicaldisk -Property deviceid,volumename,size,freespace,ProviderName | 
                Select-Object -Property @{n="Computer";e={$Name}},`
                @{n="Drive";e={$_.deviceid}},`
                @{n="VolumeName";e={$_.volumename}},`
                @{n="Path";e={$_.ProviderName}},`
                @{n="SizeGB";e={$_.size / 1GB -as [int]}},`
                @{n="FreeGB";e={$_.freespace / 1GB -as [int]}},`
                @{n="Under20Percent";e={if(($_.freespace / $_.size) -le 0.2){"True"}else{"False"}}}
        }
    }

    end{
        $mappedDrives
        return
    }
}

function Get-OfflineComputers{

    <#

    .SYNOPSIS
    Gets a list of all computers in AD that are currently offline. 

    .DESCRIPTION
    Returns a list of computers from AD that are offline with information including name, DNS host name, and distinguished name. By default searches the whole AD. Can be limited to a specific organizational unit.

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
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    #>

    [CmdletBinding()]
    Param(
        [string]$OrganizationalUnit = ""
    )

    $domainInfo = (Get-ADDomain).DistinguishedName 
    
    if($OrganizationalUnit -eq ""){
        $computers = Get-ADComputer -Filter *
    }else{
        $computers = Get-ADComputer -Filter * -SearchBase "ou=$OrganizationalUnit,$domainInfo"
    }

    $offlineComputers = @()
    
    foreach($computer in $computers){
    
        if(!(Test-Connection -ComputerName ($computer).name -Count 1 -Quiet)){
            $offlineComputers += $computer
        }
    }
    
    $offlineComputers | Select-Object -Property Name,DNSHostName,DistinguishedName | Sort-Object -Property Name
    return
}

function Get-OnlineComputers{

    <#

    .SYNOPSIS
    Gets a list of AD computers that are currently online.

    .DESCRIPTION
    Returns an array of PS objects containing the name, DNS host name, and distinguished name of AD computers that are currently online. 

    .PARAMETER OrganizationalUnit
    Focuses the function on a specific AD organizational unit.

    .INPUTS
    None.

    .OUTPUTS
    PS objects containing name, DNS host name, and distinguished name.

    .NOTES
    Firewalls must be configured to allow ping requests.

    .EXAMPLE
    Get-OnlineComputers

    Returns list of all AD computers that are currently online.

    .EXAMPLE
    Get-OnlineComputers

    Returns the online computers from an organizational unit.

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    #>

    [CmdletBinding()]
    Param(
        [string]$OrganizationalUnit = ""
    )

    $domainInfo = (Get-ADDomain).DistinguishedName 
    
    if($OrganizationalUnit -eq ""){
        $computers = Get-ADComputer -Filter *
    }else{
        $computers = Get-ADComputer -Filter * -SearchBase "ou=$OrganizationalUnit,$domainInfo"
    }

    $onlineComputers = @()
    
    foreach($computer in $computers){
        if(Test-Connection -ComputerName ($computer.name) -Count 1 -Quiet){
            $onlineComputers += $computer
        }
    }
    
    #$onlineComputers | Select-Object -Property Name,DNSHostName,DistinguishedName
    $onlineComputers
    return
}

function Get-OUComputers{

    <#

    .SYNOPSIS
    This function returns computers from a specific organizational unit in Active Directory.
    
    .DESCRIPTION
    This function returns computer AD objects for each computer in an AD organizaitional unit. 
    
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
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

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
        $computers
        return
    }
}

function Get-OUUsers{

    <#

    .SYNOPSIS
    This function returns users from a specific organizational unit in Active Directory.
    
    .DESCRIPTION
    This function returns user AD objects for each user in an AD organizaitional unit. 
    
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
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

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
        $users
        return
    }
}

function Get-PhysicalDiskInformation{

    <#

    .SYNOPSIS
    Gets the health status of the physical disks of a computer or computers.

    .DESCRIPTION
    Returns the health status of the physical disks of the local computer, remote computer, group of computers, or computers in an organizational unit.

    .PARAMETER Name
    Specifies the computer the fuction will gather information from.

    .PARAMETER OrganizationalUnit
    Pulls information from computers in an organizational unit.

    .INPUTS
    You can pipe host names or AD computer objects.

    .OUTPUTS
    Returns objects with disk info including computer name, friendly name, media type, operational status, health status, and size in GB.

    .NOTES
    Only returns information from computers running Windows 10 or Windows Server 2012 or higher.

    .EXAMPLE
    Get-PhysicalDiskInformation

    Returns disk health information for the local computer.

    .EXAMPLE
    Get-PhysicalDiskInformation -Name Computer1

    Returns disk health information for the computer named Computer1.

    .EXAMPLE
    "computer1","computer2" | Get-PhysicalDiskInformation

    Returns physical disk information from "computer1" and "computer2".

    .EXAMPLE
    Get-PhysicalDiskInformation -OrganizationalUnit "Company Servers"

    Returns physical disk information from all computers in the "Company Servers" organizational unit.

    .LINK
    By Ben Peterson
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

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
        $physicalDiskList | Select-Object -Property ComputerName,FriendlyName,MediaType,OperationalStatus,HealthStatus,SizeGB | Sort-Object -Property ComputerName
        Return
    }
}

function Get-SubDirectorySize{

    <#

    .SYNOPSIS
    Gets sub directory names and sizes at a particular path.

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
    Get-SubDirectorySize -Path C:\Users

    Gets the name and size of all folders contained in the Users directory.

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    .Link
    Source: https://www.gngrninja.com/script-ninja/2016/5/24/powershell-calculating-folder-sizes

    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string] $Path
    )

    $foldersInfo = @()
    $folders = Get-ChildItem -Path $Path -Directory

    foreach($folder in $folders){

        $folderSize = (Get-ChildItem -Path $folder.fullname -File -Recurse | 
            Measure-Object -Sum Length).sum

        $foldersInfo += [PSCustomObject]@{
            Directory = $folder.fullname;
            SizeGB = [math]::round(($folderSize / 1GB),2)
        }

    }

    $foldersInfo
    return
}

function Get-UserActiveLogon{

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
    Find-UserLogin -Name Thor

    Returns a list of computers where Thor is logged in.  

    .EXAMPLE
    "Thor","Loki","Oden" | Find-UserLogin 

    Returns a list of computer where each of these users are logged in. 

    .LINK
    By Ben Peterson
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

    #>

    [CmdletBinding()]
    Param(
        [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [string]$SamAccountName,
        [string]$OrganizationalUnit = ""
    )

    begin{
        $computerList = @()
        $domainInfo = (Get-ADDomain).DistinguishedName

        if($OrganizationalUnit -eq ""){
            $computers = (Get-ADComputer -Filter *).Name | Sort-Object
        }else{
            $computers = (Get-ADComputer -Filter * -SearchBase "ou=$OrganizationalUnit,$domainInfo").Name | Sort-Object
        }
    }

    process{

        foreach($computer in $computers){

            try{

                if($computer -eq $env:COMPUTERNAME){
                    $currentUser = ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name).split('\')[-1]
                }else{
                    $currentUser = ((Get-CimInstance -ComputerName $computer -ClassName "Win32_ComputerSystem" -Property "UserName").UserName).split('\')[-1]
                }

                if($currentUser -eq $SamAccountName){
                    $computerList += New-Object -TypeName PSObject -Property @{"User"="$currentUser";"Computer"="$computer"}
                }

            }catch{}
        }
    }

    end{
        $computerList
        return
    }
}

function Get-UserLastLogon{

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
    Get-UserLastLogon -Name "Fred"

    Returns the last time Fred logged into the domain.

    .EXAMPLE
    Get-ADUser -Filter * | Get-UserLastLogon

    Gets the last time all users in AD logged onto the domain.

    .EXAMPLE
    Get-UserLastLogon -OrganizationalUnit "Company Users"

    Returns the last logon time for all users in the organizational unit "Company Users".

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

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
        $lastLogonList += Get-ADuser $SamAccountName | Get-ADObject -Properties lastlogon | Select-Object -Property @{n="SamAccountName";e={$SamAccountName}},@{n="LastLogon";e={([datetime]::fromfiletime($_.lastlogon))}}
    }

    end{
        $lastLogonList | Select-Object -Property SamAccountName,LastLogon | Sort-Object -Property SamAccountName
        return
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
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

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
        $movedComputers
        return
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
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

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
        $movedUsers | Sort-Object -Property SamAccountName
        return
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
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

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
        $computers | Sort-Object -Property Name
        return
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
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

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
        $users | Sort-Object -Property SamAccountName
        return
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
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

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
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT    

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
    }

    process{
        $ComputerMACs = (Get-DhcpServerv4Lease -ComputerName gamls-dc1 -ScopeId "10.10.10.0" | Where-Object -Property hostname -match $Name).clientid

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