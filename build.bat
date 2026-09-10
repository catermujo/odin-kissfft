@echo off
setlocal EnableDelayedExpansion

set "REVISION=e5e3fac46e0d94a8f8170c06706b7a4218828333"
set "REMOTE=https://github.com/mborgerding/kissfft.git"
set "BASE=%~dp0"
set "SOURCE_DIR=%BASE%kissfft"
set "VENDOR_WINDOWS_ARCH=%VSCMD_ARG_TGT_ARCH%"
if not defined VENDOR_WINDOWS_ARCH set "VENDOR_WINDOWS_ARCH=%PROCESSOR_ARCHITECTURE%"
if /I "%VENDOR_WINDOWS_ARCH%"=="AMD64" set "VENDOR_WINDOWS_ARCH=x64"
if /I "%VENDOR_WINDOWS_ARCH%"=="ARM64" set "VENDOR_WINDOWS_ARCH=arm64"
if /I "%VENDOR_WINDOWS_ARCH%"=="X86" set "VENDOR_WINDOWS_ARCH=x64"
if /I not "%VENDOR_WINDOWS_ARCH%"=="x64" if /I not "%VENDOR_WINDOWS_ARCH%"=="arm64" (
    echo Unsupported Windows architecture: %VENDOR_WINDOWS_ARCH% 1>&2
    exit /b 1
)

where git >nul 2>&1 || (echo Missing required command: git 1>&2 & exit /b 1)
where cl >nul 2>&1 || (echo Missing required command: cl 1>&2 & exit /b 1)
where lib >nul 2>&1 || (echo Missing required command: lib 1>&2 & exit /b 1)

if exist "%SOURCE_DIR%\.git\" goto source_ready
if exist "%SOURCE_DIR%" (
    echo KISS FFT source path exists but is not a git checkout: %SOURCE_DIR% 1>&2
    exit /b 1
)
git clone --no-checkout "%REMOTE%" "%SOURCE_DIR%" || exit /b 1
git -C "%SOURCE_DIR%" checkout --detach "%REVISION%" || exit /b 1

:source_ready
for /f "delims=" %%I in ('git -C "%SOURCE_DIR%" rev-parse HEAD') do set "SOURCE_COMMIT=%%I"
if /I not "%SOURCE_COMMIT%"=="%REVISION%" (
    echo KISS FFT source checkout does not match pinned commit: %REVISION% 1>&2
    exit /b 1
)
set "SOURCE_DIRTY="
for /f "delims=" %%I in ('git -C "%SOURCE_DIR%" status --porcelain --untracked-files=no') do set "SOURCE_DIRTY=1"
if defined SOURCE_DIRTY (
    echo KISS FFT source checkout has staged or unstaged tracked modifications 1>&2
    exit /b 1
)

set "BUILD_DIR=%BASE%build_windows_%VENDOR_WINDOWS_ARCH%"
set "OUTPUT_DIR=%BASE%windows_%VENDOR_WINDOWS_ARCH%"
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
cl /nologo /std:c11 /O2 /Brepro /DNDEBUG /I"%BASE%" /c "%BASE%bridge_f32.c" /Fo"%BUILD_DIR%\bridge_f32.obj" || exit /b 1
cl /nologo /std:c11 /O2 /Brepro /DNDEBUG /I"%BASE%" /c "%BASE%bridge_f64.c" /Fo"%BUILD_DIR%\bridge_f64.obj" || exit /b 1
lib /nologo /Brepro /OUT:"%OUTPUT_DIR%\kissfft.lib" "%BUILD_DIR%\bridge_f32.obj" "%BUILD_DIR%\bridge_f64.obj" || exit /b 1

echo KISS FFT static build completed successfully!
exit /b 0
