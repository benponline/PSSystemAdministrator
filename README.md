# PSSystemAdministrator
This module contains functions useful for administrating a Windows Active Directory domain with a single DHCP scope. Many of the functions are designed to work with eachother. Functions that gather information on users or computers can be piped into functions that take an action. For instance, you can pipe a function that returns computers that have not logged onto the network for 30 days into a function that disables computer accounts. In a single line of code, you can disable all the inactive computers in active directory. There are a wide variety of functions that perform other tasks like sending magic packets for wake on lan, measuring directory and sub-directory sizes, gathering large files, and other tasks. Every function is fully documented and works with the `Get-Help` function. 

This module is written for PowerShell Core and tested with Windows 10 machines. I am actively developing this module alongside my work as a system administrator. I use this module every day.

## Installation
1. Download the PSSystemAdministrator.psm1 file.
2. Open the PowerShell modules folder on your computer.
   - For PowerShell Core it is located here: \Documents\PowerShell\Modules
3. Create a folder named “PSSystemAdministrator”.
4. Place the PSSystemAdministrator.psm1 file in the new folder.
5. Open your version of PowerShell and run the following command: 
`Set-ExecutionPolicy -ExecutionPolicy RemoteSigned`
6. This will allow PowerShell to read the contents of the module.
7. Open a new PowerShell session and you are good to go.

## Functions
`Add-DHCPReservation` Adds a reservation in DHCP for a computer.

`Disable-Computer` Disables a computer.

`Disable-User` Disables a user.

`Disconnect-Users` Signs out all users on a computer.

`Enable-Computer` Enables an AD computer account.

`Enable-User` Enables an AD user account.

`Enable-WakeOnLan` Configures a computer to allow wake on lan.

`Get-AccessedFile` Gets all files in a directory that have been accessed in the last 24 hours.

`Get-ActiveComputer` Gets a list of computers that have logged onto the domain in the last 30 days.

`Get-ActiveFile` Gets all files in a directory that have been written in the last 24 hours.

`Get-ActiveUser` Gets a list of all users that have logged on in the last 30 days.

`Get-ChildItemLastAccessTime` Gets all files in a directory and returns information including file name and last access time.

`Get-ChildItemLastWriteTime` Gets all files in a directory and returns information including last write time.

`Get-ComputerCurrentUser` Gets the current user logged onto a computer.

`Get-ComputerDriveInformation` Gets information about the drives on a computer.

`Get-ComputerFailedLogonEvent` Gets failed logon events from a computer in the last day.

`Get-ComputerInformation` Gets general information about a computer.

`Get-ComputerIPAddress` Gets the IPv4 address of a computer.

`Get-ComputerLastBootUpTime` Gets the last time a computer booted up.

`Get-ComputerLastLogonTime` Gets the last time a computer logged onto the domain.

`Get-ComputerMemory` Gets the memory in GB of a computer.

`Get-ComputerModel` Gets the model of a computer.

`Get-ComputerOS` Gets the operating system name of a computer.

`Get-ComputerPhysicalDiskInformation` Gets information about the physical disks of a computer.

`Get-ComputerProcessor` Gets the processor of a computer.

`Get-ComputerShareFolder` Gets all of the share folders on a computer.

`Get-ComputerSoftware` Gets all of the installed software on a computer.

`Get-ComputerSystemEvent` Gets system events from a computer.

`Get-CredentialExportToXML` Gets credentials from the user and exports them to location provided by the user.

`Get-DHCPReservation` Gets all reservations for a computer in DHCP.

`Get-DirectorySize` Gets the size of a directory.

`Get-DisabledComputer` Gets a list of all computers that are disabled.

`Get-DisabledUser` Gets a list of all users that are disabled. 

`Get-InactiveComputer` Gets computers that have not logged onto the domain for more than 30 days.

`Get-InactiveFile` Gets all files in a directory that have not been accessed in the last 24 hours.

`Get-InactiveUser` Gets a list of all users that have not logged on to the domain for 30 days.

`Get-ItemLastAccessTime` Gets the last access time from an item.

`Get-ItemLastWriteTime` Gets the last write time from an item.

`Get-LargeFile` Gets files larger than 500 MB from a directory.

`Get-LockedOutUser` Gets locked out users from Active Directory.

`Get-LockedOutUserEvent` Gets events about user accounts getting locked in Active Directory.

`Get-OfflineComputer` Gets all computers that are offline. 

`Get-OnlineComputer` Gets computers that are online.

`Get-OUComputer` Gets computers from a specific organizational unit.

`Get-OUUser` Gets users from a specific organizational unit.

`Get-SubDirectorySize` Gets directory names and sizes.

`Get-UserActiveLogon` Gets all computers where a user is logged in.

`Get-UserLastLogonTime` Gets the last time a user logged onto the domain.

`Move-Computer` Moves a computer to an organizational unit.

`Move-User` Moves a user to an organizational unit.

`Remove-Computer` Removes a computer from Active Directory.

`Remove-DHCPReservation` Removes a reservation for a computer in DHCP.

`Remove-User` Removes a user from Active Directory.

`Set-ComputerIPAddress` Sets the IP address of a computer.

`Set-UserChangePassword` Sets user account to require a password change at the next log on.

`Start-Computer` Starts a remote computer by sending a magic packet.

`Test-NetworkSpeed` Tests the network speed between the machine running this function and a remote machine.

`Unlock-User` Unlocks an AD user account.
