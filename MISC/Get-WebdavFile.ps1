param (
    [string]$WebDAVUrl,
    [string]$RemoteFile,
    [string]$LocalFile,
    [PSCredential]$Credential
)

if (-not $WebDAVUrl -or -not $RemoteFile -or -not $LocalFile -or -not $Credential) {
    Write-Error "Missing required parameters. Use -WebDAVUrl, -RemoteFile, -LocalFile, -Credential."
    exit 1
}

# Encode credentials for Basic Auth
function Get-EncodedAuth {
    param ($Creds)
    $credPair = "$($Creds.UserName):$($Creds.GetNetworkCredential().Password)"
    return [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($credPair))
}

$headers = @{ Authorization = "Basic $(Get-EncodedAuth -Creds $Credential)" }

# Download the file
try {
    Invoke-WebRequest -Uri "$WebDAVUrl$RemoteFile" -Headers $headers -OutFile $LocalFile
    Write-Host "Download successful: $LocalFile" -ForegroundColor Green
} catch {
    Write-Error "Download failed: $_"
}
