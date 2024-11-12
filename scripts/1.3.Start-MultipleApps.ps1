# Save as Start-MultipleApps.ps1

function Start-MultipleApps {
    $apps = @(
        "notepad.exe",
        "calc.exe",
        "mspaint.exe",
        "write.exe"
    )
    
    foreach ($app in $apps) {
        Write-Host "Starting $app..."
        Start-Process $app
        Start-Sleep -Seconds 2
    }
    Write-Host "All applications launched."
}

Start-MultipleApps
