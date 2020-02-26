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

        $disabledComputers += $computer
            
    }

    end{
        
        $disabledComputers

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

        $disabledUsers += $user
        
    }

    end{

        $disabledUsers =  $disabledUsers | Get-ADUser

        $disabledUsers | Sort-Object -Property Name

        return

    }

}

###################################
function Get-ComputerError{

    <#

    .SYNOPSIS
    Gets system errors from a computer, computers, or computers in an Active Directory Organzational Unit.

    .DESCRIPTION
    Gets system errors from a computers. By default returns errors from local computer. Can return errors from remote computer(s) or computers in a specific organizational unit. Default number of errors returned is 5, but is adjustable.

    .PARAMETER Name
    Specifies which computer to pull errors from.

    .PARAMETER Newest
    Specifies the number of most recent errors to be returned.

    .PARAMETER OrganizationalUnit
    Specifies the organizational unit in active directory the function will return errors from.

    .INPUTS
    Host names or AD computer objects.

    .OUTPUTS
    PS objects for computer system errors with Computer, TimeWritten, EventID, InstanceId, and Message.

    .NOTES
    Compatible with Windows 7 and newer.

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
    Get-ComputerError -OrganizationalUnit "Company Servers"

    Returns the last 5 errors from all computers in the "Company Servers" organizational unit.

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

        [parameter()]
        [int]$Newest = 5,

        [string]$OrganizationalUnit = ""

    )

    begin{

        function getcomputererror{

            [cmdletBinding()]
            param(

                [string]$computerName,

                [int]$first

            )

            $errors += Get-EventLog -ComputerName $computerName -LogName System -EntryType Error -Newest $first | 
                Select-Object -Property @{n="ComputerName";e={$computerName}},TimeWritten,EventID,InstanceID,Message

            $errors

            return

        }

        $errorLog = @()

        if($OrganizationalUnit -ne ""){

            $domainInfo = (Get-ADDomain).DistinguishedName

            $computers = (Get-ADComputer -Filter * -SearchBase "ou=$OrganizationalUnit,$domainInfo").name

        }

    }

    Process{

        if($OrganizationalUnit -ne ""){

            foreach($computer in $computers){

                $errorlog += getcomputererror -computerName $computer -first $Newest

            }

        }else{

            $errorLog += getcomputererror -computerName $Name -first $Newest

        }

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

    .PARAMETER OrganizationalUnit
    Specifies the computer in an organizational unit to search.

    .INPUTS
    You can pipe host names or AD computer objects.

    .OUTPUTS
    Returns an object with computer name, model, CPU, memory in GB, storage in GB, the current user, IP address, and last boot time.

    .NOTES
    Compatible for Windows 7 and newer.

    Only returns information from computers running Windows 10 or Windows Server 2012 or higher.

    .EXAMPLE
    Get-ComputerInformation

    Returns computer information for the local host.

    .EXAMPLE
    Get-ComputerInformation -Name Server1

    Returns computer information for Server1.

    .EXAMPLE
    Get-ADComputer -filter * | Get-ComputerInformation

    Returns computer information on all AD computers. 

    .EXAMPLE
    Get-ComputerInformation -OrganizationalUnit "Company Servers"

    Returns computer information for all computers in the "Company Servers" organizational unit.

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    #>

    [CmdletBinding()]
    Param(

        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias('ComputerName')]
        [string]$Name = $env:COMPUTERNAME,

        [string]$OrganizationalUnit = ""

    )

    begin{

        function getcomputerinformation{

            [CmdletBinding()]
            Param(
                
                [string]$computerName

            )
            
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

            $computerInfo = New-Object -TypeName PSObject -Property $computerObjectProperties

            $computerInfo.computername = $computerName

            $computerInfo.model = (Get-CimInstance -ComputerName $computerName -ClassName Win32_ComputerSystem -Property Model).model

            $computerInfo.CPU = (Get-CimInstance -ComputerName $computerName -ClassName Win32_Processor -Property Name).name

            $computerInfo.memoryGB = [math]::Round(((Get-CimInstance -ComputerName $computerName -ClassName Win32_ComputerSystem -Property TotalPhysicalMemory).TotalPhysicalMemory / 1GB),1)

            $computerInfo.storageGB = [math]::Round((((Get-CimInstance -ComputerName $computerName -ClassName win32_logicaldisk -Property Size) | 
                Where-Object -Property DeviceID -eq "C:").size / 1GB),1)

            $computerInfo.currentuser = (Get-CimInstance -ComputerName $computerName -ClassName Win32_ComputerSystem -Property UserName).UserName

            $computerInfo.IPAddress = (Test-Connection -ComputerName $computerName -Count 1).IPV4Address

            $computerInfo.BootUpTime = ([System.Management.ManagementDateTimeconverter]::ToDateTime((Get-WmiObject -Class Win32_OperatingSystem -computername $computerName).LastBootUpTime)).ToString()

            $computerInfo

            return

        }

        $computerInfoList = @()

        if($OrganizationalUnit -ne ""){

            $domainInfo = (Get-ADDomain).DistinguishedName

            $computers = (Get-ADComputer -Filter * -SearchBase "ou=$OrganizationalUnit,$domainInfo").name

        }

    }

    process{

        if($OrganizationalUnit -ne ""){

            foreach($computer in $computers){

                $computerInfoList += getcomputerinformation -computerName $computer

            }

        }else{

            $computerInfoList += getcomputerinformation -computerName $Name

        }

    }

    end{

        $computerInfoList | Select-Object -Property ComputerName,Model,CPU,MemoryGB,StorageGB,CurrentUser,IPAddress,BootUpTime

        return

    }

}

function Get-ComputerLastLogon{

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
        [string]$Name = $env:COMPUTERNAME,

        [string]$OrganizationalUnit = ""
    
    )

    begin{

        function getcomputerlastlogon{

            [cmdletBinding()]
            Param(

                [string]$computerName

            )

            $lastLogonTime = (Get-ADComputer $computerName | Get-ADObject -Properties lastlogon).lastlogon

            $lastLogonProperties = @{
                "Last Logon" = ([datetime]::fromfiletime($lastLogonTime));
                "Computer" = ($computerName)
            }
                
            $lastLogon = New-Object -TypeName PSObject -Property $lastLogonProperties

            $lastLogon

            return

        }

        $lastLogonList = @()

        if($OrganizationalUnit -ne ""){

            $domainInfo = (Get-ADDomain).DistinguishedName

            $computers = (Get-ADComputer -Filter * -SearchBase "ou=$OrganizationalUnit,$domainInfo").name

        }

    }

    process{

        if($OrganizationalUnit -ne ""){

            foreach($computer in $computers){

                $lastLogonList += getcomputerlastlogon -computerName $computer

            }

        }else{

            $lastLogonList += getcomputerlastlogon -computerName $Name

        }
        
    }

    end{

        $lastLogonList | Select-Object -Property Computer,"Last Logon" | Sort-Object -Property Computer

        return

    }

}

function Get-ComputerOS{

    <#

    .SYNOPSIS
    Get the operating system name of a computer or computers.

    .DESCRIPTION
    Gets the Windows operating system of the local host. Does not return build number or any other detailed info. Can also get the operating system from a remote computer or group of computers, including those grouped into organizational units.
    
    .PARAMETER Name
    Name of computer you want the operating system of.

    .PARAMETER OrganizationalUnit
    Returns the operating system of computers in an organizational unit.
    
    .INPUTS
    Accepts pipeline input. Host names and AD computer objects.
    
    .OUTPUTS
    PSObject with computer name and operating system.
    
    .NOTES
    Compatible with Windows 7 and newer.

    .EXAMPLE
    Get-ComputerOS

    Returns the local host's operating system.

    .EXAMPLE
    Get-ComputerOS -Name Computer1

    Returns computer name and operating system.

    .EXAMPLE
    Get-CommuterOS -OrganizationalUnit "Company Computers"

    Returns the operating system of all computers in the "Company Computers" operating system.

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

        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [Alias('ComputerName')]
        [string]$Name = $env:COMPUTERNAME,

        [string]$OrganizationalUnit = ""

    )

    begin{

        function getcomputeros{

            [cmdletBinding()]
            param(

                [string]$computerName

            )

            try{

                $computerOS = Get-CimInstance -ComputerName $computerName -ClassName win32_operatingsystem -ErrorAction "Stop" | Select-Object -Property PSComputerName,Caption
                
            }catch{
    
                $computerOS = Get-WmiObject -ComputerName $computerName -Class win32_operatingsystem | Select-Object -Property PSComputerName,Caption
    
            }

            $computerOS

            return

        }

        $computerOSList = @()

        if($OrganizationalUnit -ne ""){

            $domainInfo = (Get-ADDomain).DistinguishedName
    
            $computers = (Get-ADComputer -Filter * -SearchBase "ou=$OrganizationalUnit,$DomainInfo" | Sort-Object -Property Name).Name
    
        }

    }

    process{

        if($OrganizationalUnit -ne ""){

            foreach($computer in $computers){

                $computerOSList += getcomputeros -computerName $computer
                
            }

        }else{

            $computerOSList += getcomputeros -computerName $Name

        }

    }

    end{

        $computerOSList

        return

    }

}

function Get-ComputerSoftware{

    <#

    .SYNOPSIS
    Gets all of the installed software on a computer or computers.

    .DESCRIPTION
    This function gathers all of the installed software on a computer or group of computers. By default gathers from the local host. Can target a remote computer, computers, or organizational unit.

    .PARAMETER Name
    Specifies the computer this function will gather information from. 

    .PARAMETER OrganizationalUnit
    Targets computers in a specific organizational unit.

    .INPUTS
    You can pipe host names or computer objects input to this function.

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

    .EXAMPLE
    Get-ComputerSoftware -OrganizationalUnit "Company Computers"

    Returns the software installed on each computer in the "Company Computers" organizational unit.

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
    
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [Alias('ComputerName')]
        [string]$Name = $env:COMPUTERNAME,

        [string]$OrganizationalUnit = ""
        
    )

    begin{

        function getcomputersoftware{

            [cmdletbinding()]
            param(

                [String]$computerName

            )

            $lmKeys = "Software\Microsoft\Windows\CurrentVersion\Uninstall","SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
            $lmReg = [Microsoft.Win32.RegistryHive]::LocalMachine
            $cuKeys = "Software\Microsoft\Windows\CurrentVersion\Uninstall"
            $cuReg = [Microsoft.Win32.RegistryHive]::CurrentUser

            if((Test-Connection -ComputerName $computerName -Count 1 -ErrorAction Stop)){

                $remoteCURegKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($cuReg,$computerName)
                $remoteLMRegKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($lmReg,$computerName)

                $softwareKeys =@()

                foreach($key in $lmKeys){
                    $regKey = $remoteLMRegKey.OpenSubkey($key)
                    
                    foreach ($subName in $regKey.GetSubkeyNames()){
                    
                        foreach($sub in $regKey.OpenSubkey($subName)){
                    
                            $softwareKeys += (New-Object PSObject -Property @{
                                "ComputerName" = $computerName;
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

                                $softwareKeys += (New-Object PSObject -Property @{
                                    "ComputerName" = $computerName;
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

            $softwareKeys

            return

        }

        $masterKeys = @()

        if($OrganizationalUnit -ne ""){

            $domainInfo = (Get-ADDomain).DistinguishedName

            $computers = (Get-ADComputer -Filter * -SearchBase "ou=$OrganizationalUnit,$domainInfo").name

        }

    }

    process{

        if($OrganizationalUnit -ne ""){

            foreach($computer in $computers){

                $masterKeys += getcomputersoftware -computerName $computer

            }

        }else{

            $masterKeys += getcomputersoftware -computerName $Name

        }

    }

    end{
    
        $woFilter = {$null -ne $_.name -AND $_.SystemComponent -ne "1" -AND $null -eq $_.ParentKeyName}

        $props = 'ComputerName','Name','Version','Installdate','UninstallCommand','RegPath'

        $masterKeys = ($masterKeys | Where-Object $woFilter | Select-Object -Property $props | Sort-Object -Property ComputerName)

        $masterKeys

    }

}

function Get-CredentialExportToXML{

    <#
    
    .SYNOPSIS
    This function gets credentials from the user and exports them to location provided by the user.

    .DESCRIPTION
    This function promps the 
    
    .PARAMETER Path

    .INPUTS
    None.

    .OUTPUTS

    .NOTES

    .EXAMPLE

    .LINK
    By Ben Peterson
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

    #>

    [cmdletbinding()]
    param(

        [Parameter(Mandatory=$true)]
        [string]$Path
    
    )

    $credential = Get-Credential

    Export-Clixml -Path $Path -InputObject $credential

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
        [string] $Path
    
    )

    $folderSize = (Get-ChildItem -Path $Path -File -Recurse | Measure-Object -Sum Length).sum

    $folderInfo += [PSCustomObject]@{

        Directory = $Path;
        SizeGB = [math]::round(($folderSize / 1GB),2)

    }

    $folderInfo

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

function Get-DriveInformation{

    <#

    .SYNOPSIS
    Gets information about the drives on a computer or computers.

    .DESCRIPTION
    Returns information from the drives on a computer, remote computer, or group of computers. The information includes computer name, drive, volume name, size, free space, and if the drive has less than 20% space left.
    
    .PARAMETER Name
    Specifies the computer the function will gather information from.

    .INPUTS
    You can pipe host names or AD computer objects.

    .OUTPUTS
    Returns PS objects to the host the following information about the drives on a computer: computer name, drive, volume name, size, free space, and indicates those under 20% desc space remaining.

    .NOTES
    Compatible with Window 7 and newer.

    .EXAMPLE
    Get-DriveInformation

    Gets drive information for the local host.

    .EXAMPLE
    Get-DriveInformation -computerName computer

    Gets drive information for "computer".

    .EXAMPLE
    Get-DriveInformation -Filter * | Get-DriveSpace

    Gets drive information for all computers in AD.

    .EXAMPLE
    Get-DriveInformation -OrganizationUnit "Company Computers"

    Gets drive information on all computers in the "Company Computers" organizational unit.

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

        [string]$OrganizationalUnit = ""

    )

    begin{

        function getdriveinformation{

            [cmdletBinding()]
            param(

                [string]$computerName

            )

            $driveInformation = Get-CimInstance -ComputerName $computerName -ClassName win32_logicaldisk -Property deviceid,volumename,size,freespace | 
                Where-Object -Property DeviceID -NE $null | 
                Select-Object -Property @{n="Computer";e={$computerName}},`
                @{n="Drive";e={$_.deviceid}},`
                @{n="VolumeName";e={$_.volumename}},`
                @{n="SizeGB";e={$_.size / 1GB -as [int]}},`
                @{n="FreeGB";e={$_.freespace / 1GB -as [int]}},`
                @{n="Under20Percent";e={if(($_.freespace / $_.size) -le 0.2){"True"}else{"False"}}}

            $driveInformation

            return

        }

        if($OrganizationalUnit -ne ""){

            $domainInfo = (Get-ADDomain).DistinguishedName

            $computers = (Get-ADComputer -Filter * -SearchBase "ou=$OrganizationalUnit,$domainInfo").name

        }

        $driveInformationList = @()

    }

    process{

        if($OrganizationalUnit -ne ""){

            foreach($computer in $computers){

                $driveInformationList += getdriveinformation -computerName $computer

            }

        }else{

            $driveInformationList += getdriveinformation -computerName $Name

        }

    }

    end{

        $driveInformationList = $driveInformationList | Where-Object -Property SizeGB -NE 0 | Where-Object -Property VolumeName -NotMatch "Recovery"

        $driveInformationList | Select-Object -Property Computer,Drive,VolumeName,SizeGB,FreeGB,Under20Percent

        return

    }  

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

    .PARAMETER OrganizationalUnit
    Function will return information from computers in the passed organizatonal unit.

    .INPUTS
    You can pipe host names or AD computer objects.

    .OUTPUTS
    PS objects with computer names, time written, and event IDs for failed logon events.

    .NOTES
    Compatible with Windows 10.

    .EXAMPLE
    Get-FailedLogon

    Returns failed logon events from the local host.

    .EXAMPLE
    Get-FailedLogon -Name "Server"

    Returns failed logon events from computer "Server".

    .EXAMPLE
    Get-FailedLogon -OrganizationalUnit "Company Servers"

    Returns failed logon attempts from computers in the "Company Servers" organizational unit.

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

        [int]$DaysBack = 1,

        [string]$OrganizationalUnit = ""

    )

    begin{

        function getfailedlogon{

            [cmdletBinding()]
            param(

                [string]$computerName,

                [int]$days

            )

            $failedLogin = Get-EventLog -ComputerName $computerName -LogName Security -InstanceId 4625 -After ((Get-Date).AddDays($days * -1)) |
                Select-Object -Property @{n="ComputerName";e={$computerName}},TimeWritten,EventID

            $failedLogin

            return

        }

        if($OrganizationalUnit -ne ""){

            $domainInfo = (Get-ADDomain).DistinguishedName

            $computers = (Get-ADComputer -Filter * -SearchBase "ou=$OrganizationalUnit,$domainInfo").name

        }

        $failedLoginList = @()

    }

    process{
        
        if($OrganizationalUnit -ne ""){

            foreach($computer in $computers){

                try{

                    $failedLoginList += getfailedlogon -computerName $computer -days $DaysBack

                }catch{}

            }

        }else{

            try{

                $failedLoginList += getfailedlogon -computerName $Name -days $DaysBack

            }catch{}

        }
        
    }

    end{

        $failedLoginList | Select-Object -Property ComputerName,TimeWritten,EventID

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
    
        if(([datetime]::fromfiletime($computer.lastlogon)) -lt ((Get-Date).AddDays(($DaysInactive * -1)))){
    
            $lastLogonProperties = @{
                "LastLogon" = ([datetime]::fromfiletime($computer.lastlogon));
                "Name" = ($computer.name)
            }
    
            $lastLogonObject = New-Object -TypeName PSObject -Property $lastLogonProperties
        
            $lastLogonList += $lastLogonObject
        
        }
    
    }
    
    $lastLogonList | Select-Object -Property Name,LastLogon | Sort-Object -Property Name
    
    return

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

function Get-MappedDrive{

    <#

    .SYNOPSIS

    .DESCRIPTION

    .PARAMETER OrganizationalUnit

    .INPUTS

    .OUTPUTS

    .NOTES

    .EXAMPLE

    .EXAMPLE

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

        [string]$OrganizationalUnit = ""

    )

    begin{

        function getmappeddrive{

            [cmdletBinding()]
            param(

                [string]$computerName

            )

            try{

                $drives += Get-CimInstance -ComputerName $computerName -ClassName win32_mappedlogicaldisk | Select-Object -Property SystemName,Name,ProviderName

            }catch{

                $drives += Get-WmiObject -ComputerName $computerName -Class Win32_MappedLogicalDisk | Select-Object -Property SystemName,Name,ProviderName

            }

            $drives

            return

        }

        $mappedDrives = @()

        if($OrganizationalUnit -ne ""){

            $domainInfo = (Get-ADDomain).DistinguishedName

            $computers = (Get-ADComputer -Filter * -SearchBase "ou=$OrganizationalUnit,$domainInfo").name

        }

    }

    Process{

        if($OrganizationalUnit -ne ""){

            foreach($computer in $computers){

                try{

                    $mappedDrives += getmappeddrive -computerName $computer

                }catch{}

            }

        }else{

            $mappedDrives += getmappeddrive -computerName $Name

        }

    }

    end{

        $mappedDrives | Sort-Object -Property SystemName

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
    
    $onlineComputers | Select-Object -Property Name,DNSHostName,DistinguishedName | Sort-Object -Property Name
    
    return

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
        [string]$Name = $env:COMPUTERNAME,

        [string]$OrganizationalUnit = ""

    )

    begin{

        function getphysicaldiskinformation{

            [cmdletBinding()]
            param(

                [string]$computerName

            )

            $disks = Get-PhysicalDisk -CimSession $computerName | 
                Select-Object -Property @{n="ComputerName";e={$computerName}},`
                FriendlyName,`
                MediaType,`
                OperationalStatus,`
                HealthStatus,`
                @{n="SizeGB";e={[math]::Round(($_.Size / 1GB),1)}}

            $disks

            return

        }

        $physicalDiskList = @()

        if($OrganizationalUnit -ne ""){

            $domainInfo = (Get-ADDomain).DistinguishedName
    
            $computers = (Get-ADComputer -Filter * -SearchBase "ou=$OrganizationalUnit,$domainInfo").name
    
        }

    }

    process{

        if($OrganizationalUnit -ne ""){

            foreach($computer in $computers){

                    $physicalDiskList += getphysicaldiskinformation -computerName $computer

            }

        }else{

            $physicalDiskList += getphysicaldiskinformation -computerName $Name
            
        }

    }

    end{

        $physicalDiskList | Select-Object -Property ComputerName,FriendlyName,MediaType,OperationalStatus,HealthStatus,SizeGB

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

}

function Get-UserLastLogon{

    <#

    .SYNOPSIS
    Gets the last time a user, or group of users, logged onto the domain.

    .DESCRIPTION
    Returns the last time a user or group of users logged onto the domain. Scope can be limited to an organizational unit.

    .PARAMETER SamAccountName
    User name.

    .PARAMETER OrganizationalUnit
    Returns information on users in a specific organizational unit.

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
        [string]$SamAccountName = $env:UserName,

        [string]$OrganizationalUnit = ""

    )

    begin{

        function getuserlastlogon{

            [cmdletBinding()]
            param(

                [string]$Name

            )

                $userlastLogon = (Get-ADuser $Name | Get-ADObject -Properties lastlogon | Select-Object -Property @{n="LastLogon";e={([datetime]::fromfiletime($_.lastlogon))}}).LastLogon

                $userLastLogon

                return

        }

        $lastLogonList = @()

        if($OrganizationalUnit -ne ""){

            $domainInfo = (Get-ADDomain).DistinguishedName

            $users = (Get-ADuser -Filter * -SearchBase "ou=$OrganizationalUnit,$domainInfo").SamAccountName
    
        }

    }

    process{

        if($OrganizationalUnit -ne ""){

            foreach($user in $users){

                $lastLogonList += [PSCustomObject]@{`
                    "LastLogon" = (getuserlastlogon -Name $user);`
                    "SamAccountName" = $user
                }
                
            }

        }else{

            $lastLogonList += [PSCustomObject]@{`
                "LastLogon" = (getuserlastlogon -Name $SamAccountName);`
                "SamAccountName" = $SamAccountName
            }

        }
        
    }

    end{

        $lastLogonList | Select-Object -Property SamAccountName,LastLogon | Sort-Object -Property SamAccountName

        return

    }

}

function Get-UserLogon{

    <#

    .SYNOPSIS
    Finds all computers where a specific user, or users, is logged in.

    .DESCRIPTION
    Searches domain computers and returns a list of computers where a specific user is logged in. 
    
    .PARAMETER SamAccountName
    Takes the SamAccountName of an AD user.

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
        [string]$SamAccountName 
    
    )

    begin{

        $computerList = @()

        $computers = (Get-ADComputer -Filter *).Name

    }

    process{

        foreach($computer in $computers){

            try{

                $currentUser = ((Get-CimInstance -ComputerName $computer -ClassName "Win32_ComputerSystem" -Property "UserName").UserName).split('\')[-1]

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

function Import-OutlookContactsFromCSV{
#https://blogs.msdn.microsoft.com/jmanning/2007/01/25/using-powershell-for-outlook-automation/
    
    [cmdletBinding()]	
    
    param(
    
        [Parameter(Mandatory = $True)]
        [string]$ComputerName,
    
        [Parameter(Mandatory = $True)]
        [string]$CSVPath
            
    )
    
    $ImportContacts = Import-Csv -Path $CSVPath
    
    Invoke-Command -ComputerName $ComputerName -ScriptBlock{
    
        $Outlook = New-Object -com Outlook.Application
    
        #Adding a contact
    
        $Contacts = $Outlook.Session.GetDefaultFolder(10) # == olFolderContacts
    
        $ExistingContacts = $Contacts.items | Select-Object -Property FullName,FirstName,LastName,Email1Address
    
        foreach($NewContact in $using:ImportContacts){
    
            $AddContact = $true
    
            $InputFirstName = $NewContact."First Name"
            $InputLastName = $NewContact."Last Name"
            $InputEmail = $NewContact."E-mail Address"
            $InputEmailDisplayName = $NewContact."E-mail Display Name"
    
            foreach($Contact in $ExistingContacts){
    
                if(($InputFirstName -eq $Contact.FirstName) -and ($InputLastName -eq $Contact.LastName)){
    
                    $AddContact = $false
    
                }
    
            }
    
            if($AddContact -eq $true){
    
                $NewContact = $Contacts.Items.Add()
                $NewContact.FirstName = $InputFirstName
                $NewContact.LastName = $InputLastName
                $NewContact.Email1Address =$InputEmail
                $NewContact.Email1DisplayName = $InputEmailDisplayName
                $NewContact.Save()
    
            }
    
        }
    
    }
    
}

function Move-Computer{

    <#

    .SYNOPSIS
    
    .DESCRIPTION
    
    .PARAMETER ComputerName

    .PARAMETER OrganizationalUnit

    .INPUTS

    .OUTPUTS

    .NOTES

    .EXAMPLE

    .LINK
    By Ben Peterson
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

    #>

    [cmdletbinding()]
    param(

        [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [string]$DestinationOU
    
    )
    
    begin{

        $domainInfo = (Get-ADDomain).DistinguishedName

        $computers = @()

    }

    process{

        $computers += Get-ADComputer -Identity $Name

    }

    end{

        $computers | Move-ADObject -TargetPath "ou=$DestinationOU,$domainInfo"

        $computers

        return

    }

}

function Move-DisabledComputers{

    <#

    .SYNOPSIS
    Disables Active Directory computers that have not recently connected to the domain.

    .DESCRIPTION
    Disables Active Directory computers that have not connected to the domain in a set amount of months. The number of 
    months can be set by passing it to the MonthsOld parameter. The function by default searches the whole Active Directory,
    but can be pointed at a specific organizational unit.

    .PARAMETER MonthsOld
    Sets the number of months that a computer has to have been offline for it to be disabled.

    .PARAMETER OrganizationalUnit
    Sets the organizational unit the function will search.

    .INPUTS
    None.

    .OUTPUTS
    Returns an AD PSObject for each computer that was disabled.

    .NOTES

    .EXAMPLE
    Disable-ADOldComputer

    .LINK
    By Ben Peterson
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

    #>

    [cmdletbinding()]
    param(

        [Parameter()]
        [string]$OriginOU,
        
        [Parameter(Mandatory=$true)]
        [string]$DestinationOU
    
    )
    
    $domainInfo = (Get-ADDomain).DistinguishedName

    if($OriginOU -eq ""){

        $computers = Get-ADComputer -Filter * | Where-Object -Property Enabled -EQ $False

    }else{

        $computers = Get-ADComputer -Filter * -SearchBase "ou=$OriginOU,$domainInfo" | Where-Object -Property Enabled -EQ $False
    
    }

    $computers | Move-ADObject -TargetPath "ou=$DestinationOU,$domainInfo"

    $computers

    return 

}

function Move-DisabledUsers{

    <#

    .SYNOPSIS
    Disables Active Directory computers that have not recently connected to the domain.

    .DESCRIPTION
    Disables Active Directory computers that have not connected to the domain in a set amount of months. The number of 
    months can be set by passing it to the MonthsOld parameter. The function by default searches the whole Active Directory,
    but can be pointed at a specific organizational unit.

    .PARAMETER MonthsOld
    Sets the number of months that a computer has to have been offline for it to be disabled.

    .PARAMETER OrganizationalUnit
    Sets the organizational unit the function will search.

    .INPUTS
    None.

    .OUTPUTS
    Returns an AD PSObject for each computer that was disabled.

    .NOTES

    .EXAMPLE
    Disable-ADOldComputer

    .LINK
    By Ben Peterson
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

    #>

    [cmdletbinding()]
    param(

        [Parameter()]
        [string]$OriginOU,
        
        [Parameter(Mandatory=$true)]
        [string]$DestinationOU

    )

    $domainInfo = (Get-ADDomain).DistinguishedName

    if($OriginOU -eq ""){

        $users = Get-ADUser -Filter * | Where-Object -Property Enabled -EQ $False

    }else{

        $users = Get-ADUser -Filter * -SearchBase "ou=$OriginOU,$domainInfo" | Where-Object -Property Enabled -EQ $False

    }

    $users | Move-ADObject -TargetPath "ou=$DestinationOU,$domainInfo"

    $users | Sort-Object -Property Name

    return 

}

function Move-User{

    <#

    .SYNOPSIS

    .DESCRIPTION

    .PARAMETER Name

    .PARAMETER DestinationOU

    .INPUTS

    .OUTPUTS

    .NOTES

    .EXAMPLE

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

        $users = @()

    }

    process{

        $users += Get-ADUser -Identity $Name

    }

    end{

        $users | Move-ADObject -TargetPath "ou=$DestinationOU,$domainInfo"

        $users

        return

    }

}

function Remove-Computer{

    <#

    .SYNOPSIS
    Removes disabled computers from AD.

    .DESCRIPTION
    Removes disabled computers from AD. Also returns a list of computers that have been removed.

    .PARAMETER OrganizationalUnit
    Limits the script to a specific organizational unit.

    .INPUTS
    None.

    .OUTPUTS
    Returns an AD computer object for each computer removed from AD.

    .NOTES

    .EXAMPLE
    Remove-ADDisabledComputer

    Removes all disabled computers from AD.

    .LINK
    By Ben Peterson
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

    #>

    [cmdletbinding()]
    param(

        [string]$OrganizationalUnit
    
    )

    $domainInfo = (Get-ADDomain).DistinguishedName

    if($OrganizationalUnit -eq ""){

        $computers = Get-ADComputer -Filter * | Where-Object -Property Enabled -EQ $False

    }else{

        $computers = Get-ADComputer -Filter * -SearchBase "ou=$OrganizationalUnit,$domainInfo" | 
            Where-Object -Property Enabled -EQ $False
    }

    $computers | Remove-ADComputer

    $computers

    return

}

function Remove-DisabledComputers{

    <#

    .SYNOPSIS
    Removes disabled computers from AD.

    .DESCRIPTION
    Removes disabled computers from AD. Also returns a list of computers that have been removed.

    .PARAMETER OrganizationalUnit
    Limits the script to a specific organizational unit.

    .INPUTS
    None.

    .OUTPUTS
    Returns an AD computer object for each computer removed from AD.

    .NOTES

    .EXAMPLE
    Remove-ADDisabledComputer

    Removes all disabled computers from AD.

    .LINK
    By Ben Peterson
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

    #>

    [cmdletbinding()]
    param(

        [string]$OrganizationalUnit
    
    )

    $domainInfo = (Get-ADDomain).DistinguishedName

    if($OrganizationalUnit -eq ""){

        $computers = Get-ADComputer -Filter * | Where-Object -Property Enabled -EQ $False

    }else{

        $computers = Get-ADComputer -Filter * -SearchBase "ou=$OrganizationalUnit,$domainInfo" | 
            Where-Object -Property Enabled -EQ $False
    }

    $computers | Remove-ADComputer

    $computers

    return

}

function Remove-DisabledUsers{

    <#

    .SYNOPSIS
    Removes disabled users from AD.

    .DESCRIPTION
    Removes all disabled users from AD and returns a list of users that were removed.

    .PARAMETER None

    .INPUTS
    None. You cannot pipe paramters to this function.

    .OUTPUTS
    Returns an AD user object for each user removed from AD.

    .NOTES

    .EXAMPLE
    Remove-ADDisabledUser

    Removes all disabled users in AD. Returns list of removed users.

    .LINK
    By Ben Peterson
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

    #>

    [cmdletbinding()]
    param(

        [string]$OrganizationalUnit
    
    )

    $domainInfo = (Get-ADDomain).DistinguishedName

    Write-Verbose "Domain info [$domainInfo]."
    
    if($OrganizationalUnit -eq ""){

        Write-Verbose "Gathering all disabled users in AD."

        $users = Get-ADUser -Filter * | Where-Object -Property Enabled -EQ $False

    }else{

        Write-Verbose "Gathering all disabled users in the $OrganizationalUnit organizational unit."

        $users = Get-ADUser -Filter * -SearchBase "ou=$OrganizationalUnit,$domainInfo" | 
            Where-Object -Property Enabled -EQ $False
    }

    $users | Remove-ADUser

    $users

    return

}

function Remove-User{

    <#

    .SYNOPSIS
    Removes disabled users from AD.

    .DESCRIPTION
    Removes all disabled users from AD and returns a list of users that were removed.

    .PARAMETER None

    .INPUTS
    None. You cannot pipe paramters to this function.

    .OUTPUTS
    Returns an AD user object for each user removed from AD.

    .NOTES

    .EXAMPLE
    Remove-ADDisabledUser

    Removes all disabled users in AD. Returns list of removed users.

    .LINK
    By Ben Peterson
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

    #>

    [cmdletbinding()]
    param(

        [string]$OrganizationalUnit
    
    )

    $domainInfo = (Get-ADDomain).DistinguishedName

    Write-Verbose "Domain info [$domainInfo]."
    
    if($OrganizationalUnit -eq ""){

        Write-Verbose "Gathering all disabled users in AD."

        $users = Get-ADUser -Filter * | Where-Object -Property Enabled -EQ $False

    }else{

        Write-Verbose "Gathering all disabled users in the $OrganizationalUnit organizational unit."

        $users = Get-ADUser -Filter * -SearchBase "ou=$OrganizationalUnit,$domainInfo" | 
            Where-Object -Property Enabled -EQ $False
    }

    $users | Remove-ADUser

    $users

    return

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
    $SelfIPAddress = (Test-Connection -ComputerName $env:COMPUTERNAME -Count 1).IPv4Address

    $SelfIPInterfaceIndex = (Get-NetIPAddress | Where-Object -Property IPAddress -eq $SelfIPAddress).InterfaceIndex

    #Subnetmask / Prefixlength
    $SelfPrefixlength = (Get-NetIPAddress | Where-Object -Property IPAddress -eq $SelfIPAddress).PrefixLength

    #Default Gateway
    $SelfDefaultGateway = (Get-NetRoute | Where-Object -Property DestinationPrefix -eq '0.0.0.0/0').NextHop

    #DNS
    $SelfDNS = (Get-DnsClientServerAddress -InterfaceIndex $SelfIPInterfaceIndex -AddressFamily IPv4).ServerAddresses

    $TargetIPAddress = (Test-Connection -ComputerName $ComputerName -Count 1 ).IPv4Address

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