<#

.NAME
GlanceComputerSoftware

.SYNOPSIS
This cmdlet gathers all of the installed software on a computer.

.SYNTAX
GlanceComputerSoftware [-Name <string>]

.DESCRIPTION
This cmdlet gathers all of the installed software on a computer.  or group of computers.  

.PARAMETERS
-ComputerName <string>
	A list of installed software will be pulled from this computer 

	Required?                   False
	Default value               $env:COMPUTERNAME
	Accept pipeline input?      True
	Accept wildcard characters? False

.INPUTS
You can pipe input to this cmdlet.

.OUTPUTS
Returns PS objects containing computer name, software name, version, installdate, uninstall 
command, registry path.

.NOTES

Requires:
Remote registry service running.

.EXAMPLE 1
GlanceComputerSoftware

This cmdlet returns all installed software on the local host.

.EXAMPLE 2
GlanceComputerSoftware -ComputerName “Computer”

This cmdlet returns all the software installed on "Computer".

.EXAMPLE 3
Get-ADComputer -Filter * | GlanceComputerSoftware

This cmdlet returns the installed software on all computers on the domain.

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
    [string]$ComputerName = $env:COMPUTERNAME
    
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

            Write-Error -Message "Unable to contact $ComputerName. Please verify its network connectivity and try again." -Category ObjectNotFound -TargetObject $ComputerName
            Break
        }

    }catch{

        $masterKeys += (New-Object PSObject -Property @{
            "ComputerName" = $ComputerName;
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
    $props = 'ComputerName','Name','Version','Installdate','UninstallCommand','RegPath'
    $masterKeys = ($masterKeys | Where-Object $woFilter | Select-Object -Property $props | Sort-Object -Property ComputerName)
    $masterKeys

}