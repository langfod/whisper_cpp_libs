# Whisper.cpp Static Library Builder

Builds optimized static libraries for whisper.cpp with optional CUDA support.

## Build Variants

### CUDA-enabled (default)
- Includes CUDA GPU acceleration
- Requires NVIDIA CUDA Toolkit 12.9+
- Static CUDA runtime (no external DLL dependencies for CUDA runtime)

### CPU-only
- No CUDA dependencies
- Optimized with AVX2, FMA, F16C, BMI2 instructions
- Works on any x64 system

## Quick Start

### Build CUDA variant (default)
```powershell
.\BuildRelease.ps1
# or explicitly:
.\BuildRelease.ps1 -variant cuda
```

### Build CPU-only variant
```powershell
.\BuildRelease.ps1 -variant cpu
```

### Build both variants
```powershell
.\BuildRelease.ps1 -variant both
# or use dedicated script:
.\BuildBoth.ps1
```

### Debug builds
```powershell
.\BuildRelease.ps1 -config debug -variant cuda
.\BuildRelease.ps1 -config debug -variant cpu
```

## Output Locations

After building:
- **CUDA libs**: `build/release-cuda/whisper.cpp_static/lib/`
- **CPU libs**: `build/release-cpu/whisper.cpp_static/lib/`

Libraries generated:
- `whisper.lib` - Main whisper library
- `ggml.lib` - GGML core library  
- `ggml-base.lib` - GGML base utilities
- `ggml-cpu.lib` - CPU backend
- `ggml-cuda.lib` - CUDA backend (CUDA variant only)

Headers: `build/[preset]/whisper.cpp_static/include/`

## CMake Presets

Available presets:
- `release-cuda` - Release with CUDA
- `release-cpu` - Release CPU-only
- `debug-cuda` - Debug with CUDA
- `debug-cpu` - Debug CPU-only
- `release` - Alias for release-cuda
- `debug` - Alias for debug-cuda

### Manual CMake usage
```powershell
# Configure
cmake --preset release-cpu

# Build
cmake --build --preset release-cpu
```

## Integration with Your Application

### For CPU-only build
Link against libraries from `build/release-cpu/whisper.cpp_static/lib/`:
```cmake
target_link_libraries(YourApp PRIVATE
    whisper
    ggml
    ggml-base
    ggml-cpu
)
```

### For CUDA build
Link against libraries from `build/release-cuda/whisper.cpp_static/lib/`:
```cmake
target_link_libraries(YourApp PRIVATE
    whisper
    ggml
    ggml-base
    ggml-cpu
    ggml-cuda
    cudart_static  # Static CUDA runtime
)
```

**Important**: The CUDA variant uses **static CUDA runtime**, so your application won't need CUDA runtime DLLs. However, you still need to link with `cudart_static.lib` from the CUDA Toolkit.

## Optimization Flags

All builds include maximum performance optimizations:

### Compiler optimizations
- `/O2` - Maximum speed optimization
- `/Ob2` - Full function inlining
- `/favor:blend` - Optimize for both Intel and AMD

### CPU SIMD instructions (both variants)
- **AVX2** - 256-bit vector operations
- **FMA** - Fused multiply-add
- **F16C** - Fast FP16↔FP32 conversion  
- **BMI2** - Bit manipulation instructions

### CUDA optimizations (CUDA variant only)
- `all-major` architectures
- Static runtime linking
- Optimized for CUDA 12.9

## Requirements

- Windows 10/11
- Visual Studio 2022 (MSVC 14.44+)
- CMake 3.18+
- Ninja build system
- NVIDIA CUDA Toolkit 12.9+ (for CUDA variant only)

## Troubleshooting

### CPU variant still requires CUDA DLLs
This means `CUDA_ENABLED` is not being properly disabled. Verify:
```powershell
cmake --preset release-cpu
# Should show: "Building WITHOUT CUDA support"
```

### Build fails with CUDA errors on CPU-only build
Make sure you're using the correct preset:
- ❌ `cmake --preset release`
- ✅ `cmake --preset release-cpu`

### Performance seems slow
Verify optimizations are enabled in CMakeCache.txt:
```
GGML_AVX2:BOOL=ON
GGML_FMA:BOOL=ON
CMAKE_CXX_FLAGS_RELEASE:STRING=/O2 /Ob2 /DNDEBUG ...
```
