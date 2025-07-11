<#PSScriptInfo

.VERSION 1.0

.GUID b58802e6-1a72-4140-8c8c-b6261e78c657

.AUTHOR Kalichuza

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

.DESCRIPTION
Pulls executables that are available to run in the command line.

#>
<#


.SYNOPSIS
  List files in your PATH, filtering by extension if you pass any.

.PARAMETER Extensions
  One or more extensions (without the dot) to filter by.
  Default is exe, cmd, bat, com, ps1 (i.e. all common executables).

.EXAMPLE
  # Default: list all .exe, .cmd, .bat, .com & .ps1 on your PATH
  .\List-PathExecutables.ps1

.EXAMPLE
  # Only list .exe and .dll
  .\List-PathExecutables.ps1 -Extensions exe,dll
#>

param(
    [string[]]$Extensions = @('exe','cmd','bat','com','ps1')
)

# normalize to “.ext” form
$exts = $Extensions | ForEach-Object {
    $e = $_.TrimStart('.').ToLower()
    ".$e"
}

# grab existing PATH dirs
$dirs = $env:PATH -split ';' | Where-Object { Test-Path $_ }

# collect matching files as real PSObjects
$items = foreach ($dir in $dirs) {
    try {
        Get-ChildItem -Path $dir -File -ErrorAction Stop |
          Where-Object { $exts -contains $_.Extension.ToLower() }
    } catch { }
}

# output unique, sorted objects
$items |
  Sort-Object Name -Unique |
  Select-Object Name, FullName