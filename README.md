# PSSystemAdministrator
This module contains functions useful for administrating a Windows Active Directory domain. Many of the functions are designed to work with eachother. Functions that gather information on users or computers can be piped into functions that take an action. For instance, you can pipe a function that returns computers that have not logged onto the network for 30 days into a function that disables computer accounts. In a single line of code, you can disable all the inactive computers in active directory. There are a wide variety of functions that perform other tasks like sending magic packets for wake on lan, measuring directory and sub-directory sizes, gathering large files, and other tasks. Every function is fully documented and works with the Get-Help function. 

This module is written for PowerShell Core and tested with Windows 10 machines, but should be mostly compatible with PowerShell 5 and Windows 7. I am actively developing this module alongside my work as a system administrator. I use this module every day.

## Installation
1. Download the PSSystemAdministrator.psm1 file.
2. Open the PowerShell modules folder on your computer.
- For PowerShell Core it is located here: \Documents\PowerShell\Modules
- For PowerShell 5 it is located here: \Documents\WindowsPowerShell\Modules
3. Create a folder named “PSSystemAdministrator”.
4. Place the PSSystemAdministrator.psm1 file in the new folder.
5. Open your version of PowerShell and run the following command: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned`
6. This will allow PowerShell to read the contents of the module.
7. Open a new PowerShell session and you are good to go.
