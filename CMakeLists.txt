cmake_minimum_required(VERSION 3.18)

# CUDA support option - can be set via command line: -DCUDA_ENABLED=OFF
option(CUDA_ENABLED "Enable CUDA support" ON)

if(CUDA_ENABLED)
    project(WhisperCppLibs VERSION 1.0 LANGUAGES C CXX CUDA)
    message(STATUS "Building WITH CUDA support")
else()
    project(WhisperCppLibs VERSION 1.0 LANGUAGES C CXX)
    message(STATUS "Building WITHOUT CUDA support")
endif()

# Output directory
set(OUTPUT_BASE_DIR "${CMAKE_BINARY_DIR}/whisper.cpp_static")

# Common settings - MUST match application's C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build static libraries only" FORCE)

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
        string(REPLACE "/MD" "/MT" ${flag_var} "${${flag_var}}")
    endforeach()
endif()

# CUDA configuration
if(CUDA_ENABLED)
    # Enable CUDA support
    set(GGML_CUDA ON CACHE BOOL "Enable CUDA support" FORCE)
    
    # Static CUDA runtime library - CRITICAL for compatibility
    set(CMAKE_CUDA_RUNTIME_LIBRARY "Static" CACHE STRING "CUDA runtime library" FORCE)
    
    # CUDA flags matching application
    set(CMAKE_CUDA_FLAGS "-allow-unsupported-compiler -Wno-deprecated-gpu-targets" CACHE STRING "CUDA flags" FORCE)
    set(CMAKE_CUDA_ARCHITECTURES "all-major" CACHE STRING "CUDA architectures" FORCE)
else()
    # Disable CUDA support
    set(GGML_CUDA OFF CACHE BOOL "Disable CUDA support" FORCE)
    set(CMAKE_CUDA_FLAGS "" CACHE STRING "Clear CUDA flags" FORCE)
    add_compile_definitions(WHISPER_USE_CUBLAS=0)
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