foreach(_required SOURCE_DIR WORK_DIR OUTPUT_DIR TARGET_ARCH HOST_TOOLCHAIN)
  if(NOT DEFINED ${_required} OR "${${_required}}" STREQUAL "")
    message(FATAL_ERROR "BuildTinyCC.cmake requires ${_required}")
  endif()
endforeach()

function(find_vsdevcmd result)
  set(_candidate "$ENV{TCC_VSDEVCMD}")
  if(NOT EXISTS "${_candidate}")
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
        set(_candidate "${_vs_install}/Common7/Tools/VsDevCmd.bat")
      endif()
    endif()
  endif()
  if(NOT EXISTS "${_candidate}")
    file(GLOB _candidates LIST_DIRECTORIES false
      "C:/Program Files/Microsoft Visual Studio/*/*/Common7/Tools/VsDevCmd.bat")
    list(LENGTH _candidates _candidate_count)
    if(_candidate_count GREATER 0)
      list(GET _candidates 0 _candidate)
    endif()
  endif()
  if(NOT EXISTS "${_candidate}")
    message(FATAL_ERROR "Visual Studio VsDevCmd.bat was not found")
  endif()
  set(${result} "${_candidate}" PARENT_SCOPE)
endfunction()

function(run_launcher name working_directory command_text)
  set(_launcher "${CMAKE_CURRENT_BINARY_DIR}/${name}.cmd")
  file(TO_NATIVE_PATH "${WORK_DIR}" _git_ceiling)
  file(WRITE "${_launcher}"
    "@echo off\r\nset \"GIT_CEILING_DIRECTORIES=${_git_ceiling}\"\r\n${command_text}\r\nexit /b %ERRORLEVEL%\r\n")
  file(TO_NATIVE_PATH "${_launcher}" _launcher_native)
  execute_process(
    COMMAND cmd.exe /d /c "${_launcher_native}"
    WORKING_DIRECTORY "${working_directory}"
    COMMAND_ECHO STDOUT
    RESULT_VARIABLE _result
  )
  if(NOT _result EQUAL 0)
    message(FATAL_ERROR "${name} failed (${_result})")
  endif()
endfunction()

file(REMOVE_RECURSE "${WORK_DIR}" "${OUTPUT_DIR}")
file(MAKE_DIRECTORY "${WORK_DIR}" "${OUTPUT_DIR}")
file(TO_NATIVE_PATH "${OUTPUT_DIR}" _output_dir)
find_vsdevcmd(_vsdevcmd)
file(TO_NATIVE_PATH "${_vsdevcmd}" _vsdevcmd_native)

if(HOST_TOOLCHAIN STREQUAL "tcc-bootstrap")
  if(NOT TARGET_ARCH STREQUAL "x86")
    message(FATAL_ERROR "tcc-bootstrap is only supported for the x86 target")
  endif()

  # Stage 1: MSVC emits an x64 executable containing TinyCC's i386 backend.
  # -x names it i386-win32-tcc.exe and builds the prefixed i386 runtime that
  # the cross-compiler needs when linking the native second stage.
  set(_bootstrap_source "${WORK_DIR}/bootstrap")
  file(MAKE_DIRECTORY "${_bootstrap_source}")
  file(COPY "${SOURCE_DIR}/" DESTINATION "${_bootstrap_source}" PATTERN ".git" EXCLUDE)
  file(TO_NATIVE_PATH "${_bootstrap_source}/win32" _bootstrap_dir)
  set(_bootstrap_command
    "call \"${_vsdevcmd_native}\" -no_logo -arch=x64 -host_arch=x64 && call build-tcc.bat -c cl -x i386")
  run_launcher("bootstrap-i386-cross" "${_bootstrap_dir}" "${_bootstrap_command}")

  set(_cross_compiler "${_bootstrap_source}/win32/i386-win32-tcc.exe")
  if(NOT EXISTS "${_cross_compiler}")
    message(FATAL_ERROR "The i386 cross-compiler was not produced: ${_cross_compiler}")
  endif()
  # Keep this explicit for resilience if upstream's cross-build copy phase changes.
  file(GLOB _bootstrap_headers "${_bootstrap_source}/include/*.h")
  foreach(_bootstrap_header IN LISTS _bootstrap_headers)
    get_filename_component(_bootstrap_header_name "${_bootstrap_header}" NAME)
    configure_file(
      "${_bootstrap_header}"
      "${_bootstrap_source}/win32/include/${_bootstrap_header_name}"
      COPYONLY
    )
  endforeach()

  # Stage 2: the x64-hosted cross-compiler emits native PE32/i386 binaries.
  set(_native_source "${WORK_DIR}/native")
  file(MAKE_DIRECTORY "${_native_source}")
  file(COPY "${SOURCE_DIR}/" DESTINATION "${_native_source}" PATTERN ".git" EXCLUDE)
  file(TO_NATIVE_PATH "${_native_source}/win32" _native_dir)
  file(TO_NATIVE_PATH "${_cross_compiler}" _cross_compiler_native)
  set(_native_command
    "call build-tcc.bat -c \"${_cross_compiler_native}\" -t i386 -i \"${_output_dir}\"")
  run_launcher("build-native-i386" "${_native_dir}" "${_native_command}")
  set(_bundle_source "${_native_source}")
  set(_bundle_dir "${_native_dir}")
  set(_bundle_setup "")
  set(_bundle_cc_arg ".\\tcc.exe")
else()
  file(COPY "${SOURCE_DIR}/" DESTINATION "${WORK_DIR}" PATTERN ".git" EXCLUDE)
  file(TO_NATIVE_PATH "${WORK_DIR}/win32" _build_dir)
  if(TARGET_ARCH STREQUAL "x64")
    set(_tcc_target x86_64)
  elseif(TARGET_ARCH STREQUAL "arm64")
    set(_tcc_target arm64)
  else()
    message(FATAL_ERROR "MSVC builds support x64 and arm64 targets")
  endif()
  # These are x64-hosted compilers whose TinyCC backend emits the selected target.
  set(_command
    "call \"${_vsdevcmd_native}\" -no_logo -arch=x64 -host_arch=x64 && call build-tcc.bat -c cl -t ${_tcc_target} -i \"${_output_dir}\"")
  run_launcher("build-tinycc-${TARGET_ARCH}" "${_build_dir}" "${_command}")
  set(_bundle_source "${WORK_DIR}")
  set(_bundle_dir "${_build_dir}")
  set(_bundle_setup "call \"${_vsdevcmd_native}\" -no_logo -arch=x64 -host_arch=x64 && ")
  # Keep cl unquoted so upstream build-tcc.bat recognizes it and routes all
  # three builds through its MSVC argument-translation wrapper.
  set(_bundle_cc_arg "cl")
endif()

# Build one explicitly named compiler and one prefixed runtime for every output
# target. All three executables run on the package host architecture; their
# names identify the PE architecture they emit.
set(_bundle_command
  "${_bundle_setup}call build-tcc.bat -c ${_bundle_cc_arg} -x i386 && call build-tcc.bat -c ${_bundle_cc_arg} -x x86_64 && call build-tcc.bat -c ${_bundle_cc_arg} -x arm64")
run_launcher("build-cross-bundle-${TARGET_ARCH}" "${_bundle_dir}" "${_bundle_command}")

file(GLOB _cross_compilers "${_bundle_source}/win32/*-win32-tcc.exe")
list(LENGTH _cross_compilers _cross_compiler_count)
if(NOT _cross_compiler_count EQUAL 3)
  message(FATAL_ERROR "Expected three cross-compilers, found ${_cross_compiler_count}")
endif()
foreach(_cross_compiler IN LISTS _cross_compilers)
  get_filename_component(_cross_name "${_cross_compiler}" NAME)
  configure_file("${_cross_compiler}" "${OUTPUT_DIR}/${_cross_name}" COPYONLY)
endforeach()

file(GLOB _cross_runtime_files "${_bundle_source}/win32/lib/*-win32-*")
if(NOT _cross_runtime_files)
  message(FATAL_ERROR "No prefixed cross-target runtime files were produced")
endif()
foreach(_runtime_file IN LISTS _cross_runtime_files)
  get_filename_component(_runtime_name "${_runtime_file}" NAME)
  configure_file("${_runtime_file}" "${OUTPUT_DIR}/lib/${_runtime_name}" COPYONLY)
endforeach()
