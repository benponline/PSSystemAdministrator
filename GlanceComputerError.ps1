<#

.NAME
GlanceComputerError

.SYNOPSIS
This cmdlet gathers system errors from a computer.

.SYNTAX
GlanceComputerError [-ComputerName <string>] [-Newest <int>]

.DESCRIPTION
This cmdlet gathers system errors from a computer. By default it gathers them from the local 
computer. Computer and number of errors returned can be set by user.

.PARAMETERS
-ComputerName <string>
	Specifies the computer where the errors are returned from.

	Required?                   False
	Default value               $env:ComputerName
	Accept pipeline input?      False
	Accept wildcard characters? False

-Newest <int>
    Specifies the numbers of errors returned.

    Required?                   False
    Default value               5
    Accept pipeline input?      False
	Accept wildcard characters? False

.INPUTS
None. You cannot pipe input to this cmdlet.

.OUTPUTS
Returns PS objects for computer system errors with Computer, TimeWritten, EventID, InstanceId, 
and Message.

.NOTES
Requires "Printer and file sharing", "Network Discovery", and "Remote Registry" to be enabled on computers 
that are searched.

.EXAMPLE 1
GlanceComputerError

This cmdlet returns the last 5 system errors from localhost.

.EXAMPLE 2
GetComputerError -ComputerName Server -Newest 2

This cmdlet returns the last 2 system errors from server.

.RELATED LINKS
By Ben Peterson
linkedin.com/in/BenPetersonIT
https://github.com/BenPetersonIT

#>

[CmdletBinding()]
Param(

    [string]$ComputerName = $env:COMPUTERNAME,

    [int]$Newest = 5

)

$errors = Get-EventLog -ComputerName $ComputerName -LogName System -EntryType Error -Newest $Newest |
    Select-Object -Property @{n="ComputerName";e={$ComputerName}},TimeWritten,EventID,InstanceID,Message

$errors | Select-Object -Property ComputerName,TimeWritten,EventID,Instance,Message

return