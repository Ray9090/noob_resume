@echo off
setlocal

if /I not "%OS%"=="Windows_NT" (
  echo ERROR: This setup script supports Windows only.
  exit /b 1
)

if /I not "%PROCESSOR_ARCHITECTURE%"=="AMD64" if /I not "%PROCESSOR_ARCHITEW6432%"=="AMD64" (
  echo ERROR: This setup script expects Windows x64.
  echo Detected PROCESSOR_ARCHITECTURE=%PROCESSOR_ARCHITECTURE%
  exit /b 1
)

echo ==^> Detected Windows x64 host

call :add_latex_paths

where pdflatex >nul 2>nul
if %ERRORLEVEL%==0 (
  echo ==^> pdflatex is already installed
  goto verify
)

where winget >nul 2>nul
if errorlevel 1 goto direct_miktex

echo ==^> Installing MiKTeX with winget
winget install --id MiKTeX.MiKTeX --exact --accept-package-agreements --accept-source-agreements
call :add_latex_paths
where pdflatex >nul 2>nul
if not errorlevel 1 goto verify
echo WARNING: winget did not make pdflatex available. Trying direct MiKTeX installer.
goto direct_miktex

:try_choco
where choco >nul 2>nul
if errorlevel 1 goto no_package_manager

net session >nul 2>nul
if errorlevel 1 (
  echo WARNING: Chocolatey is installed, but this shell is not elevated.
  echo WARNING: Skipping Chocolatey to avoid non-interactive admin or credential prompts.
  goto no_installer_available
)

echo ==^> Installing MiKTeX with Chocolatey
choco install miktex -y
if errorlevel 1 (
  echo ERROR: Chocolatey failed to install MiKTeX.
  exit /b 1
)
goto verify

:direct_miktex
if "%DIRECT_MIKTEX_TRIED%"=="1" goto no_installer_available
set "DIRECT_MIKTEX_TRIED=1"
set "MIKTEX_VERSION=25.12"
set "MIKTEX_SHA256=14b42dd9f4b4a7813a8bfd69c8f99316c2888cc4ee26f631f397e163d85d6c62"
set "MIKTEX_URL=https://miktex.org/download/ctan/systems/win32/miktex/setup/windows-x64/basic-miktex-25.12-x64.exe"
set "MIKTEX_INSTALLER=%TEMP%\basic-miktex-25.12-x64.exe"
set "MIKTEX_INSTALL_DIR=%LOCALAPPDATA%\Programs\MiKTeX"
set "MIKTEX_CONFIG_DIR=%APPDATA%\MiKTeX"
set "MIKTEX_DATA_DIR=%LOCALAPPDATA%\MiKTeX"

echo ==^> Downloading MiKTeX %MIKTEX_VERSION% x64 installer
powershell.exe -NoProfile -Command "Invoke-WebRequest -Uri '%MIKTEX_URL%' -OutFile '%MIKTEX_INSTALLER%'"
if errorlevel 1 (
  echo WARNING: Direct MiKTeX download failed. The host or corporate proxy may block downloaded .exe installers.
  echo WARNING: Trying Chocolatey only if this shell is elevated.
  goto try_choco
)

echo ==^> Verifying MiKTeX installer SHA-256
certutil -hashfile "%MIKTEX_INSTALLER%" SHA256 | findstr /I "%MIKTEX_SHA256%" >nul
if errorlevel 1 (
  echo ERROR: Downloaded MiKTeX installer hash did not match the expected SHA-256.
  echo Expected: %MIKTEX_SHA256%
  exit /b 1
)

echo ==^> Installing MiKTeX privately for the current user
"%MIKTEX_INSTALLER%" --unattended --private --user-install="%MIKTEX_INSTALL_DIR%" --user-config="%MIKTEX_CONFIG_DIR%" --user-data="%MIKTEX_DATA_DIR%"
if errorlevel 1 (
  echo ERROR: Direct MiKTeX installer failed.
  exit /b 1
)
goto verify

:no_package_manager
goto direct_miktex

:no_installer_available
echo ERROR: Could not install MiKTeX. winget failed, direct download failed, and Chocolatey was unavailable or unusable.
exit /b 1

:verify
call :add_latex_paths
where pdflatex >nul 2>nul
if not %ERRORLEVEL%==0 (
  echo ERROR: pdflatex was not found after setup.
  echo Restart your terminal or add the MiKTeX bin folder to PATH.
  exit /b 1
)

echo ==^> pdflatex version:
pdflatex --version
where initexmf >nul 2>nul
if not errorlevel 1 initexmf --set-config-value [MPM]AutoInstall=1

if /I "%1"=="--build" (
  echo WARNING: setup-latex.cmd no longer builds the PDF.
  echo WARNING: Run scripts\build-resume.cmd after setup completes.
)

echo ==^> LaTeX setup complete
exit /b 0

:add_latex_paths
if exist "C:\Program Files\MiKTeX\miktex\bin\x64" set "PATH=C:\Program Files\MiKTeX\miktex\bin\x64;%PATH%"
if exist "%LOCALAPPDATA%\Programs\MiKTeX\miktex\bin\x64" set "PATH=%LOCALAPPDATA%\Programs\MiKTeX\miktex\bin\x64;%PATH%"
if exist "C:\texlive\2026\bin\windows" set "PATH=C:\texlive\2026\bin\windows;%PATH%"
if exist "C:\texlive\2025\bin\windows" set "PATH=C:\texlive\2025\bin\windows;%PATH%"
if exist "C:\texlive\2024\bin\windows" set "PATH=C:\texlive\2024\bin\windows;%PATH%"
exit /b 0
