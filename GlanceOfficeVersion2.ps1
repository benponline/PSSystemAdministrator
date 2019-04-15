[cmdletbinding()]
param(

    [string]$ComputerName = $env:COMPUTERNAME

)

Invoke-Command -ComputerName "$ComputerName" -ScriptBlock {
    Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\O365ProPlusRetail* |
    Select-Object DisplayName, DisplayVersion, Publisher }