<#

.NAME
GlanceADComputerError

.SYNOPSIS
This cmdlet gathers system errors in the last day from AD computers.

.SYNTAX
GetComputerError [-searchOU <string>] [-daysBack <int>]

.DESCRIPTION
This cmdlet gathers system errors from all AD computers. You can limit the 
scope to any top level OU in AD or the "Computers" container. By default it gathers
errors going back one day, but can be set to search as many days back as needed. 

.PARAMETERS
-searchOU <string>
	Specifies the top level OU the cmdlet will search.

	Required?                   False
	Default value               ""
	Accept pipeline input?      False
	Accept wildcard characters? False

-daysBack <int>
    Specifies the numbers of days back the cmdlet will search for errors.

    Required?                   False
    Default value               1
    Accept pipeline input?      False
	Accept wildcard characters? False

.INPUTS
None. You cannot pipe input to this cmdlet.

.OUTPUTS
Returns computer system errors along with Computer, TimeWritten, EventID, InstanceId, 
and Message.

.NOTES
This script can take a long time to finish if there are a large number of
computers being contacted.

Requires:
- "Printer and file sharing" and "Network Discovery" to be enabled.
- Windows Server 2012, Windows 7, or newer. "Get-EventLog: No matched found" is returned when 
  the script contacts a computer running an OS older then is required.

.EXAMPLE 1
GlanceADComputerError

This cmdlet returns system errors from all AD computers from the last day.

.EXAMPLE 2
GetComputerError -searchOU “computers” -daysBack 2

This cmdlet returns system errors from all computers in the AD “Computers” CN from the last 2 days.

.EXAMPLE 3
GetComputerError -searchOU “Servers”

This cmdlet returns system errors from all computers in the AD “Servers” OU from the last day.

.RELATED LINKS
By Ben Peterson
linkedin.com/in/benpetersonIT
https://github.com/BenPetersonIT

#>

[CmdletBinding()]
Param(

    [string]$searchOU = $null,

    [int]$newest = 5

)

$domainInfo = Get-ADDomain
$errorLog = @()

if($searchOU -eq $null){

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