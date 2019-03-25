<#

.NAME
GlanceADDriveSpace

.SYNOPSIS
This script returns the free space of the drives connected to computers in a domain.

.SYNTAX
GlanceADDriveSpace [-searchOU <string>]

.DESCRIPTION
This script can search an entire domain or specific OU for the freespace on the drives of computers that belong to it.

.PARAMETERS
-searchOU <string>
Specifies the top level OU the cmdlet will search.

Defaul Vaule                    ""
Required?                       False
Accept pipeline input?          False
Accept wildcard characters?     False

.INPUTS
None. You cannot pipe input to this cmdlet.

.OUTPUTS
Returns objects with disk info including computer name, device ID, storage in GB, free space in GB, and an indicator if the drive has under 20 percent free space.

.NOTES

.EXAMPLE 1
GlanceADDriveSpace
Returns drive free space info for all computers in the domain.

.EXAMPLE 2
GlanceADDriveSpace -searchOU "Servers"
Returns drive space information for all computers in the "Servers" OU.

.RELATED LINKS
By Ben Peterson
linkedin.com/in/benpetersonIT
https://github.com/BenPetersonIT

#>

[CmdletBinding()]
Param(
    [string]$searchOU = ""
)

$domainInfo = Get-ADDomain
$driveSpaceLog = @()

if($searchOU -eq ""){
    $computerSearch = ((Get-ADComputer -Filter *).name) | Sort-Object
}else{
    $computerSearch = ((Get-ADComputer -Filter * -SearchBase "OU=$searchOU, $domainInfo").name) | Sort-Object
}

foreach($computerName in $computerSearch){
    try{
        $driveSpace = Get-CimInstance -ComputerName $computerName -ClassName win32_logicaldisk | 
            Select-Object -Property @{name="ComputerName";expression={$computerName}},`
            @{name="DeviceID";expression={$_.deviceid}},`
            @{name="StorageGB";expression={[math]::Round(($_.size / 1GB),1)}},`
            @{name="FreeSpaceGB";expression={[math]::Round(($_.freespace / 1GB),1)}},`
            @{name="Under20Percent";expression={if($_.freespace / $_.size -le 0.2){"True"}else{"False"}}}
        $driveSpaceLog += $driveSpace
    }catch{}
}

$driveSpaceLog

return