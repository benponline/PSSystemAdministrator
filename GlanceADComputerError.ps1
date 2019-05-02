<#

.NAME
GlanceADComputerError

.SYNOPSIS
This cmdlet gathers system errors from AD computers.

.SYNTAX
GlanceADComputerError [-searchOU <string>] [-newest <int>]

.DESCRIPTION
This cmdlet gathers system errors from all AD computers.  

.PARAMETERS
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
GlanceADComputerError -newest 2

This cmdlet returns the 2 newest system errors from all AD computers.

.RELATED LINKS
By Ben Peterson
linkedin.com/in/BenPetersonIT
https://github.com/BenPetersonIT

#>

[CmdletBinding()]
Param(

    [int]$Newest = 5

)

$ErrorActionPreference = "Stop"

$errorLog = @()

$computerSearch = ((Get-ADComputer -Filter *).name) | Sort-Object -Property Name

Foreach($computer in $computerSearch){

    if(Test-Connection $computer -Quiet){

        try{

            $errorLog += Get-EventLog -ComputerName $computer -LogName System -EntryType Error -Newest $newest | 
                Select-Object -Property @{n="Computer";e={$computer}},TimeWritten,EventID,InstanceID,Message
        
        }catch{}

    }
    
}

$errorLog | Select-Object -Property Computer,TimeWritten,EventID,InstanceID,Message

return