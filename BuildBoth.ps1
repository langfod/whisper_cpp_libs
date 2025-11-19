param(
    [string]$config = "release",
    [int]$threads = 8
)

$env:CMAKE_BUILD_PARALLEL_LEVEL=$threads

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Building whisper.cpp - BOTH variants" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Build CUDA variant
$cudaPreset = "$config-cuda"
Write-Host "`n>>> Building CUDA variant ($cudaPreset)..." -ForegroundColor Yellow
& cmake -S . --preset=$cudaPreset
if ($LASTEXITCODE -ne 0) { 
    Write-Error "CUDA configuration failed"
    exit 1
}

& cmake --build --preset=$cudaPreset -- -v
if ($LASTEXITCODE -ne 0) { 
    Write-Error "CUDA build failed"
    exit 1
}

Write-Host "`n>>> CUDA variant completed!" -ForegroundColor Green

# Build CPU-only variant
$cpuPreset = "$config-cpu"
Write-Host "`n>>> Building CPU-only variant ($cpuPreset)..." -ForegroundColor Yellow
& cmake -S . --preset=$cpuPreset
if ($LASTEXITCODE -ne 0) { 
    Write-Error "CPU configuration failed"
    exit 1
}

& cmake --build --preset=$cpuPreset -- -v
if ($LASTEXITCODE -ne 0) { 
    Write-Error "CPU build failed"
    exit 1
}

Write-Host "`n>>> CPU-only variant completed!" -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Both builds completed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "CUDA libs: build/$config-cuda/whisper.cpp_static/lib/" -ForegroundColor Cyan
Write-Host "CPU libs:  build/$config-cpu/whisper.cpp_static/lib/" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Green
