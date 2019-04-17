<#

    Glance Module

#>

#-----------------------------#
#--- GlanceADComputerError ---#
#-----------------------------#
function GlanceADComputerError {

    [CmdletBinding()]
    Param(

    [int]$Newest = 5

    )

    $errorLog = @()

    $computerSearch = ((Get-ADComputer -Filter *).name) | Sort-Object -Property Name

    #Gathers the system errors from the list of computers created above.
    Foreach($computer in $computerSearch){

        if(Test-Connection $computer -Quiet){

            try{

                $errorLog += Get-EventLog -ComputerName $computer -LogName System -EntryType Error -Newest $newest | 
                    Select-Object -Property @{n="Computer";e={$computer}},TimeWritten,EventID,InstanceID,Message
            
            }catch{}

        }
        
    }

    #Returns the array of errors to the console.
    $errorLog | Select-Object -Property Computer,TimeWritten,EventID,InstanceID,Message

    return

}

#--------------------------#
#--- GlanceADDiskHealth ---#
#--------------------------#

function GlanceADDiskHealth{

    $physicalDiskHealthLog = @()

    $computerSearch = ((Get-ADComputer -Filter *).name) | Sort-Object -Property name
    
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

}

#--------------------------#
#--- GlanceADDriveSpace ---#
#--------------------------#

function GlanceADDriveSpace {

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

}

#---------------------------#
#--- GlanceADFailedLogon ---#
#---------------------------#

function GlanceADFailedLogon{

    $failedLoginLog = @()

    $computerSearch = ((Get-ADComputer -Filter *).name) | Sort-Object -Property Name
    
    foreach($computerName in $computerSearch){
    
        try{
    
            $failedLogin = Get-EventLog -ComputerName $computerName -LogName Security -InstanceId 4625 -After ((Get-Date).AddDays(-1)) |
                Select-Object -Property @{n="ComputerName";e={$computerName}},TimeWritten,EventID
    
            $failedLoginLog += $failedLogin
    
        }catch{}
        
    }
    
    #Returns an array of PS objects with failed logon events.
    $failedLoginLog | Select-Object -Property ComputerName,TimeWritten,EventID
    
    return 

}

#--------------------------------#
#--- GlanceADOfflineComputer ---#
#--------------------------------#

function GlanceADOfflineComputers {

    $computers = Get-ADComputer -Filter *

    $offlineComputers = @()
    
    foreach($computer in $computers){
    
        if(!(Test-Connection -ComputerName ($computer.name) -Count 1 -Quiet)){
    
            $offlineComputers += $computer
    
        }
    
    }
    
    $offlineComputers | Select-Object -Property Name,DNSHostName,DistinguishedName
    
    return
    
}

#----------------------------#
#--- GlanceADOldComputer ---#
#----------------------------#
function GlanceADOldComputer{

    $MonthsOld = 3

    $lastLogonList = @()
    
    #Creates a list with all AD computers.
    $computers = Get-ADComputer -Filter * | Get-ADObject -Properties lastlogon | Select-Object -Property name,lastlogon | 
        Sort-Object -Property name
    
    #Adds computers that have not been online for the amount of months in MonthsOld.
    foreach($computer in $computers){
    
        if(([datetime]::fromfiletime($computer.lastlogon)) -lt ((Get-Date).AddMonths(($monthsOld * -1)))){
    
            $lastLogonProperties = @{
                "Last Logon" = ([datetime]::fromfiletime($computer.lastlogon));
                "Computer" = ($computer.name)
            }
    
            $lastLogonObject = New-Object -TypeName PSObject -Property $lastLogonProperties
        
            $lastLogonList += $lastLogonObject
        
        }
    
    }
    
    #Returns an array of PS objects with the computer name and last logon date.
    $lastLogonList
    
    return

}

#-----------------------#
#--- GlanceADOldUser ---#
#-----------------------#
function GlanceADOldUser{

    $MonthsOld = 3

    $lastLogonList = @()
    
    #Creates a list with all AD users.
    $users = Get-ADUser -Filter * | Get-ADObject -Properties lastlogon | 
        Select-Object -Property lastlogon,name | Sort-Object -Property name
    
    #Adds users that have not been online for the amount of months in MonthsOld.
    foreach($user in $users){
    
        if(([datetime]::fromfiletime($user.lastlogon)) -lt ((Get-Date).AddMonths($monthsOld * -1))){
    
            $lastLogonProperties = @{
                "LastLogon" = ([datetime]::fromfiletime($user.lastlogon));
                "User" = ($user.name)
            }
    
            $lastLogonObject = New-Object -TypeName PSObject -Property $lastLogonProperties
        
            $lastLogonList += $lastLogonObject
        
        }
    
    }
    
    #Returns an array of PS objects with user name and last logon dates.
    $lastLogonList | Select-Object -Property User,LastLogon
    
    return

}

#------------------------------#
#--- GlanceADOlineComputer ---#
#------------------------------#
function GlanceADOlineComputer{

    $computers = Get-ADComputer -Filter *

    $onlineComputers = @()
    
    foreach($computer in $computers){
    
        if(Test-Connection -ComputerName ($computer.name) -Count 1 -Quiet){
    
            $onlineComputers += $computer
    
        }
    
    }
    
    $onlineComputers | Select-Object -Property Name,DNSHostName,DistinguishedName
    
    return

}

#---------------------------#
#--- GlanceComputerError ---#
#---------------------------#
function GlanceComputerError{

    [CmdletBinding()]
    Param(
    
        [string]$ComputerName = "$env:COMPUTERNAME",
    
        [int]$Newest = 5
    
    )
    
    #Gathers system errors. 
    $errors = Get-EventLog -ComputerName $ComputerName -LogName System -EntryType Error -Newest $Newest |
        Select-Object -Property @{n="ComputerName";e={$ComputerName}},TimeWritten,EventID,InstanceID,Message
    
    #Returns array of PS objects with system error information including computer name, time written, 
    #event ID, instance ID, and message.
    $errors
    
    return

}

#--------------------------#
#--- GlanceComputerInfo ---#
#--------------------------#
function GlanceComputerInfo{

    [CmdletBinding()]
    Param(
    
        [string]$ComputerName = $env:COMPUTERNAME
    
    )
    
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
    
    #PS object that will store computer info.
    $computerInfo = New-Object -TypeName PSObject -Property $computerObjectProperties
    
    $computerInfo.computername = $ComputerName
    
    $computerInfo.model = (Get-CimInstance -ComputerName $ComputerName -ClassName Win32_ComputerSystem -Property Model).model
    
    $computerInfo.CPU = (Get-CimInstance -ComputerName $ComputerName -ClassName Win32_Processor -Property Name).name
    
    $computerInfo.memoryGB = [math]::Round(((Get-CimInstance -ComputerName $ComputerName -ClassName Win32_ComputerSystem -Property TotalPhysicalMemory).TotalPhysicalMemory / 1GB),1)
    
    #Gathers storage size of the C: drive.
    $computerInfo.storageGB = [math]::Round((((Get-CimInstance -ComputerName $ComputerName -ClassName win32_logicaldisk -Property Size) | 
        Where-Object -Property DeviceID -eq "C:").size / 1GB),1)
    
    #Gathers free space of the C: drive.
    $computerInfo.freespaceGB = [math]::Round((((Get-CimInstance -ComputerName $ComputerName -ClassName win32_logicaldisk -Property Freespace) | 
        Where-Object -Property DeviceID -eq "C:").freespace / 1GB),1)
    
    #Calculates is there is less than 20% free space on the C: drive.
    if($computerInfo.freespacegb / $computerInfo.storagegb -le 0.2){
        
        $computerInfo.under20percent = "TRUE"
    
    }else{
    
        $computerInfo.under20percent = "FALSE"
    
    }
    
    $computerInfo.currentuser = (Get-CimInstance -ComputerName $ComputerName -ClassName Win32_ComputerSystem -Property UserName).UserName
    
    $computerInfo.IPAddress = (Test-Connection -ComputerName $ComputerName -Count 1).IPV4Address
    
    $computerInfo | Select-Object -Property ComputerName,Model,CPU,MemoryGB,StorageGB,FreeSpaceGB,Under20Percent,CurrentUser,IPAddress
    
    return

}

#------------------------------#
#--- GlanceComputerSoftware ---#
#------------------------------#
function GlanceComputerSoftware{

    [cmdletbinding()]
    param(
     
        [string]$ComputerName = $env:COMPUTERNAME
        
    )
    
    $lmKeys = "Software\Microsoft\Windows\CurrentVersion\Uninstall","SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    $lmReg = [Microsoft.Win32.RegistryHive]::LocalMachine
    $cuKeys = "Software\Microsoft\Windows\CurrentVersion\Uninstall"
    $cuReg = [Microsoft.Win32.RegistryHive]::CurrentUser
    $masterKeys = @()
    
    try{
    
        if((Test-Connection -ComputerName $ComputerName -Count 1 -ErrorAction Stop)){
    
            $remoteCURegKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($cuReg,$ComputerName)
            $remoteLMRegKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($lmReg,$ComputerName)
    
            foreach($key in $lmKeys){
                $regKey = $remoteLMRegKey.OpenSubkey($key)
                    
                foreach ($subName in $regKey.GetSubkeyNames()) {
                    
                    foreach($sub in $regKey.OpenSubkey($subName)) {
                    
                        $masterKeys += (New-Object PSObject -Property @{
                            "ComputerName" = $ComputerName;
                            "Name" = $sub.getvalue("displayname");
                            "SystemComponent" = $sub.getvalue("systemcomponent");
                            "ParentKeyName" = $sub.getvalue("parentkeyname");
                            "Version" = $sub.getvalue("DisplayVersion");
                            "UninstallCommand" = $sub.getvalue("UninstallString");
                            "InstallDate" = $sub.getvalue("InstallDate");
                            "RegPath" = $sub.ToString()})
                    }
                            
                }
                        
            }
    
            foreach ($key in $cuKeys) {
    
                $regKey = $remoteCURegKey.OpenSubkey($key)
    
                if($regKey -ne $null){
    
                    foreach($subName in $regKey.getsubkeynames()){
    
                        foreach ($sub in $regKey.opensubkey($subName)) {
    
                            $masterKeys += (New-Object PSObject -Property @{
                                "ComputerName" = $ComputerName;
                                "Name" = $sub.getvalue("displayname");
                                "SystemComponent" = $sub.getvalue("systemcomponent");
                                "ParentKeyName" = $sub.getvalue("parentkeyname");
                                "Version" = $sub.getvalue("DisplayVersion");
                                "UninstallCommand" = $sub.getvalue("UninstallString");
                                "InstallDate" = $sub.getvalue("InstallDate");
                                "RegPath" = $sub.ToString()})
                            
                        }
                          
                    }
                        
                }
                    
            }
                    
        }else{
    
            break
    
        }
    
    }catch{}
    
    $woFilter = {$null -ne $_.name -AND $_.SystemComponent -ne "1" -AND $null -eq $_.ParentKeyName}
    $props = 'ComputerName','Name','Version','Installdate','UninstallCommand','RegPath'
    $masterKeys = ($masterKeys | Where-Object $woFilter | Select-Object -Property $props | Sort-Object -Property ComputerName)
    $masterKeys

}

#------------------------#
#--- GlanceDiskHealth ---#
#------------------------#
function GlanceDiskHealth{

    [CmdletBinding()]
    Param(
    
        [string]$ComputerName = $env:COMPUTERNAME
    
    )
    
    $physicalDisk = Get-PhysicalDisk -CimSession $ComputerName | 
        Where-Object -Property HealthStatus | 
        Select-Object -Property @{n="ComputerName";e={$ComputerName}},`
        FriendlyName,MediaType,OperationalStatus,HealthStatus,`
        @{n="SizeGB";e={[math]::Round(($_.Size / 1GB),1)}}
        
    $physicalDisk | Select-Object -Property ComputerName,FriendlyName,MediaType,OperationalStatus,HealthStatus,SizeGB
    
    Return

}

#------------------------#
#--- GlanceDriveSpace ---#
#------------------------#
function GlanceDriveSpace{

    [CmdletBinding()]
    Param(
    
        [string]$ComputerName = $env:COMPUTERNAME
    
    )
    
    $discSpaceLog = @()
    
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

}

#---------------------#
#--- GlancePingLog ---#
#---------------------#
function GlancePingLog{

    [CmdletBinding()]
    Param(
        
        [Parameter(Mandatory=$True)]
        [string]$Target,
        
        [Parameter(Mandatory=$True)]
        [int]$Minutes
    
    )
    
    #Variables
    
    $pingObject = New-Object System.Net.NetworkInformation.Ping
    
    $pingRecord = @()
    
    $startTime = Get-Date
    
    $minuteTicker = Get-Date
    
    #Functions
    
    function CreatePingObject{
    #Creates an object out of the information from a ping that returns information.
    
        $pingResults = New-Object -TypeName psobject -Property @{`
            "Status"=$targetPing.Status;`
            "Target"=$Target;`
            "Time"=(Get-Date -Format g);`
            "ResponseTime"=$targetPing.RoundtripTime}
    
        $pingResults
    
        return
    
    }
    
    function CreateFailedPingObject{
    #Creates an object with information about a ping that does not return information.
    
        $pingResults = New-Object -TypeName psobject -Property @{`
            "Status"="Failure";`
            "Target"=$Target;`
            "Time"=(Get-Date -Format g);`
            "ResponseTime"= 0}
    
        
        $pingResults
    
        return
    
    }
    
    #Main code
    
    While(((Get-Date) -le $startTime.AddMinutes($Minutes))){
    #Runs for the number of minutes stored in $Minutes.
        
        if((Get-Date) -ge $minuteTicker){
            
            Try{
    
                $targetPing = $pingObject.Send($Target)
    
                if(($targetPing.Status) -eq "Success"){
                #Ping found target.
                
                    $pingRecord += CreatePingObject
                                            
                }else{
                #Ping to target timed out.
                
                    $pingRecord += CreatePingObject
                }
            }catch{
            #Ping could not find target.
    
                $pingRecord += CreateFailedPingObject
    
            }
    
            $minuteTicker = $minuteTicker.AddMinutes(1)
            
        }
    
    }
    
    $pingRecord | Select-Object -Property status,target,time,ResponseTime
    
    Return

}