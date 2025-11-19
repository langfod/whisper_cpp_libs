param(
    [string]$config = "release",
    [int]$threads = 8,
    [ValidateSet("cuda", "cpu", "both")]
    [string]$variant = "cuda"
)

$env:CMAKE_BUILD_PARALLEL_LEVEL=$threads

if ($variant -eq "both") {
    Write-Host "Building both CUDA and CPU variants..." -ForegroundColor Yellow
    & .\BuildBoth.ps1 -config $config -threads $threads
    exit $LASTEXITCODE
}

$preset = "$config-$variant"
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Building whisper.cpp ($config-$variant)" -ForegroundColor Cyan
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
Write-Host "========================================" -ForegroundColor Green
Write-Host "Output: build/$preset/whisper.cpp_static/lib/" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Green