param (
    [string]$subnet = "192.168.250",
    [int]$start = 1,
    [int]$end = 254,
    [int]$rdpPort = 3389
)

# Function to test RDP port on a single IP
function Test-RDPPort {
    param (
        [string]$IPAddress,
        [int]$Port = $rdpPort
    )

    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $asyncResult = $tcpClient.BeginConnect($IPAddress, $Port, $null, $null)
        $waitHandle = $asyncResult.AsyncWaitHandle
        if ($waitHandle.WaitOne(3000, $false)) {  # 3 second timeout
            $tcpClient.EndConnect($asyncResult)
            $tcpClient.Close()
            return $true
        } else {
            $tcpClient.Close()
            return $false
        }
    } catch {
        return $false
    }
}

# Scan the whole range
foreach ($i in $start..$end) {
    $ip = "$subnet.$i"
    if (Test-RDPPort -IPAddress $ip) {
        Write-Host "RDP is OPEN on $ip" -ForegroundColor Green
    } else {
        Write-Host "RDP is CLOSED on $ip" -ForegroundColor Red
    }
} 
