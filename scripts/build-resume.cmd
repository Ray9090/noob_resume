@echo off
setlocal

call :add_latex_paths

where pdflatex >nul 2>nul
if not %ERRORLEVEL%==0 (
  echo ERROR: pdflatex is not installed or not available in PATH.
  echo Run: scripts\setup-latex.cmd
  exit /b 1
)

set "TEMPLATE_NAME=%~1"
if "%TEMPLATE_NAME%"=="" set "TEMPLATE_NAME=template_1.tex"

if /I "%TEMPLATE_NAME%"=="templates" goto :list_templates
if /I "%TEMPLATE_NAME%"=="--list-templates" goto :list_templates
if /I "%TEMPLATE_NAME%"=="/list-templates" goto :list_templates

set "NOOB_SCRIPT_DIR=%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$script = Get-Content -Raw '%~dp0build-resume.ps1'; $block = [scriptblock]::Create($script); & $block -Template '%TEMPLATE_NAME%'"
exit /b %ERRORLEVEL%

:list_templates
echo Available templates:
for %%F in ("%~dp0..\resume-template\*.tex") do echo   %%~nxF
exit /b 0

:add_latex_paths
if exist "C:\Program Files\MiKTeX\miktex\bin\x64" set "PATH=C:\Program Files\MiKTeX\miktex\bin\x64;%PATH%"
if exist "%LOCALAPPDATA%\Programs\MiKTeX\miktex\bin\x64" set "PATH=%LOCALAPPDATA%\Programs\MiKTeX\miktex\bin\x64;%PATH%"
if exist "C:\texlive\2026\bin\windows" set "PATH=C:\texlive\2026\bin\windows;%PATH%"
if exist "C:\texlive\2025\bin\windows" set "PATH=C:\texlive\2025\bin\windows;%PATH%"
if exist "C:\texlive\2024\bin\windows" set "PATH=C:\texlive\2024\bin\windows;%PATH%"
exit /b 0