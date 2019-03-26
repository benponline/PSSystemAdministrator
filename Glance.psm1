<#

    Glance Module

#>

function GlanceADComputerError{

    [CmdletBinding()]
    Param(
    
        [string]$searchOU = "",
        #Contains OU in Active Directory to be searched.
    
        [int]$daysBack = 1
        #Sets how many days back the script will look for errors.
    
    )
    
    #Variables
    
    $domainInfo = Get-ADDomain
    $errorLog = @()
    
    #Main code
    
    if($searchOU -eq ""){
    #If $searchOU is left blank it will gather all AD computers.
    
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
    
            $errorLog += Get-EventLog -ComputerName $computer -LogName System -EntryType Error -After (Get-Date).AddDays(($daysBack *= -1)) | 
                Select-Object -Property @{n="Computer";e={$computer}},TimeWritten,EventID,InstanceID,Message
            
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
    
    $errorLog
    
    return 

}