<#

.NAME
GlanceComputerInfo

.SYNOPSIS
This cmdlet gathers infomation about a computer.

.SYNTAX
GlanceComputerInfo [-computer<string>]

.DESCRIPTION
This cmdlet gathers infomation about a computer. The information includes computer name, 
model, CPU, memory in GB, storage in GB, free space in GB, if less than 20 percent of 
storage is left, the current user, and IP address.

.PARAMETERS
-ComputerName <string>
	Specifies the computer whos information is gathered.

	Required?                   False
	Default value               Localhost
	Accept pipeline input?      False
	Accept wildcard characters? False

.INPUTS
None. You cannot pipe input to this cmdlet.

.OUTPUTS
Returns an object with computer name, model, CPU, memory in GB, storage in GB, free space
in GB, if less than 20 percent of storage is left, and the current user.

.NOTES

.EXAMPLE 1
GlanceComputerInfo -ComputerName Server1
This returns computer into on Server1.

.RELATED LINKS
By Ben Peterson
linkedin.com/in/benpetersonIT
https://github.com/BenPetersonIT

#>

[CmdletBinding()]
Param(

    [string]$ComputerName = $env:COMPUTERNAME

)

$computerObjectProperties = @{
  "ComputerName" = "";
  "Model" = "";
  "CPU" = "";
  "MemoryGB" = "";
  "StorageGB" = "";
  "FreeSpaceGB" = "";
  "Under20Percent" = "";
  "CurrentUser" = "";
  "IPAddress" = ""
}
#Creates properties that will be gathered from the computer.

$computerInfo = New-Object -TypeName PSObject -Property $computerObjectProperties
#Creates the PowerShell Object that will hold the computer info being gathered.

$computerInfo.computername = $ComputerName
#Store computer name

$computerInfo.model = (Get-CimInstance -ComputerName $ComputerName -ClassName Win32_ComputerSystem -Property Model).model
#Gathers computer model

$computerInfo.CPU = (Get-CimInstance -ComputerName $ComputerName -ClassName Win32_Processor -Property Name).name
#Gather computer CPU info

$computerInfo.memoryGB = [math]::Round(((Get-CimInstance -ComputerName $ComputerName -ClassName Win32_ComputerSystem -Property TotalPhysicalMemory).TotalPhysicalMemory / 1GB),1)
#Gather RAM amount in GB

$computerInfo.storageGB = [math]::Round((((Get-CimInstance -ComputerName $ComputerName -ClassName win32_logicaldisk -Property Size) | Where-Object -Property DeviceID -eq "C:").size / 1GB),1)
#Gather storage space in GB

$computerInfo.freespaceGB = [math]::Round((((Get-CimInstance -ComputerName $ComputerName -ClassName win32_logicaldisk -Property Freespace) | Where-Object -Property DeviceID -eq "C:").freespace / 1GB),1)
#Gather freeSpace in GB

if($computerInfo.freespacegb / $computerInfo.storagegb -le 0.2){
    
    $computerInfo.under20percent = "TRUE"

}else{

    $computerInfo.under20percent = "FALSE"

}
#Records if there is less than 20 percent of stogare space left.

$computerInfo.currentuser = (Get-CimInstance -ComputerName $ComputerName -ClassName Win32_ComputerSystem -Property UserName).UserName
#Gathers name of current user

$computerInfo.IPAddress = (Test-Connection -ComputerName $ComputerName -Count 1).IPV4Address
#add computer IPv4.

$computerInfo | Select-Object -Property ComputerName,Model,CPU,MemoryGB,StorageGB,FreeSpaceGB,Under20Percent,CurrentUser,IPAddress

return