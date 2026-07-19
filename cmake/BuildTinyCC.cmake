foreach(_required SOURCE_DIR WORK_DIR OUTPUT_DIR TARGET_ARCH HOST_TOOLCHAIN)
  if(NOT DEFINED ${_required} OR "${${_required}}" STREQUAL "")
    message(FATAL_ERROR "BuildTinyCC.cmake requires ${_required}")
  endif()
endforeach()

file(REMOVE_RECURSE "${WORK_DIR}" "${OUTPUT_DIR}")
file(MAKE_DIRECTORY "${WORK_DIR}" "${OUTPUT_DIR}")
file(COPY "${SOURCE_DIR}/" DESTINATION "${WORK_DIR}" PATTERN ".git" EXCLUDE)

if(TARGET_ARCH STREQUAL "x86")
  set(_tcc_target i386)
elseif(TARGET_ARCH STREQUAL "x64")
  set(_tcc_target x86_64)
else()
  set(_tcc_target arm64)
endif()

file(TO_NATIVE_PATH "${WORK_DIR}/win32" _build_dir)
file(TO_NATIVE_PATH "${OUTPUT_DIR}" _output_dir)

if(HOST_TOOLCHAIN STREQUAL "mingw")
  find_program(_mingw_cc NAMES i686-w64-mingw32-gcc gcc)
  if(NOT _mingw_cc)
    message(FATAL_ERROR
      "A 32-bit MinGW compiler was not found. Install i686-w64-mingw32-gcc "
      "and ensure its bin directory is on PATH.")
  endif()
  execute_process(
    COMMAND "${_mingw_cc}" -dumpmachine
    OUTPUT_VARIABLE _mingw_machine
    OUTPUT_STRIP_TRAILING_WHITESPACE
    RESULT_VARIABLE _probe_result
  )
  if(NOT _probe_result EQUAL 0 OR NOT _mingw_machine MATCHES "^(i[3-6]86|mingw32)")
    message(FATAL_ERROR
      "${_mingw_cc} targets '${_mingw_machine}', not 32-bit x86. "
      "Put i686-w64-mingw32-gcc on PATH.")
  endif()
  file(TO_NATIVE_PATH "${_mingw_cc}" _mingw_cc_native)
  set(_cc "\"${_mingw_cc_native}\" -O2 -Wall -static -static-libgcc -D_WIN32_WINNT=0x0501 -DWINVER=0x0501 -Wl,--major-subsystem-version,5,--minor-subsystem-version,1")
  set(_command "call build-tcc.bat -c \"${_cc}\" -t ${_tcc_target} -i \"${_output_dir}\"")
else()
  set(_vsdevcmd "$ENV{TCC_VSDEVCMD}")
  if(NOT EXISTS "${_vsdevcmd}")
    set(_vswhere "C:/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe")
    if(EXISTS "${_vswhere}")
      execute_process(
        COMMAND "${_vswhere}" -latest -products *
                -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64
                -property installationPath
        OUTPUT_VARIABLE _vs_install
        OUTPUT_STRIP_TRAILING_WHITESPACE
      )
      if(NOT "${_vs_install}" STREQUAL "")
        set(_vsdevcmd "${_vs_install}/Common7/Tools/VsDevCmd.bat")
      endif()
    endif()
    if(NOT EXISTS "${_vsdevcmd}")
      file(GLOB _vsdevcmd_candidates LIST_DIRECTORIES false
        "C:/Program Files/Microsoft Visual Studio/*/*/Common7/Tools/VsDevCmd.bat")
      list(GET _vsdevcmd_candidates 0 _vsdevcmd)
    endif()
  endif()
  if(NOT EXISTS "${_vsdevcmd}")
    message(FATAL_ERROR "Visual Studio VsDevCmd.bat was not found")
  endif()
  file(TO_NATIVE_PATH "${_vsdevcmd}" _vsdevcmd_native)
  # The produced compiler runs on x64 Windows and emits code for TARGET_ARCH.
  # This avoids requiring an ARM64 build host while still using MSVC to build TCC.
  set(_command "call \"${_vsdevcmd_native}\" -no_logo -arch=x64 -host_arch=x64 && call build-tcc.bat -c cl -t ${_tcc_target} -i \"${_output_dir}\"")
endif()

set(_launcher "${CMAKE_CURRENT_BINARY_DIR}/build-tinycc-${TARGET_ARCH}.cmd")
file(TO_NATIVE_PATH "${WORK_DIR}" _git_ceiling)
file(WRITE "${_launcher}"
  "@echo off\r\nset \"GIT_CEILING_DIRECTORIES=${_git_ceiling}\"\r\n${_command}\r\nexit /b %ERRORLEVEL%\r\n")
file(TO_NATIVE_PATH "${_launcher}" _launcher_native)

execute_process(
  COMMAND cmd.exe /d /c "${_launcher_native}"
  WORKING_DIRECTORY "${_build_dir}"
  COMMAND_ECHO STDOUT
  RESULT_VARIABLE _build_result
)
if(NOT _build_result EQUAL 0)
  message(FATAL_ERROR "TinyCC ${TARGET_ARCH}/${HOST_TOOLCHAIN} build failed (${_build_result})")
endif()
