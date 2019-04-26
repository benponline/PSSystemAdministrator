<#

.NAME

.SYNOPSIS

.SYNTAX

.DESCRIPTION

.PARAMETERS

.INPUTS

.OUTPUTS

.NOTES

.EXAMPLE

.RELATED LINKS
By Ben Peterson
linkedin.com/in/BenPetersonIT
https://github.com/BenPetersonIT

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