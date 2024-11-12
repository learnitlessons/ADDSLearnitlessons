# Save as Create-DemoFile.ps1

function Create-LargeFile {
    param (
        [string]$Path,
        [int]$SizeMB = 500  # 500MB default size
    )
    
    Write-Host "Creating test file of $SizeMB MB at $Path..."
    $buffer = New-Object Byte[] (1024 * 1024)  # 1MB buffer
    $stream = [System.IO.File]::OpenWrite($Path)
    
    for ($i = 0; $i -lt $SizeMB; $i++) {
        $stream.Write($buffer, 0, $buffer.Length)
        if ($i % 50 -eq 0) {
            Write-Host "Written $i MB..."
        }
    }
    
    $stream.Close()
    Write-Host "File creation complete."
}

# Create test directory and file
$testDir = "C:\PerformanceDemo"
if (-not (Test-Path $testDir)) {
    New-Item -ItemType Directory -Path $testDir | Out-Null
}

$sourcePath = Join-Path $testDir "source_large_file.dat"
Create-LargeFile -Path $sourcePath -SizeMB 500
