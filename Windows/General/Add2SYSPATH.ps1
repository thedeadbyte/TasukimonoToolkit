param (



$folderPath = "C:\Program Files\Restic"
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$resticPath", [System.EnvironmentVariableTarget]::Machine)
