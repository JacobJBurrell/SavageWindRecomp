# One-time setup of a Windows machine for building Savage Wind (see docs/BUILD-windows.md).
# Installs MSYS2 (clang, lld, make, SDL3, FFmpeg, Vulkan loader/headers, shaderc) and Python 3.12, then creates
# tools/venv (lifter: unicorn, capstone, lz4). Safe to re-run.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

if (-not (Test-Path C:\msys64\usr\bin\pacman.exe)) {
    winget install --id MSYS2.MSYS2 -e --accept-source-agreements --accept-package-agreements --silent
}
# Windows on ARM: MSYS2's CLANGARM64 packages (native ARM64 clang, SDL3, Vulkan, FFmpeg); x64: UCRT64
$arm = $env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64'
$env:MSYSTEM = if ($arm) { 'CLANGARM64' } else { 'UCRT64' }
$pre = if ($arm) { 'mingw-w64-clang-aarch64' } else { 'mingw-w64-ucrt-x86_64' }
$env:CHERE_INVOKING = '1'
$bash = 'C:\msys64\usr\bin\bash.exe'
& $bash -lc 'pacman -Syuu --noconfirm' | Out-Null
& $bash -lc 'pacman -Syuu --noconfirm' | Out-Null  # second pass after a core update
$pkgs = @('make', 'zip', 'unzip') + (('clang', 'lld', 'sdl3', 'ffmpeg', 'vulkan-headers', 'vulkan-loader', 'shaderc',
        'spirv-tools', 'pkgconf', 'vulkan-memory-allocator', 'vulkan-validation-layers', 'zlib',
        'nasm'  # (make deps-windows: FFmpeg's VP9 assembly)
        ) | ForEach-Object { "$pre-$_" })
if (-not $arm) { $pkgs += "$pre-gdb" }  # (no gdb for CLANGARM64: lldb comes with its clang)
& $bash -lc "pacman -S --needed --noconfirm $($pkgs -join ' ')"

# Python for the tools: the python.org build (prebuilt unicorn / capstone wheels; MSYS2's Python can't build them)
$py = "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe"
if (-not (Test-Path $py)) {
    # (x64 on ARM too: unicorn and capstone have no win_arm64 wheels; Windows runs it emulated)
    winget install --id Python.Python.3.12 -e --architecture x64 --scope user --accept-source-agreements --accept-package-agreements --silent
}
if (-not (Test-Path "$root\tools\venv\Scripts\python.exe")) { & $py -m venv "$root\tools\venv" }
& "$root\tools\venv\Scripts\python.exe" -m pip install -q lz4 capstone unicorn

# LF line endings in this clone (the bash tools break with CRLF; Git for Windows defaults to autocrlf=true)
git -C $root config core.autocrlf false
git -C $root config core.eol lf
$envdir = $env:MSYSTEM.ToLower()
Write-Host "Done. Build from an MSYS2 $($env:MSYSTEM) shell (or put C:\msys64\$envdir\bin;C:\msys64\usr\bin first on PATH): make -j"
