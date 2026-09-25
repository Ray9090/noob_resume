@echo off
setlocal

call :add_latex_paths

where pdflatex >nul 2>nul
if not %ERRORLEVEL%==0 (
  echo ERROR: pdflatex is not installed or not available in PATH.
  echo Run: scripts\setup-latex.cmd
  exit /b 1
)

set "SOURCE_NAME=%~1"
if "%SOURCE_NAME%"=="" set "SOURCE_NAME=user-info"

set "TEMPLATE_NAME=%~2"
if /I "%SOURCE_NAME:~-4%"==".tex" (
  set "TEMPLATE_NAME=%SOURCE_NAME%"
  set "SOURCE_NAME=user-info"
)
if "%TEMPLATE_NAME%"=="" set "TEMPLATE_NAME=noob_resume_template.tex"

set "NOOB_SCRIPT_DIR=%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$script = Get-Content -Raw '%~dp0build-user-resume.ps1'; $block = [scriptblock]::Create($script); & $block -Source '%SOURCE_NAME%' -Template '%TEMPLATE_NAME%'"
exit /b %ERRORLEVEL%

:add_latex_paths
if exist "C:\Program Files\MiKTeX\miktex\bin\x64" set "PATH=C:\Program Files\MiKTeX\miktex\bin\x64;%PATH%"
if exist "%LOCALAPPDATA%\Programs\MiKTeX\miktex\bin\x64" set "PATH=%LOCALAPPDATA%\Programs\MiKTeX\miktex\bin\x64;%PATH%"
if exist "C:\texlive\2026\bin\windows" set "PATH=C:\texlive\2026\bin\windows;%PATH%"
if exist "C:\texlive\2025\bin\windows" set "PATH=C:\texlive\2025\bin\windows;%PATH%"
if exist "C:\texlive\2024\bin\windows" set "PATH=C:\texlive\2024\bin\windows;%PATH%"
exit /b 0
