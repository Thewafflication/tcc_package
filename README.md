# TinyCC Windows packages

This wrapper builds three isolated TinyCC packages from the `tinycc` submodule:

| Preset | Host compiler | TinyCC output target | Compatibility |
|---|---|---|---|
| `x86-winxp-mingw` | 32-bit MinGW GCC | i386 PE | Windows XP (5.1) |
| `x64-msvc` | MSVC | x86-64 PE | 64-bit Windows |
| `arm64-msvc` | MSVC | ARM64 PE | Windows on ARM |

The x64 and ARM64 packages contain x64-hosted TinyCC executables. The ARM64
package's `tcc.exe` emits ARM64 code; it does not itself run natively on ARM64.

## Prerequisites

- CMake 3.21 or newer and Ninja
- Visual Studio 2022 or newer with the MSVC x64 tools
- A 32-bit MinGW-w64 GCC (`i686-w64-mingw32-gcc`) on `PATH` for the XP build

## Build

```powershell
cmake --preset x86-release
cmake --build --preset x86-release

cmake --preset x64-release
cmake --build --preset x64-release

cmake --preset arm64-release
cmake --build --preset arm64-release
```

Each completed package is written beneath `out/build/<preset>/package`.
The MinGW package is statically linked, defines the Windows XP API baseline,
and requests PE subsystem version 5.1. TinyCC's own i386 PE backend uses an
even older 4.0 OS/subsystem baseline for programs it generates.

Each build also creates a signed WPM archive in `out/packages`. Its version
and metadata are derived from the TinyCC submodule's Git state, `VERSION`,
`README`, `COPYING`, and `origin` remote. Installed architectures coexist in
`%ProgramFiles%\TinyCC\<version>`, allowing multiple compiler versions to
coexist. `TCC_HOME` points to the most recently installed version; no ambiguous
`tcc.exe` entry is added to the global `PATH`. Packages are signed with
`%ProgramData%\WPM\wpm-release.private` by default; override `WPM_SIGNING_KEY`
when configuring if a different key is required.

GitHub Actions builds `*-debug` WPM archives for branch pushes and pull
requests, and release archives for tags matching `v*`. Configure the
`WPM_SIGNING_PRIVATE_KEY` repository secret with the contents of the WPM
private key. Debug CI artifacts may be unsigned when secrets are unavailable;
tagged release builds require the signing secret.
