<#

.NAME
GlancePingLog

.SYNOPSIS
Pings a target URL, IP address, or network host name over time and returns the results.

.SYNTAX
TestConnectivity -Target <String> -Minutes <Int>

.DESCRIPTION
Pings a target URL or IP address over time and returns the results in a table. A ping is
sent out once a minute for the legth of time, in minutes, set by the user.

.PARAMETERS
-Target <String>
	Specifies the target URL or IP address that will be pinged.

    Required?                    Yes
    Accept pipeline?             False
    Accept wildcard charactors?  False

-Minutes <Int>
	Specifies the number of hours that the cmdlet will monitor the pingTarget.

    Required?                    Yes
    Accept pipeline?             False
    Accept wildcard charactors?  False

.INPUTS
None. You cannot pipe input to this cmdlet.

.OUTPUTS
Writes a table with the result of each ping to the screen. Information includes target, 
status, response time, hour, minute, month, day, and year.

.EXAMPLE 1
Record pings from a URL for 10 minutes.
GetPingLog -Target “www.website.com” -Minutes 10
    
.EXAMPLE 2
Record pings from an IP address for 5 minutes. 
GetPingLog -Target "8.8.8.8" -Minutes 5

.EXAMPLE 3
Record pings from a host name for 10 minutes.
GetPingLog -Target "computername" -Minutes 10

.RELATED LINKS
By Ben Peterson
linkedin.com/in/bpetersonmcts/
https://github.com/BenPetersonIT

Credits:
http://www.happysysadm.com/2017/02/from-test-connection-to-one-line-long.html

#>

[CmdletBinding()]
Param(
    
    [Parameter(Mandatory=$True)]
    [string]$Target,
    #Contains variable to desired target URL, IP address, or host name.

    [Parameter(Mandatory=$True)]
    [int]$Minutes
    #Length of time in minutes cmdlt will run.

)

#Variables

$pingObject = New-Object System.Net.NetworkInformation.Ping
#Creates the object that pings the $Target.

$pingRecord = @()
#Record of all pings; successful and not.

$startTime = Get-Date
#Start time of script. Used to measure how long the it should run.

$minuteTicker = Get-Date
#Incrimented up a minute after every ping. Prevents the cmdlt from pinging the target
#more than once a minute.

#Functions

function CreatePingObject{
#Creates an object out of the information from a ping that returns information.

    $pingResults = New-Object -TypeName psobject -Property @{`
        "Status"=$targetPing.Status;`
        "Target"=$targetPing.Address;`
        "Time"=(Get-Date -Format g);`
        "ResponseTime"=$targetPing.RoundtripTime}

    $pingResults

    return

}

function CreateFailedPingObject{
#Creates an object with information about a ping that does not return information.

    $pingResults = New-Object -TypeName psobject -Property @{`
        "Status"="Failure";`
        "Target"=$Target;`
        "Time"=(Get-Date -Format g);`
        "ResponseTime"= 0}

    
    $pingResults

    return

}

#Main code

While(((Get-Date) -le $startTime.AddMinutes($Minutes))){
#Runs for the number of minutes stored in $Minutes.
    
    if((Get-Date) -ge $minuteTicker){
        
        Try{

            $targetPing = $pingObject.Send($Target)

            if(($targetPing.Status) -eq "Success"){
            #Ping found target.
            
                $pingRecord += CreatePingObject
                                        
            }else{
            #Ping to target timed out.
            
                $pingRecord += CreatePingObject
            }
        }catch{
        #Ping could not find target.

            $pingRecord += CreateFailedPingObject

        }

        $minuteTicker = $minuteTicker.AddMinutes(1)
        
    }

}

$pingRecord

Return