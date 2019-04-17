<#

.NAME
GlanceADDriveSpace

.SYNOPSIS
This cmdlet returns information about drives connected to AD computer.

.SYNTAX
GlanceADDriveSpace [-SearchOU <string>]

.DESCRIPTION
This cmdlet returns information about the drives connected to all AD computers, those in specific 
organizational units, or the "computers" container.

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
Returns objects with disk info including computer name, device ID, storage in GB, free space in GB,
and an indicator if the drive has under 20 percent free space.

.NOTES


.EXAMPLE 1
GlanceADDriveSpace

Returns drive free space info for all computers in the domain.

.EXAMPLE 2
GlanceADDriveSpace -SearchOU "Servers"

Returns drive space information for all computers in the "Servers" OU.

.RELATED LINKS
By Ben Peterson
linkedin.com/in/BenPetersonIT
https://github.com/BenPetersonIT

#>

$driveSpaceLog = @()

$computerSearch = ((Get-ADComputer -Filter *).name) | Sort-Object -Property Name

#Gathers the drive info from the list of computers created above.
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

#Returns an array of PS objects with all the drive information.
$driveSpaceLog | Select-Object -Property ComputerName,DeviceID,StorageGB,FreeSpaceGB,Under20Percent

return