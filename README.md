# Whisper.cpp Static Libraries Build

CMake setup for building whisper.cpp as static libraries with both CPU and CUDA variants.

## Features

- **Static libraries only** - No shared libraries built
- **CPU version** - Optimized CPU-only build (`whisper_cpu.lib`, `ggml_cpu.lib`)
- **CUDA version** - GPU-accelerated build (`whisper_cuda.lib`, `ggml_cuda.lib`)
- **Separate outputs** - Each variant in its own directory with headers

## Prerequisites

- CMake 3.18 or higher
- Ninja build system
- Visual Studio 2022 (for Windows)
- CUDA Toolkit (for CUDA build)
- Python 3.x (for whisper.cpp dependencies)

## Quick Start

### Build both CPU and CUDA versions (Release):
```powershell
.\BuildRelease.ps1 -config release -threads 8
```

### Build CPU version only:
```powershell
.\BuildRelease.ps1 -config release -cpuOnly -threads 8
```

### Build CUDA version only:
```powershell
.\BuildRelease.ps1 -config release -cudaOnly -threads 8
```

### Build Debug versions:
```powershell
.\BuildRelease.ps1 -config debug -threads 8
```

## Output Structure

By default (or when `SKYRIMNET_OUTPUT_PATH` is set), libraries are output to:

```
$SKYRIMNET_OUTPUT_PATH/
├── cpu/
│   ├── lib/
│   │   ├── whisper_cpu.lib
│   │   └── ggml_cpu.lib
│   └── include/
│       ├── whisper.h
│       └── ggml headers...
└── cuda/
    ├── lib/
    │   ├── whisper_cuda.lib
    │   └── ggml_cuda.lib
    └── include/
        ├── whisper.h
        └── ggml headers...
```

## Manual CMake Usage

### Configure and build CPU version:
```powershell
cmake -S . --preset=release-cpu
cmake --build --preset=release-cpu
```

### Configure and build CUDA version:
```powershell
cmake -S . --preset=release-cuda
cmake --build --preset=release-cuda
```

### Install (optional):
```powershell
cmake --install build/release-cpu
cmake --install build/release-cuda
```

## CMake Options

- `BUILD_VARIANT` - Specify "CPU" or "CUDA" variant (required)
- `SKYRIMNET_OUTPUT_PATH` - Output directory (environment variable or CMake variable)

## Integration

Link against the appropriate variant:

```cmake
# For CPU version
target_link_libraries(your_target
    ${SKYRIMNET_OUTPUT_PATH}/cpu/lib/whisper_cpu.lib
    ${SKYRIMNET_OUTPUT_PATH}/cpu/lib/ggml_cpu.lib
)
target_include_directories(your_target PRIVATE
    ${SKYRIMNET_OUTPUT_PATH}/cpu/include
)

# For CUDA version
target_link_libraries(your_target
    ${SKYRIMNET_OUTPUT_PATH}/cuda/lib/whisper_cuda.lib
    ${SKYRIMNET_OUTPUT_PATH}/cuda/lib/ggml_cuda.lib
    # Also link CUDA libraries
)
target_include_directories(your_target PRIVATE
    ${SKYRIMNET_OUTPUT_PATH}/cuda/include
)
```

## Notes

- The build system automatically disables examples, tests, and optional dependencies (curl, SDL2, FFmpeg, etc.)
- CUDA architecture is set to "all-major" for broad compatibility
- Libraries are prefixed with variant name to prevent conflicts
