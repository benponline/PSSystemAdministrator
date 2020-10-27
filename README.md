<h1>PSSystemAdministrator</h1>
This module contains functions useful for administrating a Windows Active Directory domain. Many of the functions are designed to work with eachother. Functions that gather information on users or computers can be piped into functions that take an action. For instance, you can pipe a function that returns computers that have not logged onto the network for 30 days into a function that disables computer accounts. In a single line of code, you can disable all the inactive computers in active directory. There are a wide variety of functions that perform other tasks like sending magic packets for wake on lan, measuring directory and sub-directory sizes, gathering large files, and other tasks.
<br>
Every function is fully documented and works with the Get-Help function. This module is written for PowerShell Core and tested with Windows 10 machines, but should be mostly compatible with PowerShell 5 and Windows 7. I am actively developing this module alongside my work as a system administrator. I use this module every day.
<br>
<br>
<h1>Installation</h1>
<ol>
  <li>Download the PSSystemAdministrator.psm1 file.</li>
  <li>Open the modules folder.</br>
  <ul>
    <li>For PowerShell Core it is located here: \Documents\PowerShell\Modules</li>
    <li>For PowerShell 5 it is located here: \Documents\WindowsPowerShell\Modules</li>
  </ul>
  </li>
  <li>Create a folder named “PSSystemAdministrator”.</li>
  <li>Place the PSSystemAdministrator.psm1 file in the new folder.</li>
  <li>Open your version of PowerShell and run the following command: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned</li>
  <li>This will allow PowerShell to read the contents of the module.</li>
  <li>Open a new PowerShell session and you are good to go.</li>
</ol>
