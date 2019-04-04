<#

.NAME
GlanceADFailedLogon

.SYNOPSIS
This script returns a list of failed logon events from computers on a domain.

.SYNTAX
GlanceADFailedLogon [-searchOU <string>]

.DESCRIPTION
This script can search all the computers in a domain or specific OU for failed log on events.

.PARAMETERS
-searchOU <string>

    Specifies the top level OU the cmdlet will search.

    Defaul Vaule                    ""
    Required?                       False
    Accept pipeline input?          False
    Accept wildcard characters?     False

.INPUTS
None. You cannot pipe input to this cmdlet.

.OUTPUTS
Returns objects with computer names, time written, and event IDs for failed logon events.

.NOTES

.EXAMPLE 1
GlanceADFailedLogon

Returns failed logon events from all computers in the domain.

.EXAMPLE 2
GlanceADFailedLogon -searchOU "Servers"

Returns failed logon events from all computers in the "Servers" OU.

.RELATED LINKS
By Ben Peterson
linkedin.com/in/benpetersonIT
https://github.com/BenPetersonIT

#>

[CmdletBinding()]
Param(

    [string]$SearchOU

)

$failedLoginLog = @()
$domainInfo = Get-ADDomain

if($searchOU -eq ""){

    $computerSearch = ((Get-ADComputer -Filter *).name) | Sort-Object

}else{

    $computerSearch = ((Get-ADComputer -Filter * -SearchBase "OU=$searchOU, $domainInfo").name) | Sort-Object

}

foreach($computerName in $computerSearch){

    try{

        $failedLogin = Get-EventLog -ComputerName $computerName -LogName Security -InstanceId 4625 -After ((Get-Date).AddDays(-1)) |
            Select-Object -Property @{n="ComputerName";e={$computerName}},TimeWritten,EventID

        $failedLoginLog += $failedLogin

    }catch{}
    
}

$failedLoginLog

return 