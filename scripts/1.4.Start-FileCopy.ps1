# Save as Start-FileCopy.ps1

$testDir = "C:\PerformanceDemo"
$sourcePath = Join-Path $testDir "source_large_file.dat"
$destPath = Join-Path $testDir "destination_large_file.dat"

Write-Host "Starting file copy operation..."
Write-Host "From: $sourcePath"
Write-Host "To: $destPath"

Copy-Item -Path $sourcePath -Destination $destPath -Force
Write-Host "File copy operation complete."
