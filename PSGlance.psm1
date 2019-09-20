function Find-UserLogin{

    <#

    .SYNOPSIS
    Finds all computers where a specific user is logged in.

    .DESCRIPTION
    Searches domain computers and returns a list of computers where a specific user is logged in. 
    
    .PARAMETER SamAccountName
    Takes the SamAccountName of an AD user.

    .INPUTS
    String with SamAccountName or AD user object. Can pipe input to the function.

    .OUTPUTS
    List of objects with the user name and the names of the computers they are logged into.

    .NOTES

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
        #[alias('SamAccountName')]
        [string]$SamAccountName 
    
    )

    begin{

        $ErrorActionPreference = "SilentlyContinue"

        $computerList = @()

        $computers = (Get-ADComputer -Filter *).Name

    }

    process{

        Write-Verbose ("Checking user [ " + $SamAccountName + " ] on AD computers.")
        
        foreach($computer in $computers){

            try{

                $currentUser = ((Get-CimInstance -ComputerName $computer -ClassName "Win32_ComputerSystem" -Property "UserName").UserName).split('\')[-1]

                if($currentUser -eq $SamAccountName){
                
                    $computerList += New-Object -TypeName PSObject -Property @{"User"="$currentUser";"Computer"="$computer"}
            
                }

            }catch{

                Write-Verbose "Could not connect to [ $computer ]."

            }

        }

    }

    end{

        $computerList

        return

    }

}

function Get-ADComputerLastLogon{

    <#

    .SYNOPSIS
    Gets the last time all Active Directory computers were connected to an AD network.

    .DESCRIPTION
    Returns the name of and last time that each Active Directory computer has connected to the domain.
    
    .PARAMETER OrganizationalUnit
    Limits the function to a specific OU.

    .INPUTS
    None.

    .OUTPUTS
    PS objects with names and the last time times.

    .NOTES
    None.

    .EXAMPLE
    Get-ADComputerLastLogon

    Returns the last time each computer in the domain was logged connected to the domain.

    .EXAMPLE
    Get-ADComputerLastLogon -OrganizationalUnit Servers

    Returns the name and last log on time for each computer in the "Servers" organizational unit in AD.

    .LINK
    By Ben Peterson
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

    #>

    [CmdletBinding()]
    Param(
    
        [string]$OrganizationalUnit
    
    )
    
    $domainInfo = (Get-ADDomain).DistinguishedName
    
    if($OrganizationalUnit -eq ""){

        Write-Verbose "Gathering all computers."

        $Computers = Get-ADComputer -Filter * | Get-ADObject -Properties lastlogon

    }else{

        Write-Verbose "Gathering computers in the $OrganizationalUnit OU."

        $Computers = Get-ADComputer -Filter * -SearchBase "ou=$OrganizationalUnit,$domainInfo" | Get-ADObject -Properties lastlogon

    }

    $lastLogonList = @()

    foreach($computer in $Computers){

        $lastLogonProperties = @{
        
            "Last Logon" = ([datetime]::fromfiletime($computer.lastlogon));
        
            "Computer" = ($computer.name)
        
        }

        $lastLogonList += New-Object -TypeName PSObject -Property $lastLogonProperties
        
    }

    $lastLogonList

    return

}

function Get-ADDisabledComputer{

    <#

    .SYNOPSIS
    Gets a list of all computers in AD that are currently disabled.

    .DESCRIPTION
    Returns a list of computers from AD that are disabled with information including name, enabled status, DNSHostName, and 
    DistinguishedName.

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
    Get-ADDisabledComputer -OrganizationalUnit Servers

    Returns a list of all AD computers in the organizational unit "Servers" that are currently disabled.


    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    #>

    [CmdletBinding()]
    Param(
    
        [string]$OrganizationalUnit
    
    )
    
    $domainInfo = (Get-ADDomain).DistinguishedName
    
    if($OrganizationalUnit -eq ""){

        Write-Verbose "Gathering all disabled computers."

        $disabledComputers = Get-ADComputer -Filter * | Where-Object -Property Enabled -Match False

    }else{

        Write-Verbose "Gathering disabled computers in the $OrganizationalUnit OU."

        $disabledComputers = Get-ADComputer -Filter * -SearchBase "ou=$OrganizationalUnit,$domainInfo" | 
            Where-Object -Property Enabled -Match False

    }

    $disabledComputers | Select-Object -Property Name,Enabled,DNSHostName,DistinguishedName | Sort-Object -Property Name

    return
    
}

function Get-ADDisabledUser{
    
    <#

    .SYNOPSIS
    Gets a list of all users in AD that are currently disabled. 

    .DESCRIPTION
    Returns a list of users from AD that are disabled with information including name, enabled, and user principal name. 
    Function can be limited in scope to a specific organizational unit.

    .PARAMETER OrganizationalUnit
    Focuses the function on a specific AD organizational unit.

    .INPUTS
    None.

    .OUTPUTS
    PS objects with information including name, DNSHostName, and DistinguishedName.

    .NOTES
    Firewalls must be configured to allow ping requests.

    .EXAMPLE
    Get-ADDisabledUser

    Returns a list of all AD users that are currently disabled.

    .EXAMPLE
    Get-ADDisabledUser -OrganizationalUnit "Employees"

    Returns a list of all AD users that are currently disabled in the "Employees" organizational unit.

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    #>

    [CmdletBinding()]
    Param(
    
        [string]$OrganizationalUnit
    
    )

    $domainInfo = (Get-ADDomain).DistinguishedName 
    
    if($OrganizationalUnit -eq ""){

        Write-Verbose "Gathering all disabled users."

        $disabledUsers = Get-ADUser -Filter * | Where-Object -Property Enabled -Match False

    }else{

        Write-Verbose "Gathering disabled users in the $OrganizationalUnit OU."

        $disabledUsers = Get-ADUser -Filter * -SearchBase "ou=$OrganizationalUnit,$domainInfo" | 
            Where-Object -Property Enabled -Match False

    }

    $disabledUsers | Select-Object -Property Name,Enabled,UserPrincipalName | Sort-Object -Property Name
    
    return

}

function Get-ADOfflineComputer{

    <#

    .SYNOPSIS
    Gets a list of all computers in AD that are currently offline. 

    .DESCRIPTION
    Returns a list of computers from AD that are offline with information including name, DNS host name, and distinguished 
    name. By default searches the whole AD. Can be limited to a specific organizational unit.

    .PARAMETER OrganizationalUnit
    Focuses the function on a specific AD organizational unit.

    .INPUTS
    None.

    .OUTPUTS
    PS objects with information including name, DNS host name, and distinguished name.

    .NOTES
    Firewalls must be configured to allow ping requests.

    .EXAMPLE
    Get-ADOfflineComputer

    Returns a list of all AD computers that are currently offline.

    .EXAMPLE
    Get-ADOfflineComputer -OrganizationalUnit "WorkStations"

    Returns a list of all AD computers that are currently offline in the "Workstations" organizational unit.

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    #>

    [CmdletBinding()]
    Param(
    
        [string]$OrganizationalUnit
    
    )

    $domainInfo = (Get-ADDomain).DistinguishedName 
    
    if($OrganizationalUnit -eq ""){

        Write-Verbose "Gathering all computer names."

        $computers = Get-ADComputer -Filter *

    }else{

        Write-Verbose "Gathering computer names from $OrganizationalUnit OU."

        $computers = Get-ADComputer -Filter * -SearchBase "ou=$OrganizationalUnit,$domainInfo"

    }

    $offlineComputers = @()
    
    Write-Verbose "Testing for offline computers."

    foreach($computer in $computers){
    
        if(!(Test-Connection -ComputerName ($computer.name) -Count 1 -Quiet)){
    
            $offlineComputers += $computer
    
        }
    
    }
    
    $offlineComputers | Select-Object -Property Name,DNSHostName,DistinguishedName | Sort-Object -Property Name
    
    return
    
}

function Get-ADInactiveComputer{

    <#

    .SYNOPSIS
    Gets a list of all the computers in AD that have not been online for a specific number of months.

    .DESCRIPTION
    Returns a list of all the computers in AD that have not been online a number of months. The default amount of months is
    3. Can be set by the user by passing a value to MonthsOld. Can be limited to a specific organizational unit.

    .PARAMETER MonthsOld
    Determines how long the computer account has to be inactive for it to be returned.

    .PARAMETER OrganizationalUnit
    Focuses the function on a specific AD organizational unit.

    .INPUTS
    None.

    .OUTPUTS
    PS objects with information including computer names and the date they were last connected to the domain.

    .NOTES
    Function is intended to help find retired computers that have not been removed from AD.

    .EXAMPLE
    Get-ADInactiveComputer

    Lists all computers in the domain that have not been online for more than 6 months.

    .EXAMPLE
    Get-ADInactiveComputer -MonthsOld 2

    Lists all computers in the domain that have not checked in for more than 2 months.

    .LINK
    By Ben Peterson
    linkedin.com/in/benpetersonIT
    https://github.com/BenPetersonIT

    #>

    [CmdletBinding()]
    Param(
    
        [int]$MonthsOld = 3,

        [string]$OrganizationalUnit
    
    )

    $domainInfo = (Get-ADDomain).DistinguishedName
    
    if($OrganizationalUnit -eq ""){

        Write-Verbose "Gathering all computers."

        $computers = Get-ADComputer -Filter * | Get-ADObject -Properties lastlogon | Select-Object -Property name,lastlogon

    }else{

        Write-Verbose "Gathering computers in the $OrganizationalUnit OU."

        $computers = Get-ADComputer -Filter * -SearchBase "ou=$OrganizationalUnit,$domainInfo" | 
            Get-ADObject -Properties lastlogon | Select-Object -Property name,lastlogon

    }

    $lastLogonList = @()

    Write-Verbose "Filtering for computers that have not connected to the domain in $MonthsOld months."

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

function Get-ADInactiveUser{

    <#

    .SYNOPSIS
    Gets a list of all the users in AD that have not logged on for an exstended period of time.

    .DESCRIPTION
    Returns a list of all the users in AD that have not been online for a number of months. The default amount of months is 
    3. Can be set by the user by passing a value to MonthsOld. Function can also be focused on a specific OU.

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
    Get-ADInactiveUser

    Lists all users in the domain that have not checked in for more than 3 months.

    .EXAMPLE
    Get-ADInactiveUser -MonthsOld 2

    Lists all users in the domain that have not checked in for more than 2 months.

    .EXAMPLE
    Get-ADInactiveUser -MonthsOld 3 -OrganizationalUnit "Farmers"

    Lists all users in the domain that have not checked in for more than 3 months in the "Farmers" organizational unit.

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    #>

    [CmdletBinding()]
    Param(

        [int]$MonthsOld = 3,
    
        [string]$OrganizationalUnit
    
    )

    $domainInfo = (Get-ADDomain).DistinguishedName 
    
    if($OrganizationalUnit -eq ""){

        Write-Verbose "Gathering all computers."

        $users = Get-ADUser -Filter * | Get-ADObject -Properties lastlogon | Select-Object -Property lastlogon,name

    }else{

        Write-Verbose "Gathering computers in the $OrganizationalUnit OU."

        $users = Get-ADUser -Filter * -SearchBase "ou=$OrganizationalUnit,$domainInfo" | 
            Get-ADObject -Properties lastlogon | Select-Object -Property lastlogon,name

    }
    
    $lastLogonList = @()

    Write-Verbose "Filtering for users that have not logged on for $MonthsOld months."
    
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
    Returns an array of PS objects containing the name, DNS host name, and distinguished name of AD computers that are 
    currently online. 

    .PARAMETER OrganizationalUnit
    Focuses the function on a specific AD organizational unit.

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

    [CmdletBinding()]
    Param(

        [string]$OrganizationalUnit
    
    )

    $domainInfo = (Get-ADDomain).DistinguishedName 
    
    if($OrganizationalUnit -eq ""){

        Write-Verbose "Gathering all computers."

        $computers = Get-ADComputer -Filter *

    }else{

        Write-Verbose "Gathering computers in the $OrganizationalUnit OU."

        $computers = Get-ADComputer -Filter * -SearchBase "ou=$OrganizationalUnit,$domainInfo"

    }

    $onlineComputers = @()
    
    Write-Verbose "Testing for online computers."

    foreach($computer in $computers){
    
        if(Test-Connection -ComputerName ($computer.name) -Count 1 -Quiet){
    
            $onlineComputers += $computer
    
        }
    
    }
    
    $onlineComputers | Select-Object -Property Name,DNSHostName,DistinguishedName | Sort-Object -Property Name
    
    return

}

function Get-ADUserLastLogon{

    <#

    .SYNOPSIS
    Gets the last time all AD users have logged onto the domain.

    .DESCRIPTION
    Returns the last time all users or group of users logged onto the domain.

    .PARAMETER OrganizationalUnit
    Limits the function to a specific OU.

    .INPUTS
    None.

    .OUTPUTS
    PS objects with user name and last logon date.

    .NOTES
    None.

    .EXAMPLE
    Get-UserLastLogon

    Returns the last time that all users logged into the domain.

    .EXAMPLE
    Get-UserLastLogon -OrganizationalUnit "X Department"

    Gets the last time all users in the "X Department" OU logged onto the domain.

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    #>

    [CmdletBinding()]
    Param(
    
        [string]$OrganizationalUnit
    
    )
    
    $domainInfo = (Get-ADDomain).DistinguishedName
    
    if($OrganizationalUnit -eq ""){

        Write-Verbose "Gathering all users."

        $Users = Get-ADComputer -Filter * | Get-ADObject -Properties lastlogon | 
        Select-Object -Property lastlogon,name

    }else{

        Write-Verbose "Gathering disabled computers in the $OrganizationalUnit OU."

        $Users = Get-ADComputer -Filter * -SearchBase "ou=$OrganizationalUnit,$domainInfo" | Get-ADObject -Properties lastlogon | 
        Select-Object -Property lastlogon,name

    }

    $lastLogonList = @()

    foreach($User in $Users){

        $lastLogonProperties = @{
            "LastLogon" = ([datetime]::fromfiletime($user.lastlogon));
            "User" = ($user.name)
        }
    
        $lastLogonList += New-Object -TypeName PSObject -Property $lastLogonProperties
        
    }

    $lastLogonList | Select-Object -Property User,LastLogon

    return

}

function Get-ComputerError{

    <#

    .SYNOPSIS
    Gets system errors from a computer.

    .DESCRIPTION
    Returns system errors from a computer. By default it gathers them from the local computer. Computer and number of errors
    returned can be set by user.

    .PARAMETER Name
    Specifies which computer to pull errors from.

    .PARAMETER Newest
    Specifies the numbers of errors returned.

    .INPUTS
    Host names or AD computer objects.

    .OUTPUTS
    PS objects for computer system errors with Computer, TimeWritten, EventID, InstanceId, 
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

    .EXAMPLE
    "computer1","computer2" | Get-ComputerError

    This cmdlet returns system errors from "computer1" and "computer2".

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
        [int]$Newest = 5

    )

    begin{

        $ErrorActionPreference = "Stop"

        $errors = @()

    }

    Process{

        try{
        
            $errors += Get-EventLog -ComputerName $Name -LogName System -EntryType Error -Newest $Newest |
                Select-Object -Property @{n="ComputerName";e={$Name}},TimeWritten,EventID,InstanceID,Message

        }catch{

            Write-Verbose "Unable to communicate with $Name."

        }

    }

    end{

        $errors | Sort-Object -Property ComputerName | 
            Select-Object -Property ComputerName,TimeWritten,EventID,InstanceID,Message

        return

    }

}

function Get-ComputerInformation{

    <#

    .SYNOPSIS
    Gets infomation about a computer.

    .DESCRIPTION
    This function gathers infomation about a computer or computers. By default it gathers info from the local host. The information 
    includes computer name, model, CPU, memory in GB, storage in GB, free space in GB, if less than 20 percent of storage is 
    left, the current user, and IP address.

    .PARAMETER Name
    Specifies which computer's information is gathered.

    .INPUTS
    You can pipe host names or AD computer objects.

    .OUTPUTS
    Returns an object with computer name, model, CPU, memory in GB, storage in GB, free space in GB, if less than 20 percent
    of storage is left, and the current user.

    .NOTES
    Only returns information from computers running Windows 10 or Windows Server 2012 or higher.

    .EXAMPLE
    Get-ComputerInformation -ComputerName Server1

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
            "IPAddress" = "";
            "BootUpTime" = ""
        }

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

            $computerInfo.BootUpTime = ([System.Management.ManagementDateTimeconverter]::ToDateTime((Get-WmiObject -Class Win32_OperatingSystem -computername $Name).LastBootUpTime)).ToString()

            $computerInfoList += $computerInfo

        }catch{

            Write-Verbose "Unable to communicate with $Name."

        }

    }

    end{

        $computerInfoList | Select-Object -Property ComputerName,Model,CPU,MemoryGB,StorageGB,FreeSpaceGB,Under20Percent,CurrentUser,IPAddress,BootUpTime

        return

    }

}

function Get-ComputerSoftware{

    <#

    .SYNOPSIS
    Gets all of the installed software on a computer.

    .DESCRIPTION
    This function gathers all of the installed software on a computer or group of computers.  

    .PARAMETER Name
    Specifies the computer this function will gather information from. 

    .INPUTS
    You can pipe host names or computer objects input to this function.

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
    Get-ADComputer -Filter * | Get-ComputerSoftware

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
    
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
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

        }catch{

            Write-Verbose "Unable to communicate with $Name."

        }

    }

    end{
    
        $woFilter = {$null -ne $_.name -AND $_.SystemComponent -ne "1" -AND $null -eq $_.ParentKeyName}

        $props = 'ComputerName','Name','Version','Installdate','UninstallCommand','RegPath'

        $masterKeys = ($masterKeys | Where-Object $woFilter | Select-Object -Property $props | Sort-Object -Property ComputerName)

        $masterKeys

    }

}

function Get-DiskHealth{

    <#

    .SYNOPSIS
    Gets the health status of the physical disks off a computer.

    .DESCRIPTION
    Returns the health status of the physical disks of the local computer, remote computer, or group of computers.

    .PARAMETER Name
    Specifies the computer the fuction will gather information from.

    .INPUTS
    You can pipe host names or AD computer objects.

    .OUTPUTS
    Returns objects with disk info including computer name, friendly name, media type, operational status, health 
    status, and size in GB.

    .NOTES
    Only returns information from computers running Windows 10 or Windows Server 2012 or higher.

    .EXAMPLE
    Get-DiskHealth

    Returns disk health information for the local computer.

    .EXAMPLE
    Get-DiskHealth -Name Computer1

    Returns disk health information for the computer named Computer1.

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

        }catch{

            Write-Verbose "Unable to communicate with $Name."

        }

    }

    end{

        $physicalDisk | Select-Object -Property ComputerName,FriendlyName,MediaType,OperationalStatus,HealthStatus,SizeGB

        Return

    }

}

function Get-DriveSpace{

    <#

    .SYNOPSIS
    Gets information for the drives on a computer including computer name, drive, volume, name, 
    size, free space, and indicates those under 20% desc space remaining.

    .DESCRIPTION
    Gathers information from the drives on a computer including computer name, drive, volume, name, 
    size, free space, and indicates those under 20% desc space remaining.

    .PARAMETER Name
    Specifies the computer the function will gather information from.

    .INPUTS
    You can pipe host names or AD computer objects.

    .OUTPUTS
    Returns PS objects to the host the following information about the drives on a computer: computer name, drive, 
    volume name, size, free space, and indicates those under 20% desc space remaining.  

    .NOTES

    .EXAMPLE
    Get-DriveSpace

    Gets drive information for the local host.

    .EXAMPLE
    Get-DriveSpace -computerName computer

    Gets drive information for "computer".

    .EXAMPLE
    Get-ADComputer -Filter * | Get-DriveSpace

    Gets drive information for all computers in AD.

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

        }catch{

            Write-Verbose "Unable to communicate with $Name."

        }

    }

    end{

        $driveSpaceLog = $driveSpaceLog | Where-Object -Property SizeGB -NE 0

        $driveSpaceLog | Select-Object -Property Computer,Drive,VolumeName,SizeGB,FreeGB,Under20Percent

        return

    }  

}

function Get-FailedLogon{

    <#

    .SYNOPSIS
    Gets a list of failed logon events from a computer.

    .DESCRIPTION
    This function can return failed logon events from the local computer, remote computer, or group of computers.

    .PARAMETER Name
    Specifies the computer the function gathers information from.

    .PARAMETER DaysBack
    Determines how many days in the past the function will search for failed log ons.

    .INPUTS
    You can pipe host names or AD computer objects.

    .OUTPUTS
    PS objects with computer names, time written, and event IDs for failed logon events.

    .NOTES

    .EXAMPLE
    Get-FailedLogon

    Returns failed logon events from the local host.

    .EXAMPLE
    Get-FailedLogon -Name "Server"

    Returns failed logon events from computer "Server".

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

        $ErrorActionPreference = "Stop"

        $failedLoginLog = @()

    }

    process{
        
        try{

            $failedLogin = Get-EventLog -ComputerName $Name -LogName Security -InstanceId 4625 -After ((Get-Date).AddDays($DaysBack * -1)) |
                Select-Object -Property @{n="ComputerName";e={$Name}},TimeWritten,EventID

            $failedLoginLog += $failedLogin

        }catch{

            Write-Verbose "Unable to communicate with $Name."

        }
        
    }

    end{

        $failedLoginLog | Select-Object -Property ComputerName,TimeWritten,EventID

        return

    }

}

function Get-ComputerLastLogon{

    <#

    .SYNOPSIS
    Gets the last time a computer was connected to an AD network.

    .DESCRIPTION
    Returns the name and last time a computer connected to the domain.
    
    .PARAMETER Name
    Target computer.

    .INPUTS
    Can pipe host names or AD computer objects to function.

    .OUTPUTS
    PS object with computer name and the last time is was connected to the domain.

    .NOTES
    None.

    .EXAMPLE
    Get-ComputerLastLogon

    Returns the last time the local host logged onto the domain.

    .EXAMPLE
    Get-ComputerLastLogon -Name "Borg"

    Returns the last time the computer "Borg" logged onto the domain.

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

        $lastLogonList

        return

    }

}

function Get-UserLastLogon{

    <#

    .SYNOPSIS
    Gets the last time a user logged onto the domain.

    .DESCRIPTION
    Returns  the last time a user or group of users logged onto the domain.

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

    .LINK
    By Ben Peterson
    linkedin.com/in/BenPetersonIT
    https://github.com/BenPetersonIT

    #>

    [cmdletbinding()]
    param(

        [parameter(Mandatory=$true,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true)]
        [string]$SamAccountName

    )

    begin{

        $lastLogonList = @()

    }

    process{

        $user = Get-ADUser -Identity $SamAccountName | Get-ADObject -Properties lastlogon | 
            Select-Object -Property lastlogon,name 

        $lastLogonProperties = @{
            "LastLogon" = ([datetime]::fromfiletime($user.lastlogon));
            "User" = ($user.name)
        }

        $lastLogonObject = New-Object -TypeName PSObject -Property $lastLogonProperties
        
        $lastLogonList += $lastLogonObject
        
    }

    end{

        $lastLogonList | Select-Object -Property User,LastLogon

        return

    }

}