cmake_minimum_required(VERSION 3.21)

project(tcc_package LANGUAGES NONE)

include(CTest)

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
file(GLOB_RECURSE _tcc_build_inputs CONFIGURE_DEPENDS
  "${CMAKE_CURRENT_SOURCE_DIR}/tinycc/*.c"
  "${CMAKE_CURRENT_SOURCE_DIR}/tinycc/*.h"
  "${CMAKE_CURRENT_SOURCE_DIR}/tinycc/*.S"
  "${CMAKE_CURRENT_SOURCE_DIR}/tinycc/Makefile"
  "${CMAKE_CURRENT_SOURCE_DIR}/tinycc/win32/*.bat"
)
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
    ${_tcc_build_inputs}
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/BuildTinyCC.cmake"
    "${CMAKE_CURRENT_SOURCE_DIR}/tinycc/win32/build-tcc.bat"
  VERBATIM
  USES_TERMINAL
  COMMENT "Building TinyCC ${TCC_TARGET} package with ${TCC_TOOLCHAIN}"
)

add_custom_target(tinycc ALL DEPENDS "${_stamp}")

if(BUILD_TESTING)
  find_program(POWERSHELL_EXECUTABLE NAMES pwsh pwsh.exe REQUIRED)
  if(TCC_TARGET STREQUAL "arm64")
    set(_cx01_execution_mode CompileOnly)
  else()
    set(_cx01_execution_mode Native)
  endif()
  add_test(
    NAME tcc-cx01-types
    COMMAND
      "${POWERSHELL_EXECUTABLE}"
      -NoProfile
      -File "${CMAKE_CURRENT_SOURCE_DIR}/tests/cx01/run-tc-0001.ps1"
      -Compiler "${_package_dir}/tcc.exe"
      -ExecutionMode "${_cx01_execution_mode}"
  )
  set_tests_properties(tcc-cx01-types PROPERTIES
    LABELS "cx01;TCC-CX-TC-0001"
    REQUIRED_FILES "${_package_dir}/tcc.exe"
  )
  add_test(
    NAME tcc-cx01-objects
    COMMAND
      "${POWERSHELL_EXECUTABLE}"
      -NoProfile
      -File "${CMAKE_CURRENT_SOURCE_DIR}/tests/cx01/run-tc-0002.ps1"
      -Compiler "${_package_dir}/tcc.exe"
      -ExecutionMode "${_cx01_execution_mode}"
  )
  set_tests_properties(tcc-cx01-objects PROPERTIES
    LABELS "cx01;TCC-CX-TC-0002"
    REQUIRED_FILES "${_package_dir}/tcc.exe"
  )
  add_test(
    NAME tcc-cx01-conversions
    COMMAND
      "${POWERSHELL_EXECUTABLE}"
      -NoProfile
      -File "${CMAKE_CURRENT_SOURCE_DIR}/tests/cx01/run-tc-0003.ps1"
      -Compiler "${_package_dir}/tcc.exe"
      -ExecutionMode "${_cx01_execution_mode}"
  )
  set_tests_properties(tcc-cx01-conversions PROPERTIES
    LABELS "cx01;TCC-CX-TC-0003"
    REQUIRED_FILES "${_package_dir}/tcc.exe"
  )
  add_test(
    NAME tcc-cx01-operators
    COMMAND
      "${POWERSHELL_EXECUTABLE}"
      -NoProfile
      -File "${CMAKE_CURRENT_SOURCE_DIR}/tests/cx01/run-tc-0004.ps1"
      -Compiler "${_package_dir}/tcc.exe"
      -ExecutionMode "${_cx01_execution_mode}"
  )
  set_tests_properties(tcc-cx01-operators PROPERTIES
    LABELS "cx01;TCC-CX-TC-0004"
    REQUIRED_FILES "${_package_dir}/tcc.exe"
  )
  add_test(
    NAME tcc-cx01-abi
    COMMAND
      "${POWERSHELL_EXECUTABLE}"
      -NoProfile
      -File "${CMAKE_CURRENT_SOURCE_DIR}/tests/cx01/run-tc-0005.ps1"
      -Compiler "${_package_dir}/tcc.exe"
      -TargetArchitecture "${TCC_TARGET}"
      -ExecutionMode "${_cx01_execution_mode}"
  )
  set_tests_properties(tcc-cx01-abi PROPERTIES
    LABELS "cx01;TCC-CX-TC-0005"
    REQUIRED_FILES "${_package_dir}/tcc.exe"
  )
  add_test(
    NAME tcc-cx01-musl-header
    COMMAND
      "${POWERSHELL_EXECUTABLE}"
      -NoProfile
      -File "${CMAKE_CURRENT_SOURCE_DIR}/tests/cx01/run-tc-0006.ps1"
      -Compiler "${_package_dir}/tcc.exe"
      -ExecutionMode CompileOnly
  )
  set_tests_properties(tcc-cx01-musl-header PROPERTIES
    LABELS "cx01;TCC-CX-TC-0006"
    REQUIRED_FILES "${_package_dir}/tcc.exe"
  )
  add_test(
    NAME tcc-cx01-regression-package
    COMMAND
      "${POWERSHELL_EXECUTABLE}"
      -NoProfile
      -File "${CMAKE_CURRENT_SOURCE_DIR}/tests/cx01/run-tc-0007.ps1"
      -Compiler "${_package_dir}/tcc.exe"
      -TargetArchitecture "${TCC_TARGET}"
      -ExecutionMode "${_cx01_execution_mode}"
  )
  set_tests_properties(tcc-cx01-regression-package PROPERTIES
    LABELS "cx01;TCC-CX-TC-0007"
    REQUIRED_FILES "${_package_dir}/tcc.exe"
  )

  foreach(_cx02_id RANGE 1001 1006)
    add_test(
      NAME "tcc-cx02-tc-${_cx02_id}"
      COMMAND
        "${POWERSHELL_EXECUTABLE}"
        -NoProfile
        -File
          "${CMAKE_CURRENT_SOURCE_DIR}/tests/cx02/run-tc-${_cx02_id}.ps1"
        -Compiler "${_package_dir}/tcc.exe"
        -ExecutionMode "${_cx01_execution_mode}"
    )
    set_tests_properties("tcc-cx02-tc-${_cx02_id}" PROPERTIES
      LABELS "cx02;TCC-CX-TC-${_cx02_id}"
      REQUIRED_FILES "${_package_dir}/tcc.exe"
    )
  endforeach()
  add_test(
    NAME tcc-cx02-tc-1007
    COMMAND
      "${POWERSHELL_EXECUTABLE}"
      -NoProfile
      -File "${CMAKE_CURRENT_SOURCE_DIR}/tests/cx02/run-tc-1007.ps1"
      -Compiler "${_package_dir}/tcc.exe"
      -TargetArchitecture "${TCC_TARGET}"
  )
  set_tests_properties(tcc-cx02-tc-1007 PROPERTIES
    LABELS "cx02;TCC-CX-TC-1007"
    REQUIRED_FILES "${_package_dir}/tcc.exe"
  )
  add_test(
    NAME tcc-cx02-tc-1008
    COMMAND
      "${POWERSHELL_EXECUTABLE}"
      -NoProfile
      -File "${CMAKE_CURRENT_SOURCE_DIR}/tests/cx02/run-tc-1008.ps1"
      -Compiler "${_package_dir}/tcc.exe"
      -TargetArchitecture "${TCC_TARGET}"
      -ExecutionMode "${_cx01_execution_mode}"
  )
  set_tests_properties(tcc-cx02-tc-1008 PROPERTIES
    LABELS "cx02;TCC-CX-TC-1008"
    REQUIRED_FILES "${_package_dir}/tcc.exe"
  )
endif()

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
