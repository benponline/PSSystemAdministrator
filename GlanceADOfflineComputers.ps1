<#


#>

$computers = Get-ADComputer -Filter *

$offlineComputers = @()

foreach($computer in $computers){

    if(!(Test-Connection -ComputerName ($computer.name) -Count 1 -Quiet)){

        $offlineComputers += $computer

    }

}

$offlineComputers | Select-Object -Property Name,DNSHostName,DistinguishedName

return