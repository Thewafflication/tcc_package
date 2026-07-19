cmake_minimum_required(VERSION 3.21)

project(tcc_package LANGUAGES NONE)

set(TCC_TARGET "x64" CACHE STRING "TinyCC PE target: x86, x64, or arm64")
set_property(CACHE TCC_TARGET PROPERTY STRINGS x86 x64 arm64)
set(TCC_TOOLCHAIN "msvc" CACHE STRING "Host toolchain: tcc-bootstrap or msvc")
set_property(CACHE TCC_TOOLCHAIN PROPERTY STRINGS tcc-bootstrap msvc)

if(NOT TCC_TARGET MATCHES "^(x86|x64|arm64)$")
  message(FATAL_ERROR "TCC_TARGET must be x86, x64, or arm64")
endif()
if(TCC_TARGET STREQUAL "x86" AND NOT TCC_TOOLCHAIN STREQUAL "tcc-bootstrap")
  message(FATAL_ERROR "The x86 package must use TCC_TOOLCHAIN=tcc-bootstrap")
endif()
if(NOT TCC_TARGET STREQUAL "x86" AND NOT TCC_TOOLCHAIN STREQUAL "msvc")
  message(FATAL_ERROR "The x64 and arm64 packages must use TCC_TOOLCHAIN=msvc")
endif()

set(_package_dir "${CMAKE_BINARY_DIR}/package")
set(_stamp "${CMAKE_BINARY_DIR}/tcc-${TCC_TARGET}-${TCC_TOOLCHAIN}.stamp")
set(WPM_EXECUTABLE "" CACHE FILEPATH "Path to the Waughtal Package Manager executable")
set(WPM_PACKAGE_OUTPUT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/out/packages" CACHE PATH
  "Directory for final WPM package archives")
set(WPM_SIGNING_KEY "$ENV{ProgramData}/WPM/wpm-release.private" CACHE FILEPATH
  "Ed25519 private key used to sign WPM packages")
option(WPM_PACKAGE_DEBUG "Mark the generated WPM archive as a debug package" OFF)

add_custom_command(
  OUTPUT "${_stamp}"
  COMMAND "${CMAKE_COMMAND}"
          -DSOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}/tinycc
          -DWORK_DIR=${CMAKE_BINARY_DIR}/source
          -DOUTPUT_DIR=${_package_dir}
          -DTARGET_ARCH=${TCC_TARGET}
          -DHOST_TOOLCHAIN=${TCC_TOOLCHAIN}
          -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/BuildTinyCC.cmake"
  COMMAND "${CMAKE_COMMAND}" -E touch "${_stamp}"
  DEPENDS
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/BuildTinyCC.cmake"
    "${CMAKE_CURRENT_SOURCE_DIR}/tinycc/win32/build-tcc.bat"
  VERBATIM
  USES_TERMINAL
  COMMENT "Building TinyCC ${TCC_TARGET} package with ${TCC_TOOLCHAIN}"
)

add_custom_target(tinycc ALL DEPENDS "${_stamp}")

if(NOT WPM_EXECUTABLE)
  find_program(_WPM_EXECUTABLE NAMES wpm wpm.exe)
  if(_WPM_EXECUTABLE)
    set(WPM_EXECUTABLE "${_WPM_EXECUTABLE}" CACHE FILEPATH
      "Path to the Waughtal Package Manager executable" FORCE)
  endif()
endif()
if(NOT WPM_EXECUTABLE)
  message(FATAL_ERROR "wpm.exe was not found; set WPM_EXECUTABLE to build packages")
endif()

add_custom_target(wpm-package ALL
  COMMAND "${CMAKE_COMMAND}"
          -DTCC_SOURCE_DIR=${CMAKE_CURRENT_SOURCE_DIR}/tinycc
          -DTCC_PAYLOAD_DIR=${_package_dir}
          -DWPM_STAGING_DIR=${CMAKE_BINARY_DIR}/wpm-staging
          -DWPM_OUTPUT_DIR=${WPM_PACKAGE_OUTPUT_DIR}
          -DWPM_ARCH=${TCC_TARGET}
          -DWPM_EXECUTABLE=${WPM_EXECUTABLE}
          -DWPM_SIGNING_KEY=${WPM_SIGNING_KEY}
          -DWPM_PACKAGE_DEBUG=${WPM_PACKAGE_DEBUG}
          -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/BuildWpmPackage.cmake"
  DEPENDS tinycc
  VERBATIM
  USES_TERMINAL
  COMMENT "Building TinyCC ${TCC_TARGET} WPM package"
)

install(DIRECTORY "${_package_dir}/" DESTINATION ".")
