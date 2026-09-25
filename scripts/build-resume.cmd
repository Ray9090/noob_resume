@echo off
setlocal

call :add_latex_paths

where pdflatex >nul 2>nul
if not %ERRORLEVEL%==0 (
  echo ERROR: pdflatex is not installed or not available in PATH.
  echo Run: scripts\setup-latex.cmd
  exit /b 1
)

set "OUTPUT_DIR=%~dp0..\build"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

for /f "usebackq delims=" %%A in (`powershell.exe -NoProfile -Command "Get-Date -Format 'yyyyMMdd-HHmmss'"`) do set "STAMP=%%A"
set "JOB_NAME=noob_resume_template_%STAMP%"

pushd "%~dp0..\resume-template"
pdflatex -interaction=nonstopmode -jobname="%JOB_NAME%" -output-directory="%OUTPUT_DIR%" noob_resume_template.tex
if not %ERRORLEVEL%==0 (
  echo ERROR: pdflatex failed. Check build\%JOB_NAME%.log for details.
  popd
  exit /b 1
)
pdflatex -interaction=nonstopmode -jobname="%JOB_NAME%" -output-directory="%OUTPUT_DIR%" noob_resume_template.tex
if not %ERRORLEVEL%==0 (
  echo ERROR: pdflatex failed on rerun. Check build\%JOB_NAME%.log for details.
  popd
  exit /b 1
)
popd

echo ==^> Resume PDF built at build\%JOB_NAME%.pdf
exit /b 0

:add_latex_paths
if exist "C:\Program Files\MiKTeX\miktex\bin\x64" set "PATH=C:\Program Files\MiKTeX\miktex\bin\x64;%PATH%"
if exist "%LOCALAPPDATA%\Programs\MiKTeX\miktex\bin\x64" set "PATH=%LOCALAPPDATA%\Programs\MiKTeX\miktex\bin\x64;%PATH%"
if exist "C:\texlive\2026\bin\windows" set "PATH=C:\texlive\2026\bin\windows;%PATH%"
if exist "C:\texlive\2025\bin\windows" set "PATH=C:\texlive\2025\bin\windows;%PATH%"
if exist "C:\texlive\2024\bin\windows" set "PATH=C:\texlive\2024\bin\windows;%PATH%"
exit /b 0
