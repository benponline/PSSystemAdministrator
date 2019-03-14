<#

.NAME
GlanceADComputerError

.SYNOPSIS
This cmdlet gathers system errors in the last day from AD computers.

.SYNTAX
GetComputerError [-searchOU <string>] [-daysBack <int>]

.DESCRIPTION
This cmdlet gathers system errors from all AD computers. You can limit its 
scope to any top level OU in AD or the "Computers" container. By default it gathers
errors going back one day, but can be set to search as many days back as needed. 

.PARAMETERS
-searchOU <string>
	Specifies the top level OU the cmdlet will search.

	Required?                   False
	Default value               Active Directory
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
Requires "Printer and file sharing" and "Network Discovery" to be enabled on computers 
that are searched.

.EXAMPLE 1
GetComputerError

This cmdlet returns system errors from all AD computers from the last day.

.EXAMPLE 2
GetComputerError -searchOU “computers” -daysBack 2

This cmdlet returns system errors from all computers in the AD “Computers” CN from the last 2 days.

.EXAMPLE 3
GetComputerError -searchOU “Servers”

This cmdlet returns system errors from all computers in the AD “Servers” OU from the last day.

.RELATED LINKS
By Ben Peterson
linkedin.com/in/bpetersonmcts/
https://github.com/BenPetersonIT

#>

[CmdletBinding()]
Param(

    [string]$searchOU,
    #Contains OU in Active Directory to be searched.

    [int]$daysBack
    #Sets how many days back the script will look for errors.

)

#Variables

$domainInfo = Get-ADDomain
#Gathers domain info for searching AD.

$errorLog = @()
#Will contain all system errors.

#Main code

if($daysBack -eq ""){
#If $daysBack is left blank it is set to -1.
    
    $daysBack = -1

}else{

    $daysBack *= -1

}

if($searchOU -eq ""){
#If $searchOU is left blank it will gather all AD computers.

    $searchOU = "Active Directory"
    $computerSearch = ((Get-ADComputer -Filter *).name) | Sort-Object
    #If no parameter is passed to $searchOU the cmdlet it pulls from all AD computers.

}elseif($searchOU -eq "computers"){
#If $searchOU is set to "computers", then computers from the "Computer" container are gathered.

    $computerSearch = ((Get-ADComputer -Filter * -SearchBase "CN=$searchOU, $domaininfo").name) | 
        Sort-Object

}else{
#If a value is passed to $searchOU then it is used to gather computers from the OU that shares its
#name.

    $computerSearch = ((Get-ADComputer -Filter * -SearchBase "OU=$searchOU, $domaininfo").name) |
        Sort-Object

}

Foreach($computer in $computerSearch){

    if((Test-Connection $computer -Quiet) -eq $true){
    #Tests to see if the computer is online.

        $errorLog += Get-EventLog -ComputerName $computer -LogName System -EntryType Error -After ((Get-Date).AddDays($daysBack)) |
            Select-Object -Property @{n="Computer";e={$computer}},TimeWritten,EventID,InstanceID,Message
        #Adds the last 5 system errors to the error log.
        
    }else{
    #The computer is not online.
            
        $errorLog += New-Object –TypeName PSObject –Prop (@{`
            "Computer"="$computer";`
            "TimeWritten"="";`
            "EventID"="";`
            "InstanceID"="";`
            "Message"="Failed to connect"}) | 
            Select-Object -Property Computer,TimeWritten,EventID,InstanceID,Message
        #Places an entry in the error log showing computers that it cannot connect to.        

    }

}

$errorLog | Format-Table

return