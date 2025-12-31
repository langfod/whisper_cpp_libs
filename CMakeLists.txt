cmake_minimum_required(VERSION 3.18)

# Common settings - MUST match application's C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

project(WhisperCppLibs VERSION 1.0 LANGUAGES C CXX CUDA)


# Static MSVC runtime library - CRITICAL for compatibility
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>" CACHE STRING "MSVC runtime library" FORCE)

# Disable examples and tests
set(WHISPER_BUILD_TESTS OFF CACHE BOOL "Build tests" FORCE)
set(WHISPER_BUILD_EXAMPLES OFF CACHE BOOL "Build examples" FORCE)
set(WHISPER_BUILD_SERVER OFF CACHE BOOL "Build server" FORCE)
set(WHISPER_ALL_WARNINGS OFF CACHE BOOL "Enable all compiler warnings" FORCE)

# Disable extra dependencies
set(WHISPER_CURL OFF CACHE BOOL "Disable curl" FORCE)
set(WHISPER_SDL2 OFF CACHE BOOL "Disable SDL2" FORCE)
set(WHISPER_FFMPEG OFF CACHE BOOL "Disable FFmpeg (not needed - examples are disabled)" FORCE)
set(WHISPER_COREML OFF CACHE BOOL "Disable CoreML" FORCE)
set(WHISPER_OPENVINO OFF CACHE BOOL "Disable OpenVINO" FORCE)

# MSVC-specific compiler flags to match application
if(MSVC)
    # Remove any existing exception handling flags and set to /EHa (asynchronous)
    string(REGEX REPLACE "/EH[scra-z]+" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
    string(APPEND CMAKE_CXX_FLAGS " /EHa /bigobj /permissive- /Zc:preprocessor /utf-8")
    
    # Add common Windows defines
    add_compile_definitions(WIN32_LEAN_AND_MEAN NOMINMAX UNICODE _UNICODE)
    
    # Force /EHa and /bigobj for all configurations
    foreach(flag_var
        CMAKE_C_FLAGS_RELEASE CMAKE_C_FLAGS_DEBUG
        CMAKE_CXX_FLAGS_RELEASE CMAKE_CXX_FLAGS_DEBUG)
        string(REGEX REPLACE "/EH[scra-z]+" "" ${flag_var} "${${flag_var}}")
        string(APPEND ${flag_var} " /EHa /bigobj")
        # Replace dynamic with static runtime (/MD -> /MT)
        #string(REPLACE "/MD" "/MT" ${flag_var} "${${flag_var}}")
    endforeach()
endif()

# CUDA configuration
# Enable CUDA support
set(GGML_CUDA ON CACHE BOOL "Enable CUDA support" FORCE)
set(CMAKE_CUDA_FLAGS "-allow-unsupported-compiler -Wno-deprecated-gpu-targets --diag-suppress=177 --diag-suppress=550 --diag-suppress=221" CACHE STRING "CUDA flags" FORCE)
set(CMAKE_CUDA_RUNTIME_LIBRARY "Static" CACHE STRING "CUDA runtime library" FORCE)
set(GGML_AMX_VNNI ON CACHE BOOL "Enable AMX VNNI support" FORCE)

set(GGML_AVX2 ON CACHE BOOL "Enable AVX2 support" FORCE)
set(GGML_FMA ON CACHE BOOL "Enable FMA support" FORCE)
set(GGML_F16C ON CACHE BOOL "Enable F16C support" FORCE)
set(GGML_BMI2 ON CACHE BOOL "Enable BMI2 support" FORCE)
# Vulkan configuration
if(DYNAMIC_LIBS)
    set(OUTPUT_BASE_DIR "${CMAKE_BINARY_DIR}/whisper.cpp_dynamic")
    set(GGML_BACKEND_DL ON CACHE BOOL "Build backends as dynamically loaded plugins" FORCE)
    set(BUILD_SHARED_LIBS ON CACHE BOOL "Build shared libraries only" FORCE)
    set(GGML_NATIVE OFF CACHE BOOL "Disable native support" FORCE)
    set(GGML_VULKAN ON CACHE BOOL "Enable Vulkan support" FORCE)
    set(GGML_KOMPUTE ON CACHE BOOL "Enable Kompute support" FORCE)
    set(GGML_OPENCL ON CACHE BOOL "Enable OpenCL support" FORCE)
    message(STATUS "Building WITH Vulkan support")
else()
set(OUTPUT_BASE_DIR "${CMAKE_BINARY_DIR}/whisper.cpp_static")
    set(GGML_BACKEND_DL OFF CACHE BOOL "Build backends as dynamically loaded plugins" FORCE)
    set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build static libraries only" FORCE)
    set(GGML_NATIVE ON CACHE BOOL "Enable native support" FORCE)
    set(GGML_VULKAN OFF CACHE BOOL "Disable Vulkan support" FORCE)
    set(GGML_KOMPUTE OFF CACHE BOOL "Disable Kompute support" FORCE)
    set(GGML_OPENCL OFF CACHE BOOL "Disable OpenCL support" FORCE)
    message(STATUS "Building WITHOUT Vulkan support")
endif()

# Set output directory
set(VARIANT_OUTPUT_DIR "${OUTPUT_BASE_DIR}")

# Add whisper.cpp subdirectory
add_subdirectory(whisper.cpp)

# Create custom target to copy headers after build
add_custom_target(copy_headers ALL
    COMMAND ${CMAKE_COMMAND} -E make_directory "${VARIANT_OUTPUT_DIR}/include"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_CURRENT_SOURCE_DIR}/whisper.cpp/include/whisper.h"
        "${VARIANT_OUTPUT_DIR}/include/whisper.h"
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${CMAKE_CURRENT_SOURCE_DIR}/whisper.cpp/ggml/include"
        "${VARIANT_OUTPUT_DIR}/include"
    COMMENT "Copying headers to ${VARIANT_OUTPUT_DIR}/include"
)

# Configure whisper target if it exists
if(TARGET whisper)
    add_dependencies(copy_headers whisper)
    
    set_target_properties(whisper PROPERTIES
        OUTPUT_NAME "whisper"
        ARCHIVE_OUTPUT_DIRECTORY "${VARIANT_OUTPUT_DIR}/lib"
        LIBRARY_OUTPUT_DIRECTORY "${VARIANT_OUTPUT_DIR}/lib"
        RUNTIME_OUTPUT_DIRECTORY "${VARIANT_OUTPUT_DIR}/bin"
    )
endif()

# Configure ggml target if it exists
if(TARGET ggml)
    add_dependencies(copy_headers ggml)
    
    set_target_properties(ggml PROPERTIES
        OUTPUT_NAME "ggml"
        ARCHIVE_OUTPUT_DIRECTORY "${VARIANT_OUTPUT_DIR}/lib"
        LIBRARY_OUTPUT_DIRECTORY "${VARIANT_OUTPUT_DIR}/lib"
        RUNTIME_OUTPUT_DIRECTORY "${VARIANT_OUTPUT_DIR}/bin"
    )
endif()

# Configure ggml-base target if it exists
if(TARGET ggml-base)
    add_dependencies(copy_headers ggml-base)
    
    set_target_properties(ggml-base PROPERTIES
        OUTPUT_NAME "ggml-base"
        ARCHIVE_OUTPUT_DIRECTORY "${VARIANT_OUTPUT_DIR}/lib"
        LIBRARY_OUTPUT_DIRECTORY "${VARIANT_OUTPUT_DIR}/lib"
        RUNTIME_OUTPUT_DIRECTORY "${VARIANT_OUTPUT_DIR}/bin"
    )
endif()

# Configure ggml-cpu target if it exists
if(TARGET ggml-cpu)
    add_dependencies(copy_headers ggml-cpu)
    
    set_target_properties(ggml-cpu PROPERTIES
        OUTPUT_NAME "ggml-cpu"
        ARCHIVE_OUTPUT_DIRECTORY "${VARIANT_OUTPUT_DIR}/lib"
        LIBRARY_OUTPUT_DIRECTORY "${VARIANT_OUTPUT_DIR}/lib"
        RUNTIME_OUTPUT_DIRECTORY "${VARIANT_OUTPUT_DIR}/bin"
    )
endif()

# Configure ggml-cuda target if it exists (CUDA variant only)
if(TARGET ggml-cuda)
    add_dependencies(copy_headers ggml-cuda)
    
    set_target_properties(ggml-cuda PROPERTIES
        OUTPUT_NAME "ggml-cuda"
        ARCHIVE_OUTPUT_DIRECTORY "${VARIANT_OUTPUT_DIR}/lib"
        LIBRARY_OUTPUT_DIRECTORY "${VARIANT_OUTPUT_DIR}/lib"
        RUNTIME_OUTPUT_DIRECTORY "${VARIANT_OUTPUT_DIR}/bin"
    )
endif()

# Configure ggml-vulkan target if it exists
if(TARGET ggml-vulkan)
    add_dependencies(copy_headers ggml-vulkan)
    
    set_target_properties(ggml-vulkan PROPERTIES
        OUTPUT_NAME "ggml-vulkan"
        ARCHIVE_OUTPUT_DIRECTORY "${VARIANT_OUTPUT_DIR}/lib"
        LIBRARY_OUTPUT_DIRECTORY "${VARIANT_OUTPUT_DIR}/lib"
        RUNTIME_OUTPUT_DIRECTORY "${VARIANT_OUTPUT_DIR}/bin"
    )
endif()

# Configure ggml-opencl target if it exists
if(TARGET ggml-opencl)
    add_dependencies(copy_headers ggml-opencl)
    
    set_target_properties(ggml-opencl PROPERTIES
        OUTPUT_NAME "ggml-opencl"
        ARCHIVE_OUTPUT_DIRECTORY "${VARIANT_OUTPUT_DIR}/lib"
        LIBRARY_OUTPUT_DIRECTORY "${VARIANT_OUTPUT_DIR}/lib"
        RUNTIME_OUTPUT_DIRECTORY "${VARIANT_OUTPUT_DIR}/bin"
    )
endif()

# Configure ggml-kompute target if it exists
if(TARGET ggml-kompute)
    add_dependencies(copy_headers ggml-kompute)
    
    set_target_properties(ggml-kompute PROPERTIES
        OUTPUT_NAME "ggml-kompute"
        ARCHIVE_OUTPUT_DIRECTORY "${VARIANT_OUTPUT_DIR}/lib"
        LIBRARY_OUTPUT_DIRECTORY "${VARIANT_OUTPUT_DIR}/lib"
        RUNTIME_OUTPUT_DIRECTORY "${VARIANT_OUTPUT_DIR}/bin"
    )
endif()

# Configure ggml-sycl target if it exists
if(TARGET ggml-sycl)
    add_dependencies(copy_headers ggml-sycl)
    
    set_target_properties(ggml-sycl PROPERTIES
        OUTPUT_NAME "ggml-sycl"
        ARCHIVE_OUTPUT_DIRECTORY "${VARIANT_OUTPUT_DIR}/lib"
        LIBRARY_OUTPUT_DIRECTORY "${VARIANT_OUTPUT_DIR}/lib"
        RUNTIME_OUTPUT_DIRECTORY "${VARIANT_OUTPUT_DIR}/bin"
    )
endif()

# Post-build cleanup: remove .exp files (linker intermediates not needed for distribution)
if(DYNAMIC_LIBS)
    if(WIN32)
        add_custom_target(cleanup_exp_files ALL
            COMMAND powershell -Command "Remove-Item -Path '${VARIANT_OUTPUT_DIR}/lib/*.exp' -Force -ErrorAction SilentlyContinue"
            COMMAND powershell -Command "Remove-Item -Path '${VARIANT_OUTPUT_DIR}/bin/*.exp' -Force -ErrorAction SilentlyContinue"
            COMMENT "Cleaning up .exp files"
        )
        add_dependencies(cleanup_exp_files copy_headers)
    endif()
endif()

# Add definitions to suppress warnings
add_definitions(-D_SILENCE_STDEXT_ARR_ITERS_DEPRECATION_WARNING)
add_definitions(-D_SILENCE_ALL_MS_EXT_DEPRECATION_WARNINGS)

# Add flags for PDB generation in Release builds
if(MSVC)
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /Zi -Wno-dev")
    set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} /DEBUG /OPT:REF /OPT:ICF")
    set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} /DEBUG /OPT:REF /OPT:ICF")
    set(CMAKE_STATIC_LINKER_FLAGS_RELEASE "${CMAKE_STATIC_LINKER_FLAGS_RELEASE}")
endif()

# Print summary
message(STATUS "=== Whisper.cpp Build Configuration ===")
message(STATUS "Build variant: ${BUILD_VARIANT}")
message(STATUS "Output directory: ${VARIANT_OUTPUT_DIR}")
message(STATUS "C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "MSVC Runtime: ${CMAKE_MSVC_RUNTIME_LIBRARY}")
if(BUILD_VARIANT STREQUAL "CUDA")
    message(STATUS "CUDA Runtime: ${CMAKE_CUDA_RUNTIME_LIBRARY}")
    message(STATUS "CUDA Architectures: ${CMAKE_CUDA_ARCHITECTURES}")
endif()
message(STATUS "Static libraries: ON")
message(STATUS "=======================================")
# Print summary
message(STATUS "=== Whisper.cpp Build Configuration ===")
message(STATUS "Output directory: ${VARIANT_OUTPUT_DIR}")
message(STATUS "C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "MSVC Runtime: ${CMAKE_MSVC_RUNTIME_LIBRARY}")
message(STATUS "CUDA Enabled: ${CUDA_ENABLED}")
if(CUDA_ENABLED)
    message(STATUS "CUDA Runtime: ${CMAKE_CUDA_RUNTIME_LIBRARY}")
    message(STATUS "CUDA Architectures: ${CMAKE_CUDA_ARCHITECTURES}")
endif()
message(STATUS "Static libraries: ON")
message(STATUS "=======================================")