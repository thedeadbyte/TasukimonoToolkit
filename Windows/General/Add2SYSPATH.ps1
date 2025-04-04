param([string]$folderPath)


[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$folderPath", [System.EnvironmentVariableTarget]::Machine)

write-output "$folderPath added to system path."

Start-Process -FilePath "powershell.exe"

exit



