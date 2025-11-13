param(
    [string]$config = "release",
    [int]$threads = 8
)

$env:CMAKE_BUILD_PARALLEL_LEVEL=$threads

$preset = $config
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Building whisper.cpp ($config)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

& cmake -S . --preset=$preset
if ($LASTEXITCODE -ne 0) { 
    Write-Error "Configuration failed"
    exit 1
}

& cmake --build --preset=$preset -- -v
if ($LASTEXITCODE -ne 0) { 
    Write-Error "Build failed"
    exit 1
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Build completed successfully!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green