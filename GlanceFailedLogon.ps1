<#

.NAME
GlanceADFailedLogon

.SYNOPSIS
This cmdlet returns a list of failed logon events from AD computers.

.SYNTAX
GlanceADFailedLogon [-SearchOU <string>]

.DESCRIPTION
This cmdlet can return failed logon events from all AD computers, computers in a specific 
organizational unit, or computers in the "computers" container.

.PARAMETERS
-SearchOU <string>
    Specifies the top level OU the cmdlet will search.

    Defaul Vaule                    ""
    Required?                       False
    Accept pipeline input?          False
    Accept wildcard characters?     False

.INPUTS
None. You cannot pipe input to this cmdlet.

.OUTPUTS
Returns PS objects with computer names, time written, and event IDs for failed logon events.

.NOTES

.EXAMPLE 1
GlanceADFailedLogon

Returns failed logon events from all computers in the domain.

.EXAMPLE 2
GlanceADFailedLogon -searchOU "Servers"

Returns failed logon events from all computers in the "Servers" OU.

.RELATED LINKS
By Ben Peterson
linkedin.com/in/BenPetersonIT
https://github.com/BenPetersonIT

#>

[CmdletBinding()]
Param(

    [string]$ComputerName = $env:COMPUTERNAME,

    [int]$daysBack = 1

)

$failedLogon = Get-EventLog -ComputerName $computerName -LogName Security -InstanceId 4625 -After ((Get-Date).AddDays($daysBack * -1)) |
    Select-Object -Property @{n="ComputerName";e={$computerName}},TimeWritten,EventID

$failedLogon | Select-Object -Property ComputerName,TimeWritten,EventID

return 