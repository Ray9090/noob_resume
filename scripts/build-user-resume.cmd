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

pushd "%~dp0..\user-resources"
pdflatex -interaction=nonstopmode -output-directory="%OUTPUT_DIR%" custom_resume_template.tex
if not %ERRORLEVEL%==0 (
  echo ERROR: pdflatex failed. Check build\custom_resume_template.log for details.
  popd
  exit /b 1
)
pdflatex -interaction=nonstopmode -output-directory="%OUTPUT_DIR%" custom_resume_template.tex
if not %ERRORLEVEL%==0 (
  echo ERROR: pdflatex failed on rerun. Check build\custom_resume_template.log for details.
  popd
  exit /b 1
)
popd

echo ==^> User resume PDF built at build\custom_resume_template.pdf
exit /b 0

:add_latex_paths
if exist "C:\Program Files\MiKTeX\miktex\bin\x64" set "PATH=C:\Program Files\MiKTeX\miktex\bin\x64;%PATH%"
if exist "%LOCALAPPDATA%\Programs\MiKTeX\miktex\bin\x64" set "PATH=%LOCALAPPDATA%\Programs\MiKTeX\miktex\bin\x64;%PATH%"
if exist "C:\texlive\2026\bin\windows" set "PATH=C:\texlive\2026\bin\windows;%PATH%"
if exist "C:\texlive\2025\bin\windows" set "PATH=C:\texlive\2025\bin\windows;%PATH%"
if exist "C:\texlive\2024\bin\windows" set "PATH=C:\texlive\2024\bin\windows;%PATH%"
exit /b 0
