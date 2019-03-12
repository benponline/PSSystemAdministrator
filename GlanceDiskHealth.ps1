<#

.NAME
GlanceDiskHealth

.SYNOPSIS
This script returns the health status of the physical disks on a computer.

.SYNTAX
GlanceDiskHealth [-ComputerName<string>]

.DESCRIPTION
This script returns the health status of the physical disks on the local or remote computer.

.PARAMETERS
-ComputerName <string>
Specifies the top level OU the cmdlet will search.

Defaul Vaule                    ""
Required?                       False
Accept pipeline input?          False
Accept wildcard characters?     False

.INPUTS
None. You cannot pipe input to this cmdlet.

.OUTPUTS
Returns array of objects with disk info including computer name, friendly name, media type, operational status, health status, and size in GB.

.NOTES
Only returns information from computers running Windows 10 or Windows Server 2012 or higher.

.EXAMPLE 1
GlanceDiskHealth
Returns disk health information for the local computer.

.EXAMPLE 2
GlanceADDiskHealth -ComputerName Computer1

Returns disk health information for the computer named Computer1.

.RELATED LINKS

By Ben Peterson
linkedin.com/in/bpetersonmcts/
https://github.com/BenPetersonIT

#>

[CmdletBinding()]
Param(
    [string]$computerName = ""
)

if($computerName -eq ""){
    $computerName = $env:COMPUTERNAME
}

$physicalDisk = Get-PhysicalDisk -CimSession $computerName | 
    Where-Object -Property HealthStatus | 
    Select-Object -Property @{n="ComputerName";e={$computerName}},`
    FriendlyName,MediaType,OperationalStatus,HealthStatus,`
    @{n="SizeGB";e={[math]::Round(($_.Size / 1GB),1)}}
    
$physicalDisk

Return