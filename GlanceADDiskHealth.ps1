<#

.NAME
GlanceADDiskHealth

.SYNOPSIS
This cmdlet returns the health status of the physical disks in AD computers.

.SYNTAX
GlanceADDiskHealth [-searchOU <string>]

.DESCRIPTION
This cmdlet returns physical disk health information from all AD computers, specific 
organizational units, or the "computers" container. By default, it returns disk info from all AD
computers.

.PARAMETERS
-SearchOU <string>
    Specifies the top level OU the cmdlet will search.

    Defaul Vaule                    ""
    Required?                       False
    Accept pipeline input?          False
    Accept wildcard characters?     False

.INPUTS
None. You cannot pipe input to this cmdlet.

.OUTPUTS
Returns array of objects with physical disk info including computer name, friendly name, media 
type, operational status, health status, and size in GB.

.NOTES
Only returns information from computers running Windows Server 2012, Windows 7 or higher.

.EXAMPLE 1
GlanceADDiskHealth

Returns disk health information for all computers in the domain.

.EXAMPLE 2
GlanceADDiskHealth -searchOU "Servers"

Returns disk health information for all computers in the "Servers" OU.

.RELATED LINKS
By Ben Peterson
linkedin.com/in/benpetersonIT
https://github.com/BenPetersonIT

#>

[CmdletBinding()]
Param(

    [string]$SearchOU

)

$domaininfo = Get-ADDomain

$physicalDiskHealthLog = @()

#Gathers a list of computers based on what is passed to the SearchOU parameter.
if($searchOU -eq ""){

    $computerSearch = ((Get-ADComputer -Filter *).name) | Sort-Object

}elseif($searchOU -eq "computers"){

    $computerSearch = ((Get-ADComputer -Filter * -SearchBase "CN=$searchOU, $domainInfo").name) | 
        Sort-Object

}else{

    $computerSearch = ((Get-ADComputer -Filter * -SearchBase "OU=$searchOU, $domainInfo").name) | Sort-Object

}

#Gathers the physical disk info from the list of computers created above.
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

#Returns the array of PS objects to the console with the properties in the order shown in the command.
$physicalDiskHealthLog | Select-Object -Property ComputerName,FriendlyName,MediaType,OperationalStatus,HealthStatus,SizeGB

Return