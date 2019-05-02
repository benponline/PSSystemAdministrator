<#

.NAME
GlanceADOldComputer

.SYNOPSIS
This cmdlet returns a list of all the computers in AD that have not been online for a specific 
amount of time.

.SYNTAX
GlanceADOldComputer [-MonthsOld <int>]

.DESCRIPTION
Returns a list of all the computers in AD that have not been online a number of months. The default
amount of months is 6. Can be set by the user by passing a value to MonthsOld.

.PARAMETERS
-MonthsOld <int>
    Determines how long the computer account has to be inactive for it to be returned.

    Defaul Vaule                    6
    Required?                       False
    Accept pipeline input?          False
    Accept wildcard characters?     False

.INPUTS
None.

.OUTPUTS
Array of PS objects with information including computer names and the date it last connected to the
domain.

.NOTES
None.

.EXAMPLE 1
GlanceADOldComputer

Lists all computers in the domain that have not checked in for more than 6 months.

.EXAMPLE 2
GlanceADOldComputer -MonthsOld 2

Lists all computers in the domain that have not checked in for more than 2 months.

.RELATED LINKS

By Ben Peterson
linkedin.com/in/benpetersonIT
https://github.com/BenPetersonIT

#>

[CmdletBinding()]
Param(

    [int]$MonthsOld = 3

)

$lastLogonList = @()

$computers = Get-ADComputer -Filter * | Get-ADObject -Properties lastlogon | Select-Object -Property name,lastlogon | 
    Sort-Object -Property name

foreach($computer in $computers){

    if(([datetime]::fromfiletime($computer.lastlogon)) -lt ((Get-Date).AddMonths(($monthsOld * -1)))){

        $lastLogonProperties = @{
            "Last Logon" = ([datetime]::fromfiletime($computer.lastlogon));
            "Computer" = ($computer.name)
        }

        $lastLogonObject = New-Object -TypeName PSObject -Property $lastLogonProperties
    
        $lastLogonList += $lastLogonObject
    
    }

}

$lastLogonList

return