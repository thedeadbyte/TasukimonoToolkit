
<#PSScriptInfo

.VERSION 1.0.0

.GUID 5f005950-ef04-495d-9b93-9e791f91d222

.AUTHOR kalichuza

.COMPANYNAME

.COPYRIGHT

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#>

<# 

.DESCRIPTION 
 Queries the Registry for uninstallers, lists them, then allows for uninstall via index number. A no frills, quick tool 

#> 
# Get list of installed applications from the registry
$uninstallKeys = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$apps = foreach ($keyPath in $uninstallKeys) {
    Get-ItemProperty $keyPath | Where-Object { $_.DisplayName -and $_.UninstallString } |
    Select-Object DisplayName, UninstallString
}

# Display the list of applications
if ($apps.Count -eq 0) {
    Write-Host "No applications found with uninstall commands."
    exit
}

Write-Host "Applications with available uninstallers:"
for ($i = 0; $i -lt $apps.Count; $i++) {
    Write-Host "[$i] $($apps[$i].DisplayName)"
}

# Prompt the user to select an application
$selection = Read-Host "Enter the index number of the application to uninstall"

if ($selection -match '^\d+$' -and [int]$selection -ge 0 -and [int]$selection -lt $apps.Count) {
    $selectedApp = $apps[$selection]
    Write-Host "Uninstalling: $($selectedApp.DisplayName)"
    
    # Execute the uninstall command
    $uninstallCommand = $selectedApp.UninstallString

    if ($uninstallCommand -match '^MsiExec.exe /I') {
        $uninstallCommand = $uninstallCommand -replace '/I', '/X'  # Change install to uninstall for MSI packages
    }

    Start-Process cmd -ArgumentList "/c $uninstallCommand" -NoNewWindow -Wait
} else {
    Write-Host "Invalid selection. Exiting."
}



