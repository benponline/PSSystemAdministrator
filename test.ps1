Get-ADUser ben -Server gamlsdc1 | 
    Get-ADObject -Properties LastLogon | 
    Select-Object -Property @{n="SamAccountName";e={"michael"}},@{n="LastLogon";e={([datetime]::fromfiletime($_.LastLogon))}}

Get-ADUser ben -Server gamlsdc2 | 
    Get-ADObject -Properties LastLogon | 
    Select-Object -Property @{n="SamAccountName";e={"michael"}},@{n="LastLogon";e={([datetime]::fromfiletime($_.LastLogon))}}