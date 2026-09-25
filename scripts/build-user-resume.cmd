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
if "%TEMPLATE_NAME%"=="" set "TEMPLATE_NAME=noob_resume_template.tex"

set "OUTPUT_DIR=%~dp0..\build"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

for /f "usebackq delims=" %%A in (`powershell.exe -NoProfile -Command "$scriptDir='%~dp0'; $repoRoot=Resolve-Path (Join-Path $scriptDir '..'); $outputDir=Join-Path $repoRoot 'build'; $template=Join-Path (Join-Path $repoRoot 'resume-template') '%TEMPLATE_NAME%'; $userInfo=Join-Path $repoRoot 'user-resources\user-info.tex'; $generated=Join-Path $outputDir 'custom_resume_template.tex'; if (-not (Test-Path $template)) { throw ('Template file not found: ' + $template) }; if (-not (Test-Path $userInfo)) { throw ('User info file not found: ' + $userInfo) }; $content=Get-Content -Raw $template; $pattern='(?s)%% <NOOB_PROFILE_START>.*?%% <NOOB_PROFILE_END>'; if ($content -notmatch $pattern) { throw 'Template profile block markers were not found.' }; $replacement='%% User-editable profile variables.' + [Environment]::NewLine + '\input{../user-resources/user-info.tex}'; $generatedContent=[regex]::Replace($content,$pattern,$replacement); Set-Content -Path $generated -Value $generatedContent -NoNewline; $raw=Get-Content -Raw $userInfo; $name='custom_resume'; if ($raw -match '\\newcommand\{\\ResumeName\}\{([^}]*)\}') { $name=$Matches[1] }; $safe=($name -replace '[^A-Za-z0-9]+','_').Trim('_'); if ([string]::IsNullOrWhiteSpace($safe)) { $safe='custom_resume' }; $stamp=Get-Date -Format 'yyyyMMdd-HHmmss'; Write-Output ($safe + '_' + $stamp)"`) do set "JOB_NAME=%%A"

if "%JOB_NAME%"=="" (
  echo ERROR: Could not generate build\custom_resume_template.tex.
  exit /b 1
)

pushd "%OUTPUT_DIR%"
pdflatex -interaction=nonstopmode -jobname="%JOB_NAME%" custom_resume_template.tex
if not %ERRORLEVEL%==0 (
  echo ERROR: pdflatex failed. Check build\%JOB_NAME%.log for details.
  popd
  exit /b 1
)
pdflatex -interaction=nonstopmode -jobname="%JOB_NAME%" custom_resume_template.tex
if not %ERRORLEVEL%==0 (
  echo ERROR: pdflatex failed on rerun. Check build\%JOB_NAME%.log for details.
  popd
  exit /b 1
)
popd

echo ==^> Generated build\custom_resume_template.tex from resume-template\%TEMPLATE_NAME%
echo ==^> User resume PDF built at build\%JOB_NAME%.pdf
exit /b 0

:add_latex_paths
if exist "C:\Program Files\MiKTeX\miktex\bin\x64" set "PATH=C:\Program Files\MiKTeX\miktex\bin\x64;%PATH%"
if exist "%LOCALAPPDATA%\Programs\MiKTeX\miktex\bin\x64" set "PATH=%LOCALAPPDATA%\Programs\MiKTeX\miktex\bin\x64;%PATH%"
if exist "C:\texlive\2026\bin\windows" set "PATH=C:\texlive\2026\bin\windows;%PATH%"
if exist "C:\texlive\2025\bin\windows" set "PATH=C:\texlive\2025\bin\windows;%PATH%"
if exist "C:\texlive\2024\bin\windows" set "PATH=C:\texlive\2024\bin\windows;%PATH%"
exit /b 0
