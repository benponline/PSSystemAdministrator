<#

.NAME
GlanceOldADUsers

.SYNOPSIS
Returns a list of all the users in AD that have not been online for 6 months.

.SYNTAX
GetADUserOldLogon

.DESCRIPTION
Returns a list of all the users in AD that have not been online for 6 months and the last date 
they were seen online.

.PARAMETERS
None.

.INPUTS
None.

.OUTPUTS
List of user names and dates.

.NOTES
None.

.EXAMPLE 1
GetADUserOldLogon

Returns a list of all the users in AD that have not been online for 6 months.

.RELATED LINKS
By Ben Peterson
linkedin.com/in/bpetersonmcts/
https://github.com/BenPetersonIT

#>

$lastLogonList = @()

$users = Get-ADUser -Filter * | Get-ADObject -Properties lastlogon | 
Select-Object -Property lastlogon,name | Sort-Object -Property name

foreach($user in $users){

    if(([datetime]::fromfiletime($user.lastlogon)) -lt ((Get-Date).AddMonths(-6))){

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