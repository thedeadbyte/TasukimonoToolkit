<#
.SYNOPSIS
    This script checks if the RSAT Active Directory module is installed and installs it if it is not.
#>

# Check to see if the module is installed
$moduleInstalled = Get-WindowsCapability -Name RSAT.ActiveDirectory* -Online | Select-Object -Property Name,State

# Display the current state of the module
Write-Host "Module State: " $moduleInstalled

# Install the module if it is not installed
if ($moduleInstalled.State -eq "NotPresent") {
    Write-Host $moduleInstalled.Name "is not installed, installing it now..."
    Add-WindowsCapability -Online -Name $moduleInstalled.Name
    Write-Host "Done!"
} else {
    Write-Host $moduleInstalled.Name "is already installed!"
}
