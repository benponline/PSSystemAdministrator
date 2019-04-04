<#

.NAME
GlanceOldADUser

.SYNOPSIS
Returns a list of all the users in AD that have not logged on for 6 months.

.SYNTAX
GlanceOldADUser

.DESCRIPTION
Returns a list of all the users in AD that have not been online for 6 months and the last date 
they were seen online.

.PARAMETERS
-monthsOld <int>

    Determines how long the computer account has to be inactive for it to be returned.

    Defaul Vaule                    6
    Required?                       False
    Accept pipeline input?          False
    Accept wildcard characters?     False

.INPUTS
None.

.OUTPUTS
List of user names and dates.

.NOTES
None.

.EXAMPLE 1
GlanceADOldUser

Lists all users in the domain that have not checked in for more than 6 months.

.EXAMPLE 2
GlanceADOldUser -monthsOld 2

Lists all users in the domain that have not checked in for more than 2 months.

.RELATED LINKS
By Ben Peterson
linkedin.com/in/benpetersonIT
https://github.com/BenPetersonIT

#>

[cmdletbinding()]
param(

    [int]$MonthsOld = 6

)

$lastLogonList = @()

$users = Get-ADUser -Filter * | Get-ADObject -Properties lastlogon | 
    Select-Object -Property lastlogon,name | Sort-Object -Property name

foreach($user in $users){

    if(([datetime]::fromfiletime($user.lastlogon)) -lt ((Get-Date).AddMonths($monthsOld * -1))){

        $lastLogonProperties = @{
            "Last Logon" = ([datetime]::fromfiletime($user.lastlogon));
            "User" = ($user.name)
        }

        $lastLogonObject = New-Object -TypeName PSObject -Property $lastLogonProperties
    
        $lastLogonList += $lastLogonObject
    
    }

}

$lastLogonList

return