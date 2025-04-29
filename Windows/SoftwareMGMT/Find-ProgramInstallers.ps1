param (
    [string]$ScanPath = "C:\",
    [int]$MinSizeMB = 20,
    [string[]]$Extensions = @("*.exe", "*.msi"),
    [string]$ExportCSV = "",
    [string]$Keyword = "",
    [switch]$VerboseLog
)

function Convert-Size {
    param ([long]$Bytes)
    switch ($Bytes) {
        {$_ -ge 1TB} { return "{0:N2} TB" -f ($Bytes / 1TB) }
        {$_ -ge 1GB} { return "{0:N2} GB" -f ($Bytes / 1GB) }
        {$_ -ge 1MB} { return "{0:N2} MB" -f ($Bytes / 1MB) }
        {$_ -ge 1KB} { return "{0:N2} KB" -f ($Bytes / 1KB) }
        default     { return "$Bytes B" }
    }
}

Write-Host "Scanning $ScanPath for ${Extensions -join ', '} files > $MinSizeMB MB..." -ForegroundColor Cyan
if ($Keyword) { Write-Host "Filtering for keyword: '$Keyword'" -ForegroundColor Cyan }

$results = @()

try {
    $files = Get-ChildItem -Path $ScanPath -Include $Extensions -Recurse -ErrorAction SilentlyContinue

    foreach ($file in $files) {
        if ($file.Length -gt ($MinSizeMB * 1MB)) {
            if (-not $Keyword -or $file.FullName -like "*$Keyword*") {
                $entry = [PSCustomObject]@{
                    FullPath      = $file.FullName
                    Size          = Convert-Size $file.Length
                    SizeBytes     = $file.Length
                    Created       = $file.CreationTime
                    LastModified  = $file.LastWriteTime
                }
                $results += $entry
                if ($VerboseLog) { Write-Host "Matched: $($file.FullName)" -ForegroundColor Yellow }
            }
        }
    }

    $sorted = $results | Sort-Object SizeBytes -Descending

    if ($ExportCSV) {
        $sorted | Select-Object FullPath, Size, Created, LastModified |
            Export-Csv -Path $ExportCSV -NoTypeInformation -Encoding UTF8
        Write-Host "Exported to: $ExportCSV" -ForegroundColor Green
    } else {
        $sorted | Select-Object FullPath, Size, Created, LastModified | Format-Table -AutoSize
    }

} catch {
    Write-Host "Error during scan: $_" -ForegroundColor Red
}
