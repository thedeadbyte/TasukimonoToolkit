
<#PSScriptInfo

.VERSION 1.0.1

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

Write-Host "`nInstalled Applications:`n"
for ($i = 0; $i -lt $apps.Count; $i++) {
    Write-Host "[$i] $($apps[$i].DisplayName)"
}

# Prompt the user to select an application
$selection = Read-Host "Enter the index number of the application to uninstall"

if ($selection -match '^\d+$' -and [int]$selection -ge 0 -and [int]$selection -lt $apps.Count) {
    $selectedApp = $apps[$selection]
    Write-Host "`nAttempting to silently uninstall: $($selectedApp.DisplayName)`n"

    # Extract uninstall command
    $uninstallCommand = $selectedApp.UninstallString

    # Modify command to enforce silent uninstallation
    if ($uninstallCommand -match '^MsiExec.exe /I') {
        $uninstallCommand = $uninstallCommand -replace '/I', '/X'  # Convert install command to uninstall
        $uninstallCommand += " /quiet /norestart"  # Ensure silent operation
    } elseif ($uninstallCommand -match 'MsiExec.exe') {
        $uninstallCommand += " /quiet /norestart"
    } elseif ($uninstallCommand -match '\.exe') {
        # Try common silent switches
        $uninstallCommand += " /quiet /silent /qn /norestart"
    }

    # Execute uninstall command
    Write-Host "Executing: $uninstallCommand"
    Start-Process cmd -ArgumentList "/c $uninstallCommand" -NoNewWindow -Wait
    Write-Host "`nUninstallation process initiated.`n"

} else {
    Write-Host "`nInvalid selection. Exiting.`n"
}



