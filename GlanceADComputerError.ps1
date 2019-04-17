<#

.NAME
GlanceADComputerError

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
GlanceADComputerError -searchOU “computers” -newest 2

This cmdlet returns the 2 newest system errors from all computers in the “Computers” CN.

.EXAMPLE 3
GlanceADComputerError -searchOU “Servers”

This cmdlet returns the 5 newest system errors from computers in the AD “Servers” OU.

.RELATED LINKS
By Ben Peterson
linkedin.com/in/BenPetersonIT
https://github.com/BenPetersonIT

#>

[CmdletBinding()]
Param(

    [string]$SearchOU,

    [int]$Newest = 5

)

$domainInfo = Get-ADDomain
$errorLog = @()

#Gathers a list of computers based on what is passed to the SearchOU parameter.
if($searchOU -eq ""){

    $computerSearch = ((Get-ADComputer -Filter *).name) | Sort-Object

}elseif($searchOU -eq "computers"){

    $computerSearch = ((Get-ADComputer -Filter * -SearchBase "CN=$searchOU, $domainInfo").name) | 
        Sort-Object

}else{

    $computerSearch = ((Get-ADComputer -Filter * -SearchBase "OU=$searchOU, $domainInfo").name) |
        Sort-Object

}

#Gathers the system errors from the list of computers created above.
Foreach($computer in $computerSearch){

    if((Test-Connection $computer -Quiet) -eq $true){

        try{

            $errorLog += Get-EventLog -ComputerName $computer -LogName System -EntryType Error -Newest $newest | 
                Select-Object -Property @{n="Computer";e={$computer}},TimeWritten,EventID,InstanceID,Message
        
        }catch{}

    }
    
}

#Returns the array of errors to the console.
$errorLog | Select-Object -Property Computer,TimeWritten,EventID,InstanceID,Message

return