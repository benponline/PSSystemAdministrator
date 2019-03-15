<#

.NAME
GlanceADDiskHealth

.SYNOPSIS
This script returns the health status of the physical disks in computers conntected to a domain.

.SYNTAX
GlanceADDiskHealth [-searchOU<string>]

.DESCRIPTION
This script can search an entire domain or specific OU for the health status of the disks of the computers that belong to it.

.PARAMETERS
-searchOU<string>
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
Only returns information from computers running Windows Server 2012 or higher.

.EXAMPLE 1
GlanceADDiskHealth
Returns disk health information for all computers in the domain.

.EXAMPLE 2
GlanceADDiskHealth -searchOU "Servers"
Returns disk health information for all computers in the "Servers" OU.

.RELATED LINKS
By Ben Peterson
linkedin.com/in/bpetersonmcts/
https://github.com/BenPetersonIT

#>

[CmdletBinding()]
Param(
    [string]$searchOU = ""
)

$domaininfo = Get-ADDomain
$physicalDiskHealthLog = @()

if($searchOU -eq ""){
#If searchOU is not given a value, then the script creates a list of all AD computers.
    $computerSearch = ((Get-ADComputer -Filter *).name) | Sort-Object
}else{
#The value passed to searchOU is used to pull a list of computers from the desired OU.
    $computerSearch = ((Get-ADComputer -Filter * -SearchBase "OU=$searchOU, $domainInfo").name) | Sort-Object
}

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

$physicalDiskHealthLog

Return