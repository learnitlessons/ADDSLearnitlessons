# Save as Start-CPULoad.ps1

function Start-CPULoad {
    param([int]$DurationSeconds = 30)
    
    Write-Host "Starting CPU load for $DurationSeconds seconds..."
    $endTime = (Get-Date).AddSeconds($DurationSeconds)
    
    while ((Get-Date) -lt $endTime) {
        $result = 1
        for ($i = 1; $i -lt 10000; $i++) {
            $result *= $i
        }
        Write-Host "." -NoNewline
    }
    Write-Host "`nCPU load test completed."
}

Start-CPULoad -DurationSeconds 30
