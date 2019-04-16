#[Alias('Computer','ComputerName','HostName')]
#[Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$true,Position=1)]

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