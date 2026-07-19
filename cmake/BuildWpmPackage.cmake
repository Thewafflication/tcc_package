cmake_minimum_required(VERSION 3.21)

foreach(_required TCC_SOURCE_DIR TCC_PAYLOAD_DIR WPM_STAGING_DIR WPM_OUTPUT_DIR WPM_ARCH WPM_EXECUTABLE)
  if(NOT DEFINED ${_required} OR "${${_required}}" STREQUAL "")
    message(FATAL_ERROR "BuildWpmPackage.cmake requires ${_required}")
  endif()
endforeach()

if(NOT WPM_ARCH MATCHES "^(x86|x64|arm64)$")
  message(FATAL_ERROR "Unsupported WPM architecture: ${WPM_ARCH}")
endif()
if(NOT DEFINED WPM_PACKAGE_DEBUG)
  set(WPM_PACKAGE_DEBUG OFF)
endif()
if(WPM_PACKAGE_DEBUG)
  set(_debug_metadata true)
  set(_debug_filename "-debug")
else()
  set(_debug_metadata false)
  set(_debug_filename "")
endif()
if(NOT EXISTS "${TCC_PAYLOAD_DIR}/tcc.exe")
  message(FATAL_ERROR "TinyCC payload is incomplete: ${TCC_PAYLOAD_DIR}")
endif()

find_package(Git REQUIRED)
execute_process(
  COMMAND "${GIT_EXECUTABLE}" -c safe.directory=${TCC_SOURCE_DIR}
          -C "${TCC_SOURCE_DIR}" describe --tags --long --always --dirty
  OUTPUT_VARIABLE _git_describe OUTPUT_STRIP_TRAILING_WHITESPACE
  RESULT_VARIABLE _git_result
)
execute_process(
  COMMAND "${GIT_EXECUTABLE}" -c safe.directory=${TCC_SOURCE_DIR}
          -C "${TCC_SOURCE_DIR}" rev-parse --short=8 HEAD
  OUTPUT_VARIABLE _git_hash OUTPUT_STRIP_TRAILING_WHITESPACE
  RESULT_VARIABLE _hash_result
)
execute_process(
  COMMAND "${GIT_EXECUTABLE}" -c safe.directory=${TCC_SOURCE_DIR}
          -C "${TCC_SOURCE_DIR}" config --get remote.origin.url
  OUTPUT_VARIABLE _repository OUTPUT_STRIP_TRAILING_WHITESPACE
)
if(NOT _git_result EQUAL 0 OR NOT _hash_result EQUAL 0)
  message(FATAL_ERROR "Could not derive the TinyCC version from its Git submodule")
endif()

file(STRINGS "${TCC_SOURCE_DIR}/VERSION" _source_version LIMIT_COUNT 1)
string(STRIP "${_source_version}" _source_version)
if(NOT _source_version MATCHES "^([0-9]+)\.([0-9]+)\.([0-9]+)(.*)$")
  message(FATAL_ERROR "TinyCC VERSION is not recognized: ${_source_version}")
endif()
set(_major "${CMAKE_MATCH_1}")
set(_minor "${CMAKE_MATCH_2}")
set(_patch "${CMAKE_MATCH_3}")
set(_suffix "${CMAKE_MATCH_4}")

set(_distance 0)
if(_git_describe MATCHES "-([0-9]+)-g[0-9A-Fa-f]+(-dirty)?$")
  set(_distance "${CMAKE_MATCH_1}")
endif()
set(_version "${_major}.${_minor}.${_patch}")
if(NOT _suffix STREQUAL "")
  string(REGEX REPLACE "^[._-]+" "" _suffix "${_suffix}")
  string(REGEX REPLACE "[^0-9A-Za-z-]+" "." _suffix "${_suffix}")
  string(APPEND _version "-${_suffix}")
  if(_distance GREATER 0)
    string(APPEND _version ".${_distance}")
  endif()
elseif(_distance GREATER 0)
  string(APPEND _version "-dev.${_distance}")
endif()
string(APPEND _version "+${_git_hash}")
if(_git_describe MATCHES "-dirty$")
  string(APPEND _version ".dirty")
endif()

file(STRINGS "${TCC_SOURCE_DIR}/README" _description LIMIT_COUNT 1)
string(STRIP "${_description}" _description)
if(_repository STREQUAL "")
  set(_repository "https://repo.or.cz/tinycc.git")
endif()

file(REMOVE_RECURSE "${WPM_STAGING_DIR}")
file(MAKE_DIRECTORY "${WPM_STAGING_DIR}" "${WPM_STAGING_DIR}/.wpm")
file(COPY "${TCC_PAYLOAD_DIR}/" DESTINATION "${WPM_STAGING_DIR}")
configure_file("${TCC_SOURCE_DIR}/COPYING" "${WPM_STAGING_DIR}/LICENSE.txt" COPYONLY)
configure_file("${TCC_SOURCE_DIR}/README" "${WPM_STAGING_DIR}/README.txt" COPYONLY)

file(WRITE "${WPM_STAGING_DIR}/.wpm/package.txt"
  "name=tinycc\n"
  "version=${_version}\n"
  "arch=${WPM_ARCH}\n"
  "debug=${_debug_metadata}\n"
  "description=${_description}\n"
  "maintainer=Jordan Waughtal\n"
  "homepage=${_repository}\n"
  "repository=${_repository}\n"
  "license=LGPL-2.1-or-later\n"
  "source-version=${_source_version}\n"
  "source-revision=${_git_hash}\n"
)

set(_install_dir "%ProgramFiles%\\TinyCC\\${_version}")
file(WRITE "${WPM_STAGING_DIR}/.wpm/install.cmd"
  "@echo off\r\n"
  "setlocal\r\n"
  "set \"TCC_DEST=${_install_dir}\"\r\n"
  "if not exist \"%TCC_DEST%\" mkdir \"%TCC_DEST%\" || exit /b 1\r\n"
  "xcopy \"%~dp0..\\*\" \"%TCC_DEST%\\\" /E /I /Q /Y >nul || exit /b 1\r\n"
  "if exist \"%TCC_DEST%\\.wpm\" rmdir /S /Q \"%TCC_DEST%\\.wpm\"\r\n"
  "reg add \"HKLM\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment\" /v TCC_HOME /t REG_EXPAND_SZ /d \"%TCC_DEST%\" /f >nul || exit /b 1\r\n"
  "exit /b 0\r\n"
)
file(WRITE "${WPM_STAGING_DIR}/.wpm/remove.cmd"
  "@echo off\r\n"
  "setlocal\r\n"
  "set \"TCC_DEST=${_install_dir}\"\r\n"
  "if exist \"%TCC_DEST%\" rmdir /S /Q \"%TCC_DEST%\" || exit /b 1\r\n"
  "set \"TCC_CURRENT=\"\r\n"
  "for /f \"tokens=2,*\" %%A in ('reg query \"HKLM\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment\" /v TCC_HOME 2^>nul') do set \"TCC_CURRENT=%%B\"\r\n"
  "if /I \"%TCC_CURRENT%\"==\"%TCC_DEST%\" reg delete \"HKLM\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment\" /v TCC_HOME /f >nul 2>&1\r\n"
  "exit /b 0\r\n"
)

file(MAKE_DIRECTORY "${WPM_OUTPUT_DIR}")
set(_wpm_command "${WPM_EXECUTABLE}" build "${WPM_STAGING_DIR}" "${WPM_OUTPUT_DIR}")
if(DEFINED WPM_SIGNING_KEY AND NOT "${WPM_SIGNING_KEY}" STREQUAL "")
  if(NOT EXISTS "${WPM_SIGNING_KEY}")
    message(FATAL_ERROR "WPM signing key was not found: ${WPM_SIGNING_KEY}")
  endif()
  list(APPEND _wpm_command --sign "${WPM_SIGNING_KEY}")
endif()
execute_process(
  COMMAND ${_wpm_command}
  RESULT_VARIABLE _wpm_result
  OUTPUT_VARIABLE _wpm_output
  ERROR_VARIABLE _wpm_error
)
if(NOT _wpm_result EQUAL 0)
  message(FATAL_ERROR "WPM package build failed:\n${_wpm_output}${_wpm_error}")
endif()
message(STATUS "Built ${WPM_OUTPUT_DIR}/tinycc-${WPM_ARCH}${_debug_filename}-${_version}.zip")
