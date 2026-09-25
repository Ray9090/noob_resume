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

set "OUTPUT_DIR=%~dp0..\build"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

for /f "usebackq delims=" %%A in (`powershell.exe -NoProfile -Command "$source='%SOURCE_NAME%'; if (($source -ne 'user-info') -and ($source -ne 'linkedin')) { throw 'Source must be user-info or linkedin.' }; $scriptDir='%~dp0'; $repoRoot=Resolve-Path (Join-Path $scriptDir '..'); $outputDir=Join-Path $repoRoot 'build'; $template=Join-Path (Join-Path $repoRoot 'resume-template') '%TEMPLATE_NAME%'; $userInfo=Join-Path $repoRoot 'user-resources\user-info.tex'; $linkedInProfile=Join-Path $repoRoot 'user-resources\linkedin-profile.json'; $generated=Join-Path $outputDir 'custom_resume_template.tex'; $generatedProfile=Join-Path $outputDir 'profile-info.tex'; if (-not (Test-Path $template)) { throw ('Template file not found: ' + $template) }; if ($source -eq 'user-info' -and -not (Test-Path $userInfo)) { throw ('User info file not found: ' + $userInfo) }; if ($source -eq 'linkedin' -and -not (Test-Path $linkedInProfile)) { throw ('LinkedIn profile file not found: ' + $linkedInProfile) }; $content=Get-Content -Raw $template; $pattern='(?s)%% <NOOB_PROFILE_START>.*?%% <NOOB_PROFILE_END>'; if ($content -notmatch $pattern) { throw 'Template profile block markers were not found.' }; $name='custom_resume'; if ($source -eq 'user-info') { $replacement='%% User-editable profile variables.' + [Environment]::NewLine + '\input{../user-resources/user-info.tex}'; $raw=Get-Content -Raw $userInfo; if ($raw -match '\\newcommand\{\\ResumeName\}\{([^}]*)\}') { $name=$Matches[1] } } else { $profile=Get-Content -Raw $linkedInProfile | ConvertFrom-Json; if ($profile.name) { $name=$profile.name }; function esc($v) { if ($null -eq $v) { return '' }; $e=[string]$v; $e=$e.Replace('\','\textbackslash{}'); $e=$e.Replace('&','\&'); $e=$e.Replace('%%','\%%'); $e=$e.Replace('$','\$'); $e=$e.Replace('#','\#'); $e=$e.Replace('_','\_'); $e=$e.Replace('{','\{'); $e=$e.Replace('}','\}'); return $e }; $lines=@('%% Generated from user-resources/linkedin-profile.json','\newcommand{\ResumeName}{' + (esc $profile.name) + '}','\newcommand{\ResumePhoneDisplay}{' + (esc $profile.phoneDisplay) + '}','\newcommand{\ResumePhoneLink}{' + (esc $profile.phoneLink) + '}','\newcommand{\ResumeEmail}{' + (esc $profile.email) + '}','\newcommand{\ResumeLinkedInDisplay}{' + (esc $profile.linkedinDisplay) + '}','\newcommand{\ResumeLinkedInUrl}{' + (esc $profile.linkedinUrl) + '}','\newcommand{\ResumeGitHubDisplay}{' + (esc $profile.githubDisplay) + '}','\newcommand{\ResumeGitHubUrl}{' + (esc $profile.githubUrl) + '}'); Set-Content -Path $generatedProfile -Value ($lines -join [Environment]::NewLine) -NoNewline; $replacement='%% User-editable profile variables.' + [Environment]::NewLine + '\input{profile-info.tex}' }; $generatedContent=[regex]::Replace($content,$pattern,$replacement); Set-Content -Path $generated -Value $generatedContent -NoNewline; $safe=($name -replace '[^A-Za-z0-9]+','_').Trim('_'); if ([string]::IsNullOrWhiteSpace($safe)) { $safe='custom_resume' }; $stamp=Get-Date -Format 'yyyyMMdd-HHmmss'; Write-Output ($safe + '_' + $stamp)"`) do set "JOB_NAME=%%A"

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
echo ==^> Source: %SOURCE_NAME%
echo ==^> User resume PDF built at build\%JOB_NAME%.pdf
exit /b 0

:add_latex_paths
if exist "C:\Program Files\MiKTeX\miktex\bin\x64" set "PATH=C:\Program Files\MiKTeX\miktex\bin\x64;%PATH%"
if exist "%LOCALAPPDATA%\Programs\MiKTeX\miktex\bin\x64" set "PATH=%LOCALAPPDATA%\Programs\MiKTeX\miktex\bin\x64;%PATH%"
if exist "C:\texlive\2026\bin\windows" set "PATH=C:\texlive\2026\bin\windows;%PATH%"
if exist "C:\texlive\2025\bin\windows" set "PATH=C:\texlive\2025\bin\windows;%PATH%"
if exist "C:\texlive\2024\bin\windows" set "PATH=C:\texlive\2024\bin\windows;%PATH%"
exit /b 0
