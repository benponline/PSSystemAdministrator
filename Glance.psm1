<#

    Glance Module

#>

function GlanceADComputerError{

    [CmdletBinding()]
    Param(
    
        [string]$searchOU,
    
        [int]$newest = 5
    
    )
    
    $domainInfo = Get-ADDomain
    $errorLog = @()
    
    if($searchOU -eq ""){
    
        $computerSearch = ((Get-ADComputer -Filter *).name) | Sort-Object
    
    }elseif($searchOU -eq "computers"){
    
        $computerSearch = ((Get-ADComputer -Filter * -SearchBase "CN=$searchOU, $domainInfo").name) | 
            Sort-Object
    
    }else{
    
        $computerSearch = ((Get-ADComputer -Filter * -SearchBase "OU=$searchOU, $domainInfo").name) |
            Sort-Object
    
    }
    
    Foreach($computer in $computerSearch){
    
        if((Test-Connection $computer -Quiet) -eq $true){
    
            try{
    
                $errorLog += Get-EventLog -ComputerName $computer -LogName System -EntryType Error -Newest $newest | 
                    Select-Object -Property @{n="Computer";e={$computer}},TimeWritten,EventID,InstanceID,Message
            
            }catch{}
    
        }
        
    }
    
    $errorLog
    
    return 

}