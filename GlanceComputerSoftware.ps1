<#

.NAME
GlanceComputerSoftware

.SYNOPSIS
This cmdlet gathers system errors from AD computers.

.SYNTAX
GlanceADComputerError [-searchOU <string>] [-newest <int>]

.DESCRIPTION
This cmdlet gathers system errors from all AD computers, specific organizational units, or the 
"Computers" container. By default, it gathers the newest 5 system errors from every AD computer.  

.PARAMETERS
-SearchOU <string>
	Specifies the top level OU the cmdlet will search.

	Required?                   False
	Default value               ""
	Accept pipeline input?      False
	Accept wildcard characters? False

-Newest <int>
    Specifies the number of recent system errors to be returned.

    Required?                   False
    Default value               5
    Accept pipeline input?      False
	Accept wildcard characters? False

.INPUTS
None. You cannot pipe input to this cmdlet.

.OUTPUTS
Returns PS objects containing system error information including Computer, TimeWritten, EventID, 
InstanceId, and Message.

.NOTES
This cmdlet can take a long time to finish if there are a large number of computers/errors.

Requires:
"Printer and file sharing" and "Network Discovery" to be enabled.

Windows Server 2012, Windows 7, or newer. "Get-EventLog: No matched found" is returned when the 
script contacts a computer running an OS older then is required.

.EXAMPLE 1
GlanceADComputerError

This cmdlet returns the 5 newest system errors from all AD computers.

.EXAMPLE 2
GetComputerError -searchOU “computers” -newest 2

This cmdlet returns the 2 newest system errors from all computers in the “Computers” CN.

.EXAMPLE 3
GetComputerError -searchOU “Servers”

This cmdlet returns the 5 newest system errors from computers in the AD “Servers” OU.

.RELATED LINKS
By Ben Peterson
linkedin.com/in/BenPetersonIT
https://github.com/BenPetersonIT

Based on code from:
https://community.spiceworks.com/scripts/show/2170-get-a-list-of-installed-software-from-a-remote-computer-fast-as-lightning

#>

[cmdletbinding()]
param(
 
    [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true,Position=1)]
    [string]$Name = $env:COMPUTERNAME
    
)

begin{

    $lmKeys = "Software\Microsoft\Windows\CurrentVersion\Uninstall","SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    $lmReg = [Microsoft.Win32.RegistryHive]::LocalMachine
    $cuKeys = "Software\Microsoft\Windows\CurrentVersion\Uninstall"
    $cuReg = [Microsoft.Win32.RegistryHive]::CurrentUser
    $masterKeys = @()

}

process{

    try{

        if((Test-Connection -ComputerName $Name -Count 1 -ErrorAction Stop)){

            Write-Host "$Name is online."
            
            $remoteCURegKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($cuReg,$Name)
            $remoteLMRegKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($lmReg,$Name)

            foreach($key in $lmKeys){
                $regKey = $remoteLMRegKey.OpenSubkey($key)
                
                foreach ($subName in $regKey.GetSubkeyNames()) {
                
                    foreach($sub in $regKey.OpenSubkey($subName)) {
                
                        $masterKeys += (New-Object PSObject -Property @{
                            "ComputerName" = $Name;
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
                                "ComputerName" = $Name;
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

            Write-Error -Message "Unable to contact $Name. Please verify its network connectivity and try again." -Category ObjectNotFound -TargetObject $Name
            Break
        }

    }catch{

        Write-Host "$Name is offline."

        $masterKeys += (New-Object PSObject -Property @{
            "ComputerName" = $Name;
            "Name" = "Offline";
            "SystemComponent" = "2";
            "ParentKeyName" = "offline";
            "Version" = "";
            "UninstallCommand" = "";
            "InstallDate" = "";
            "RegPath" = ""})

    }

}

end{
 
    $woFilter = {$null -ne $_.name -AND $_.SystemComponent -ne "1" -AND $null -eq $_.ParentKeyName}
    $props = 'ComputerName','Name','Version'#,'Installdate','UninstallCommand','RegPath'
    $masterKeys = ($masterKeys | Where-Object $woFilter | Select-Object -Property $props | Sort-Object -Property ComputerName)
    $masterKeys

}