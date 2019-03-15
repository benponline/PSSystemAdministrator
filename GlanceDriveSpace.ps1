<#

.NAME
GlanceDriveSpace

.SYNOPSIS
Gets information for the C drive of every AD computer and logs the computer name, drive, volume 
name, size, free space, and indicates those under 20% desc space remaining. Can be focused on a 
specific OU.

.SYNTAX
GetADComputerDiscSpace [-searchOU<string>]

.DESCRIPTION
Gets all the C drive information for every AD computer and logs the computer name, drive, volume 
name, size, free space, and indicates those under 20% desc space remaining. Can be focused the 
"computers" CN or on a specific top level OU.

.PARAMETERS
-searchOU <string>
	Specifies the top level OU the cmdlet will search.

	Required?                    False
	Accept pipeline input?       False
	Accept wildcard characters?  False

.INPUTS
None.
	You cannot pipe input to this cmdlet.

.OUTPUTS
Writes to the host the following information about the C drive of AD computers: computer name, 
drive, volume name, size, free space, and indicates those under 20% desc space remaining.  

.NOTES
The cmdlet tests each computer to see it if is online. If it is not reachable then it is 
noted in the results returned to the host.

.EXAMPLE 1
GetADComputerDiscSpace

Gets C drive information for every AD computer.

.EXAMPLE 2
GetADComputerDiscSpace -searchOU computers

Gets C drive information for every computer in the "computers" CN.

.EXAMPLE 3
GetDiscSpace -searchOU servers

Gets C drive information for every computer in the "servers" OU.

.RELATED LINKS

By Ben Peterson
linkedin.com/in/bpetersonmcts/
https://github.com/BenPetersonIT

#>

[CmdletBinding()]
Param(
    [string]$computerName = $env:COMPUTERNAME
)

$discSpaceLog = @()

#Main code

$discSpaceLog += Get-CimInstance -ComputerName $computerName -ClassName win32_logicaldisk -Property deviceid,volumename,size,freespace | 
    Where-Object -Property DeviceID -NE $null | 
    Select-Object -Property @{n="Computer";e={$computerName}},`
    @{n="Drive";e={$_.deviceid}},`
    @{n="VolumeName";e={$_.volumename}},`
    @{n="SizeGB";e={$_.size / 1GB -as [int]}},`
    @{n="FreeGB";e={$_.freespace / 1GB -as [int]}},`
    @{n="Under20Percent";e={if(($_.freespace / $_.size) -le 0.2){"True"}}}

$discSpaceLog | Format-Table -Property Computer,Drive,VolumeName,SizeGB,FreeGB,Under20Percent -Force

return