<#

.NAME
GlanceComputerInfo

.SYNOPSIS
This cmdlet gathers infomation about a computer.

.SYNTAX
GlanceComputerInfo [-ComputerName <string>]

.DESCRIPTION
This cmdlet gathers infomation about a computer. By default it gathers info from the local host.
The information includes computer name, model, CPU, memory in GB, storage in GB, free space in GB, 
if less than 20 percent of storage is left, the current user, and IP address.

.PARAMETERS
-ComputerName <string>
	Specifies the computer.

	Required?                   False
	Default value               $env:COMPUTERNAME
	Accept pipeline input?      False
	Accept wildcard characters? False

.INPUTS
None. You cannot pipe input to this cmdlet.

.OUTPUTS
Returns an object with computer name, model, CPU, memory in GB, storage in GB, free space in GB, if
less than 20 percent of storage is left, and the current user.

.NOTES

.EXAMPLE 1
GlanceComputerInfo -ComputerName Server1

This returns computer into on Server1.

.RELATED LINKS
By Ben Peterson
linkedin.com/in/BenPetersonIT
https://github.com/BenPetersonIT

#>

$ErrorActionPreference = "Stop"

$computerList = (Get-ADComputer -Filter *).name | Sort-Object -Property Name

$computerLog = @()

#PS object properties for to store computer info.
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

foreach($ComputerName in $computerList){

    try{

        $computerInfo = New-Object -TypeName PSObject -Property $computerObjectProperties

        $computerInfo.computername = $ComputerName

        $computerInfo.model = (Get-CimInstance -ComputerName $ComputerName -ClassName Win32_ComputerSystem -Property Model).model

        $computerInfo.CPU = (Get-CimInstance -ComputerName $ComputerName -ClassName Win32_Processor -Property Name).name

        $computerInfo.memoryGB = [math]::Round(((Get-CimInstance -ComputerName $ComputerName -ClassName Win32_ComputerSystem -Property TotalPhysicalMemory).TotalPhysicalMemory / 1GB),1)

        $computerInfo.storageGB = [math]::Round((((Get-CimInstance -ComputerName $ComputerName -ClassName win32_logicaldisk -Property Size) | 
            Where-Object -Property DeviceID -eq "C:").size / 1GB),1)

        $computerInfo.freespaceGB = [math]::Round((((Get-CimInstance -ComputerName $ComputerName -ClassName win32_logicaldisk -Property Freespace) | 
            Where-Object -Property DeviceID -eq "C:").freespace / 1GB),1)

        if($computerInfo.freespacegb / $computerInfo.storagegb -le 0.2){
            
            $computerInfo.under20percent = "TRUE"

        }else{

            $computerInfo.under20percent = "FALSE"

        }

        $computerInfo.currentuser = (Get-CimInstance -ComputerName $ComputerName -ClassName Win32_ComputerSystem -Property UserName).UserName

        $computerInfo.IPAddress = (Test-Connection -ComputerName $ComputerName -Count 1).IPV4Address

        $computerLog += $computerInfo

    }catch{}

}

$computerLog | Select-Object -Property ComputerName,Model,CPU,MemoryGB,StorageGB,FreeSpaceGB,Under20Percent,CurrentUser,IPAddress

return