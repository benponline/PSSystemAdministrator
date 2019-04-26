<#

.NAME
GlancePingLog

.SYNOPSIS
Pings a target URL, IP address, or network host name over time and returns the results.

.SYNTAX
GlancePingLog -Target <String> -Minutes <Int>

.DESCRIPTION
Pings a target URL or IP address over time and returns the results. A ping is sent out once a 
minute for the legth of time, in minutes, set by the user.

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
Returns PS objects with the result of each ping to the screen. Information includes target, status, 
response time, hour, minute, month, day, and year.

.EXAMPLE 1
GlancePingLog -Target “www.website.com” -Minutes 10

Records pings from a URL for 10 minutes.

.EXAMPLE 2
GetPingLog -Target "8.8.8.8" -Minutes 5

Records pings from an IP address for 5 minutes. 

.EXAMPLE 3
GlancePingLog -Target "computername" -Minutes 10

Record pings from a host name for 10 minutes.

.RELATED LINKS
By Ben Peterson
linkedin.com/in/benpetersonIT/
https://github.com/BenPetersonIT

Credits:
http://www.happysysadm.com/2017/02/from-test-connection-to-one-line-long.html

#>

[CmdletBinding()]
Param(
    
    [Parameter(Mandatory=$True)]
    [string]$Target,
    
    [Parameter(Mandatory=$True)]
    [int]$Minutes

)

$pingObject = New-Object System.Net.NetworkInformation.Ping

$pingRecord = @()

$startTime = Get-Date

$minuteTicker = Get-Date

function CreatePingObject{

    $pingResults = New-Object -TypeName psobject -Property @{`
        "Status"=$targetPing.Status;`
        "Target"=$Target;`
        "Time"=(Get-Date -Format g);`
        "ResponseTime"=$targetPing.RoundtripTime}

    $pingResults

    return

}

function CreateFailedPingObject{

    $pingResults = New-Object -TypeName psobject -Property @{`
        "Status"="Failure";`
        "Target"=$Target;`
        "Time"=(Get-Date -Format g);`
        "ResponseTime"= 0}

    
    $pingResults

    return

}

While(((Get-Date) -le $startTime.AddMinutes($Minutes))){
    
    if((Get-Date) -ge $minuteTicker){
        
        Try{

            $targetPing = $pingObject.Send($Target)

            if(($targetPing.Status) -eq "Success"){
            
                $pingRecord += CreatePingObject
                                        
            }else{
            
                $pingRecord += CreatePingObject
            }
        }catch{

            $pingRecord += CreateFailedPingObject

        }

        $minuteTicker = $minuteTicker.AddMinutes(1)
        
    }

}

$pingRecord | Select-Object -Property status,target,time,ResponseTime

Return