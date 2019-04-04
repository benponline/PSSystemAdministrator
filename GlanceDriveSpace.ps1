<#

.NAME
GlanceDriveSpace

.SYNOPSIS
Gets information for the C drive of every AD computer and logs the computer name, drive, volume 
name, size, free space, and indicates those under 20% desc space remaining. Can be focused on a 
specific OU.

.SYNTAX
GlanceDriveSpace [-computerName <string>]

.DESCRIPTION
Gets information for all drives on a specific computer. Information includes computer name, drive, 
volume name, size, free space, and indicates those under 20% desc space remaining.

.PARAMETERS
-computerName <string>
	Specifies the computer the cmdlet will search.

    Required?                   False
    Defaul value                $env:COMPUTERNAME       
	Accept pipeline input?      False
	Accept wildcard characters? False

.INPUTS
None.
	You cannot pipe input to this cmdlet.

.OUTPUTS
Returns PS objects to the host the following information about the drives on a computer: computer name, drive, 
volume name, size, free space, and indicates those under 20% desc space remaining.  

.NOTES


.EXAMPLE 1
GlanceDriveSpace

    Gets drive information for the local host.

.EXAMPLE 2
GlanceDriveSpace -computerName computer

    Gets drive information for "computer".

.RELATED LINKS
By Ben Peterson
linkedin.com/in/benpetersonIT
https://github.com/BenPetersonIT

#>

[CmdletBinding()]
Param(

    [string]$ComputerName = $env:COMPUTERNAME

)

$discSpaceLog = @()

#Main code

$discSpaceLog += Get-CimInstance -ComputerName $ComputerName -ClassName win32_logicaldisk -Property deviceid,volumename,size,freespace | 
    Where-Object -Property DeviceID -NE $null | 
    Select-Object -Property @{n="Computer";e={$ComputerName}},`
    @{n="Drive";e={$_.deviceid}},`
    @{n="VolumeName";e={$_.volumename}},`
    @{n="SizeGB";e={$_.size / 1GB -as [int]}},`
    @{n="FreeGB";e={$_.freespace / 1GB -as [int]}},`
    @{n="Under20Percent";e={if(($_.freespace / $_.size) -le 0.2){"True"}else{"False"}}}

$discSpaceLog | Select-Object -Property Computer,Drive,VolumeName,SizeGB,FreeGB,Under20Percent

return