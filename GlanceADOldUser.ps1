<#

.NAME
GlanceOldADUser

.SYNOPSIS
This cmdlet returns a list of all the users in AD that have not logged on for an amount of months.

.SYNTAX
GlanceOldADUser

.DESCRIPTION
Returns a list of all the users in AD that have not been online a number of months. The default
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
Array of PS objects with user names and last logon date.

.NOTES
None.

.EXAMPLE 1
GlanceADOldUser

Lists all users in the domain that have not checked in for more than 6 months.

.EXAMPLE 2
GlanceADOldUser -MonthsOld 2

Lists all users in the domain that have not checked in for more than 2 months.

.RELATED LINKS
By Ben Peterson
linkedin.com/in/BenPetersonIT
https://github.com/BenPetersonIT

#>

[cmdletbinding()]
param(

    [int]$MonthsOld = 6

)

$lastLogonList = @()

#Creates a list with all AD users.
$users = Get-ADUser -Filter * | Get-ADObject -Properties lastlogon | 
    Select-Object -Property lastlogon,name | Sort-Object -Property name

#Adds users that have not been online for the amount of months in MonthsOld.
foreach($user in $users){

    if(([datetime]::fromfiletime($user.lastlogon)) -lt ((Get-Date).AddMonths($monthsOld * -1))){

        $lastLogonProperties = @{
            "LastLogon" = ([datetime]::fromfiletime($user.lastlogon));
            "User" = ($user.name)
        }

        $lastLogonObject = New-Object -TypeName PSObject -Property $lastLogonProperties
    
        $lastLogonList += $lastLogonObject
    
    }

}

#Returns an array of PS objects with user name and last logon dates.
$lastLogonList | Select-Object -Property User,LastLogon

return