# Building Savage Wind on Windows on ARM (ARM64)

Community port. Savage Wind is by Revivedx and the Savage Wind Recomp contributors, built on LAS Recomp by Peiikai
(see [LICENSE](../LICENSE)); this port adds a native Windows ARM64 build next to the x86-64 one in
[BUILD-windows.md](BUILD-windows.md). Read that guide first: everything there applies, except what is listed here.

Tested on Windows 11 ARM64 (NVIDIA RTX Spark N1X). Needs Windows 11 on ARM64 and a GPU driver with Vulkan 1.3.

## One-time setup
Run in PowerShell from the repo root (the same script as x86-64; on an ARM64 PC it picks the ARM64 packages):

    powershell -ExecutionPolicy Bypass -File tools\setup_windows.ps1

It installs MSYS2 with the **CLANGARM64** packages (native ARM64 clang, lld, SDL3, FFmpeg, Vulkan loader and headers,
shaderc, Vulkan Memory Allocator) and an **x64** Python 3.12 for `tools\venv`: unicorn and capstone publish no
`win_arm64` wheels, so the generator runs under Windows' x64 emulation. It is an offline tool; the game itself is
native ARM64.

## Build
From an MSYS2 CLANGARM64 shell (`C:\msys64\clangarm64.exe`), or any shell with
`C:\msys64\clangarm64\bin;C:\msys64\usr\bin` first on PATH:

    make gen        # once: recompile the game from extracted/exefs (your own game files)
    make -j         # -> build/savagewind.exe and build/swgame.dll, both ARM64

The Makefile tells the target from the compiler (`clang -dumpmachine` = `aarch64-w64-windows-gnu`: `WINARCH=aarch64`).
Run from a shell with `C:\msys64\clangarm64\bin` on PATH (SDL3, FFmpeg, shaderc DLLs).

## Package
The same steps as x86-64 (`make deps-windows`, `make gen-helper`, `tools/fetch_zig.sh`, `make dist`). On ARM64:

- `make dist` writes `build/dist/SavageWind-<version>-windows-arm64.zip`.
- `tools/fetch_zig.sh` fetches zig for `aarch64-windows`, so the start screen builds the game code natively.
- `make gen-helper` freezes the generator with the x64 Python above: `swgen.exe` is x64 and runs emulated.

## Differences from x86-64 Windows
- Game code: the guest's FP/SIMD instructions run as AArch64 inline asm (`gen.py --simd asm`, as on macOS and Linux
  arm64) instead of the portable C of `simd.h`. No `-march=x86-64-v3` / compatible target: one game code library.
- DLSS: off. NVIDIA's SDK ships x86-64 libraries only. FSR and the other upscalers are unchanged.
- Updates: Savage Wind Configuration only looks for a `-windows-arm64.zip` release, never the x64 zip. Upstream
  publishes none, so no update is offered; install a newer port release by hand.
- Crash reports give pc and lr from the ARM64 context. The debug data watchpoint can't single-step on ARM64 (no trap
  flag): it reports the first access to a watched page only.
- The Windows profilers (`prof_sampler.c`, `sampler.c`) record the leaf and its caller (pc, lr) instead of a full
  unwind.
