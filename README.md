# PSGlance
PSGlance is a PowerShell module with a set of tools designed to quickly gather information in an active directory environment.

Get-ADOfflineComputer

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
    Firewalls must be configured to allow ping requests.

    .EXAMPLE
    Get-ADOfflineComputer

    Returns a list of all AD computers that are currently offline.

Get-ADOldComputer

    .SYNOPSIS
    Gets a list of all the computers in AD that have not been online for a specific number of months.

    .DESCRIPTION
    Returns a list of all the computers in AD that have not been online a number of months. The default amount of months is 
    3. Can be set by the user by passing a value to MonthsOld. 

    .PARAMETER MonthsOld
    Determines how long the computer account has to be inactive for it to be returned.

    .INPUTS
    None.

    .OUTPUTS
    PS objects with information including computer names and the date it last connected to the domain.

    .NOTES
    Function is intended to help find retired computers that have not been removed from AD.

    .EXAMPLE
    Get-ADOldComputer

    Lists all computers in the domain that have not been online for more than 6 months.

    .EXAMPLE
    Get-ADOldComputer -MonthsOld 2

    Lists all computers in the domain that have not checked in for more than 2 months.

Get-ADOldUser

    .SYNOPSIS
    Gets a list of all the users in AD that have not logged on for a number amount of months.

    .DESCRIPTION
    Returns a list of all the users in AD that have not been online a number of months. The default amount of months is 3. 
    Can be set by the user by passing a value to MonthsOld.

    .PARAMETER MonthsOld
    Determines how long the user account has to be inactive for it to be returned.

    .INPUTS
    None.

    .OUTPUTS
    PS objects with user names and last logon date.

    .NOTES
    Function is intended to help find inactive user accounts.

    .EXAMPLE
    Get-ADOldUser

    Lists all users in the domain that have not checked in for more than 6 months.

    .EXAMPLE
    Get-ADOldUser -MonthsOld 2

    Lists all users in the domain that have not checked in for more than 2 months.

Get-ADOnlineComputer

    .SYNOPSIS
    Gets a list of AD computers that are currently online.

    .DESCRIPTION
    Returns an array of PS objects containing the name, DNS host name, and distinguished name of AD computers that are 
    currently online. 

    .INPUTS
    None.

    .OUTPUTS
    PS objects containing name, DNS host name, and distinguished name.

    .NOTES

    .EXAMPLE
    Get-ADOnlineComputer

    Returns list of all AD computers that are currently online.

Get-ComputerError

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

Get-ComputerInformation

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
    Get-ADComputer | Get-ComputerInformation

    Returns computer information on all AD computers. 

Get-ComputerSoftware

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
    Get-ComputerSoftware -Filter * | GlanceComputerSoftware

    This cmdlet returns the installed software on all computers on the domain.

Get-DiskHealth

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

Get-DriveSpace

    .SYNOPSIS
    Gets information for the drives on a computer including computer name, drive, volume, name, 
    size, free space, and indicates those under 20% desc space remaining.

    .DESCRIPTION
    Gathers information for the drives on a computer including computer name, drive, volume, name, 
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

Get-FailedLogon

    .SYNOPSIS
    Gets a list of failed logon events from AD computers.

    .DESCRIPTION
    This function can return failed logon events from the local computer, remote computer, or group of computers.

    .PARAMETER Name
    Specifies the computer the function gathers information from.

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

Get-ComputerLastLogon

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

Get-UserLastLogon

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