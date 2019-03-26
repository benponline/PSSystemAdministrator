<#

.NAME
GlanceADComputerError

.SYNOPSIS
This cmdlet gathers the newest system errors from AD computers.

.SYNTAX
GlanceADComputerError [-searchOU <string>] [-newest <int>]

.DESCRIPTION
This cmdlet gathers system errors from all AD computers, specific OUs, or the "Computers" container.
By default it searches every computer in AD and gathers the 5 newest system errors 

.PARAMETERS
-searchOU <string>
	Specifies the top level OU the cmdlet will search.

	Required?                   False
	Default value               ""
	Accept pipeline input?      False
	Accept wildcard characters? False

-newest <int>
    Specifies the number of recent system errors to be returned.

    Required?                   False
    Default value               5
    Accept pipeline input?      False
	Accept wildcard characters? False

.INPUTS
None. You cannot pipe input to this cmdlet.

.OUTPUTS
Returns PS objects containing system error information including Computer, TimeWritten, EventID, InstanceId, 
and Message.

.NOTES
This script can take a long time to finish if there are a large number of computers being contacted.

Requires:
- "Printer and file sharing" and "Network Discovery" to be enabled.
- Windows Server 2012, Windows 7, or newer. "Get-EventLog: No matched found" is returned when 
  the script contacts a computer running an OS older then is required.

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
linkedin.com/in/benpetersonIT
https://github.com/BenPetersonIT

#>

[CmdletBinding()]
Param(

    [string]$searchOU,

    [int]$newest = 5

)

$domainInfo = Get-ADDomain
$errorLog = @()

if($searchOU -eq ""){

    $computerSearch = ((Get-ADComputer -Filter *).name) | Sort-Object

}elseif($searchOU -eq "computers"){

    $computerSearch = ((Get-ADComputer -Filter * -SearchBase "CN=$searchOU, $domainInfo").name) | 
        Sort-Object

}else{

    $computerSearch = ((Get-ADComputer -Filter * -SearchBase "OU=$searchOU, $domainInfo").name) |
        Sort-Object

}

Foreach($computer in $computerSearch){

    if((Test-Connection $computer -Quiet) -eq $true){

        try{

            $errorLog += Get-EventLog -ComputerName $computer -LogName System -EntryType Error -Newest $newest | 
                Select-Object -Property @{n="Computer";e={$computer}},TimeWritten,EventID,InstanceID,Message
        
        }catch{}

    }
    
}

$errorLog

return