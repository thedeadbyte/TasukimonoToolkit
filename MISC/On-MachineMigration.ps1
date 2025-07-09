<#
.\On-MachineMigration.ps1 -Uninstall -Cleanup -ReinstallUri "<Ninja MSI URL>"
#>

param (
    [Parameter(Mandatory = $false)]
    [switch]$DelTeamViewer = $false,
    [Parameter(Mandatory = $false)]
    [switch]$Cleanup,
    [Parameter(Mandatory = $false)]
    [switch]$Uninstall,
    [Parameter(Mandatory = $true)]
    [string]$ReinstallUri,
    [Parameter(Mandatory = $false)]
    [switch]$ShowError
)

# Ensure admin
$CurrentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
if (!($CurrentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator))) {
    Write-Output 'Restarting as admin...'
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -DelTeamViewer:$DelTeamViewer -Cleanup:$Cleanup -Uninstall:$Uninstall -ReinstallUri `"$ReinstallUri`" -ShowError:$ShowError" -Verb RunAs
    exit
}

$ErrorActionPreference = if ($ShowError) { 'Continue' } else { 'SilentlyContinue' }

Write-Progress -Activity "Running Ninja Removal Script" -PercentComplete 0

# Registry paths
if ([System.Environment]::Is64BitOperatingSystem) {
    $ninjaPreSoftKey = 'HKLM:\SOFTWARE\WOW6432Node\NinjaRMM LLC'
    $uninstallKey    = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    $exetomsiKey     = 'HKLM:\SOFTWARE\WOW6432Node\EXEMSI.COM\MSI Wrapper\Installed'
} else {
    $ninjaPreSoftKey = 'HKLM:\SOFTWARE\NinjaRMM LLC'
    $uninstallKey    = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    $exetomsiKey     = 'HKLM:\SOFTWARE\EXEMSI.COM\MSI Wrapper\Installed'
}

$ninjaSoftKey = Join-Path $ninjaPreSoftKey -ChildPath 'NinjaRMMAgent'
$ninjaDataDir = Join-Path -Path $env:ProgramData -ChildPath "NinjaRMMAgent"
$ninjaDir     = ''

# Try registry first
$ninjaDirRegLocation = Get-ItemPropertyValue -Path $ninjaSoftKey -Name Location -ErrorAction SilentlyContinue
if ($ninjaDirRegLocation -and (Test-Path "$ninjaDirRegLocation\NinjaRMMAgent.exe")) {
    $ninjaDir = $ninjaDirRegLocation
}

# Fallback to service path
if (-not $ninjaDir) {
    $servicePath = (Get-WmiObject -Class win32_service -Filter "Name = 'NinjaRMMAgent'").PathName
    if ($servicePath) {
        $ninjaDirService = ($servicePath | Split-Path).Replace('"', '')
        if (Test-Path "$ninjaDirService\NinjaRMMAgentPatcher.exe") {
            $ninjaDir = $ninjaDirService
        }
    }
}

# Uninstall Ninja
if ($Uninstall) {
    Start-Process -FilePath "$ninjaDir\NinjaRMMAgent.exe" -ArgumentList "-disableUninstallPrevention", "NOUI" -Wait
    $productID = (Get-WmiObject -Class Win32_Product -Filter "Name = 'NinjaRMMAgent'").IdentifyingNumber
    if ($productID) {
        Start-Process -FilePath "msiexec.exe" -ArgumentList "/x $productID /quiet /norestart" -Wait
    }
}

# Cleanup files and registry
if ($Cleanup) {
    $service = Get-Service -Name "NinjaRMMAgent" -ErrorAction SilentlyContinue
    if ($service) {
        Stop-Service -Name $service -Force
        sc.exe DELETE $service
    }

    foreach ($path in @($ninjaDir, $ninjaDataDir)) {
        if (Test-Path $path) {
            Remove-Item -Path $path -Recurse -Force
        }
    }

    foreach ($keyPath in @($ninjaPreSoftKey, $uninstallKey, $exetomsiKey)) {
        if (Test-Path $keyPath) {
            Remove-Item -Path $keyPath -Recurse -Force
        }
    }
}

# Remove TeamViewer
if ($DelTeamViewer) {
    Get-Process -Name "teamviewer*" -ErrorAction SilentlyContinue | Stop-Process -Force
    $teamViewerPaths = @("${env:ProgramFiles(x86)}\TeamViewer\uninstall.exe", "${env:ProgramFiles}\TeamViewer\uninstall.exe")
    foreach ($path in $teamViewerPaths) {
        if (Test-Path $path) {
            Start-Process -FilePath $path -ArgumentList "/S" -Wait
        }
    }
    Remove-Item -Path "HKLM:\SOFTWARE\TeamViewer" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\SOFTWARE\WOW6432Node\TeamViewer" -Recurse -Force -ErrorAction SilentlyContinue
}

# Download MSI
$MsiDest = "C:\ProgramData\ninjaone.msi"
try {
    Write-Output "Downloading MSI from $ReinstallUri..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Tls12,Tls13'
    (New-Object Net.WebClient).DownloadFile($ReinstallUri, $MsiDest)
} catch {
    Write-Error "Failed to download MSI: $_"
    exit 1
}

# Write reinstall script with proper quoting
$InstallScriptPath = "$env:TEMP\NinjaReinstall.ps1"
$InstallScriptContent = @'
Start-Transcript "$env:TEMP\NinjaReinstallLog.txt"

$msi = "C:\ProgramData\ninjaone.msi"
$args = "/i `"$msi`" /qn /norestart"

Start-Process msiexec.exe -ArgumentList $args -Wait

"NinjaOne Agent installed successfully at $(Get-Date)" | Out-File -Append "$env:TEMP\NinjaReinstallStatus.txt"

Stop-Transcript
'@

Set-Content -Path $InstallScriptPath -Value $InstallScriptContent -Force

# Register scheduled task
$TaskName = "ReinstallNinjaOne"
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

$Action    = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$InstallScriptPath`""
$Trigger   = New-ScheduledTaskTrigger -Once -At ((Get-Date).AddMinutes(1))
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Principal $Principal

Write-Output "Scheduled Ninja reinstall in 1 minute."

# Optional error logging
if ($ShowError) {
    $error | Out-File -FilePath "$env:TEMP\NinjaRemovalScriptError.txt"
}
