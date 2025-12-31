param(
    [string]$preset = "release-static",
    [int]$threads = 8,
    [ValidateSet("cuda", "cpu", "both")]
    [string]$variant = "cuda"
)

$env:CMAKE_BUILD_PARALLEL_LEVEL=$threads



Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Building whisper.cpp ($preset)" -ForegroundColor Cyan
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
Write-Host "Output: build/$preset/whisper.cpp_ggml/lib/" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Green