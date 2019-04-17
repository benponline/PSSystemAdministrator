<#

#>

$computers = Get-ADComputer -Filter *
$onlineComputers = @()

foreach($computer in $computers){

    if(Test-Connection -ComputerName ($computer.name) -Count 1 -Quiet){

        $onlineComputers += $computer

    }

}

$onlineComputers | Select-Object -Property Name,DNSHostName,DistinguishedName

return