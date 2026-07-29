<#PSScriptInfo
.VERSION 2.0
.GUID 1284b8ef-dc3d-44ba-a2af-0e40879e6781
.AUTHOR Kalichuza
.RELEASENOTES
2.0 - Fix zombie-state after tenant migration:
      * Registry-based product-code lookup (no Win32_Product)
      * Scrub orphaned Installer\Products + UserData packed-GUID keys
      * Kill watchdog/patcher before service delete
      * Remove njfile.bin identity + surface ThreatLocker/locked-path failures
#>
param (
    [switch]$DelTeamViewer = $false,
    [switch]$Cleanup,
    [switch]$Uninstall,
    [switch]$ShowError
)
 
$ErrorActionPreference = if ($ShowError) { 'Continue' } else { 'SilentlyContinue' }
$failures = @()
 
Write-Progress -Activity "Running Ninja Removal Script" -PercentComplete 0
 
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
$ninjaDir     = [string]::Empty
$ninjaDataDir = Join-Path $env:ProgramData -ChildPath "NinjaRMMAgent"
 
# --- Locate install dir: registry first, then service path ---
$ninjaDirRegLocation = Get-ItemPropertyValue -Path $ninjaSoftKey -Name Location -ErrorAction SilentlyContinue
if ($ninjaDirRegLocation -and (Test-Path (Join-Path $ninjaDirRegLocation "NinjaRMMAgent.exe"))) {
    $ninjaDir = $ninjaDirRegLocation
}
if (-not $ninjaDir) {
    $servicePath = (Get-CimInstance -ClassName Win32_Service -Filter "Name = 'NinjaRMMAgent'").PathName
    if ($servicePath) {
        $ninjaDirService = ($servicePath | Split-Path).Replace('"', '')
        if (Test-Path (Join-Path $ninjaDirService "NinjaRMMAgentPatcher.exe")) {
            $ninjaDir = $ninjaDirService
        }
    }
}
 
# --- Find MSI ProductCode WITHOUT Win32_Product (registry scan) ---
function Get-NinjaProductCode {
    $roots = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
    )
    foreach ($root in $roots) {
        Get-ChildItem $root -ErrorAction SilentlyContinue | ForEach-Object {
            $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
            if ($p.DisplayName -like 'NinjaRMMAgent*') { $_.PSChildName }
        }
    }
}
 
if ($Uninstall) {
    if ($ninjaDir -and (Test-Path "$ninjaDir\NinjaRMMAgent.exe")) {
        Start-Process -FilePath "$ninjaDir\NinjaRMMAgent.exe" `
            -ArgumentList "-disableUninstallPrevention", "NOUI" -Wait
    }
    $productCodes = @(Get-NinjaProductCode)
    if ($productCodes.Count -eq 0) {
        $failures += "No ARP ProductCode found - MSI uninstall skipped (may already be gone or ARP orphaned)."
    }
    foreach ($code in $productCodes) {
        Start-Process -FilePath "msiexec.exe" `
            -ArgumentList "/x", $code, "/quiet", "/norestart" -Wait
    }
}
 
if ($Cleanup) {
    # Kill watchdog/patcher/agent processes BEFORE touching the service
    foreach ($proc in 'NinjaRMMAgentPatcher','NinjaRMMAgent','NinjaRMMProxyProcess64','ninjarmm-cli') {
        Get-Process -Name $proc -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }
 
    $service = Get-Service -Name "NinjaRMMAgent" -ErrorAction SilentlyContinue
    if ($service) {
        Stop-Service -Name "NinjaRMMAgent" -Force -ErrorAction SilentlyContinue
        & sc.exe DELETE "NinjaRMMAgent" | Out-Null
    }
 
    # Delete folders; report failures (ThreatLocker Storage Control / locked files)
    foreach ($path in @($ninjaDir, $ninjaDataDir)) {
        if ($path -and (Test-Path $path)) {
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            if (Test-Path $path) {
                $failures += "Could not delete '$path' - check ThreatLocker Storage Control / tamper protection / open handles."
            }
        }
    }
 
    # Standard Ninja keys + ARP + EXEMSI wrapper
    foreach ($keyPath in @($ninjaPreSoftKey, $uninstallKey, $exetomsiKey)) {
        if (Test-Path $keyPath) { Remove-Item -Path $keyPath -Recurse -Force -ErrorAction SilentlyContinue }
    }
 
    # --- Scrub orphaned Windows Installer registration (the real "still installed" cause) ---
    $codes = @(Get-NinjaProductCode)
    foreach ($code in $codes) {
        # ARP entry per code
        foreach ($u in @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$code",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$code"
        )) { if (Test-Path $u) { Remove-Item $u -Recurse -Force -ErrorAction SilentlyContinue } }
    }
 
    # Packed-GUID entries in Installer\Products + UserData (match by ProductName)
    $installerRoots = @(
        'HKLM:\SOFTWARE\Classes\Installer\Products',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products'
    )
    foreach ($root in $installerRoots) {
        Get-ChildItem $root -ErrorAction SilentlyContinue | ForEach-Object {
            $props = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
            if ($props.ProductName -like 'NinjaRMMAgent*') {
                Remove-Item $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
 
if ($DelTeamViewer) {
    Get-Process -Name "teamviewer*" -ErrorAction SilentlyContinue | Stop-Process -Force
    foreach ($path in @("${env:ProgramFiles(x86)}\TeamViewer\uninstall.exe","${env:ProgramFiles}\TeamViewer\uninstall.exe")) {
        if (Test-Path $path) { Start-Process -FilePath $path -ArgumentList "/S" -Wait }
    }
    Remove-Item -Path "HKLM:\SOFTWARE\TeamViewer" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "HKLM:\SOFTWARE\WOW6432Node\TeamViewer" -Recurse -Force -ErrorAction SilentlyContinue
}
 
# --- Report ---
if ($failures.Count) {
    Write-Warning "Removal completed WITH ISSUES:"
    $failures | ForEach-Object { Write-Warning "  - $_" }
} else {
    Write-Host "Ninja removal completed. Verify: service gone, '$ninjaDataDir' gone, no NinjaRMMAgent ARP entry."
}
 
$error | Out-File -FilePath "C:\Windows\Temp\NinjaRemovalScriptError.txt"
