# TinyCC Windows packages

This wrapper builds three isolated TinyCC packages from the `tinycc` submodule:

| Preset | Host compiler | TinyCC output target | Compatibility |
|---|---|---|---|
| `x86-debug` / `x86-release` | x64 TinyCC bootstrap | native i386 PE | Windows XP and newer |
| `x64-msvc` | MSVC | x86-64 PE | 64-bit Windows |
| `arm64-msvc` | MSVC | ARM64 PE | Windows on ARM |

The x64 and ARM64 packages contain x64-hosted TinyCC executables. The ARM64
package's `tcc.exe` emits ARM64 code; it does not itself run natively on ARM64.
Every package also contains `i386-win32-tcc.exe`, `x86_64-win32-tcc.exe`, and
`arm64-win32-tcc.exe`. These explicitly named compilers run on the package's
host architecture and emit/link complete Windows programs for their named
target using the included prefixed runtime libraries.

## Install with WPM

From an elevated PowerShell session, add the GitHub latest-release assets as a
WPM repository, refresh the package index, and install the package selected for
the current Windows architecture:

```powershell
wpm repo add https://github.com/Thewafflication/tcc_package/releases/latest/download
wpm update
wpm install tinycc
```

Before the first installation, download and trust the published release key if
it is not already present in the machine trust store:

```powershell
Invoke-WebRequest https://github.com/Thewafflication/tcc_package/releases/latest/download/wpm-release.public -OutFile wpm-release.public
wpm trust add wpm-release.public
```

## Prerequisites

- CMake 3.21 or newer and Ninja
- Visual Studio 2022 or newer with the MSVC x64 tools

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
The x86 build first uses MSVC to create an x64-hosted i386 cross-compiler,
then uses that cross-compiler to build the final native i386 TinyCC package.
TinyCC's i386 PE backend declares a Windows 4.0 OS/subsystem baseline, which
remains compatible with Windows XP and modern Windows through WOW64.

Each build also creates a signed WPM archive in `out/packages`. Its version
and metadata are derived from the TinyCC submodule's Git state, `VERSION`,
`README`, `COPYING`, and `origin` remote. Installed architectures coexist in
`%ProgramFiles%\TinyCC\<version>`, allowing multiple compiler versions to
coexist. `TCC_HOME` points to the most recently installed version; no ambiguous
`tcc.exe` entry is added to the global `PATH`. Packages are signed with
`%ProgramData%\WPM\wpm-release.private` by default; override `WPM_SIGNING_KEY`
when configuring if a different key is required.

GitHub Actions builds unsigned `*-debug` WPM archives for branch pushes and
pull requests. Release builds use the protected GitHub `release` environment
and require its `WPM_RELEASE_PRIVATE_KEY` secret. The private key exists only
in the runner's temporary directory while the package is built. Signed
packages are verified against `release_keys/wpm-release.public`.

Pushing a `v*` tag publishes all three Release packages, the public key, and a
WPM version 1 `index.json` to the corresponding GitHub Release. You can also
run the workflow manually with `flavor=release` and a new `release_tag`; the
workflow creates the tag and release at the selected commit.
