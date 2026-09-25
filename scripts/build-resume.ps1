$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$templateDir = Join-Path $repoRoot "resume-template"
$templateFile = Join-Path $templateDir "noob_resume_template.tex"
$userInfoFile = Join-Path $repoRoot "user-resources\user-info.tex"
$outputDir = Join-Path $repoRoot "build"

if (-not (Get-Command pdflatex -ErrorAction SilentlyContinue)) {
    throw "pdflatex is not installed or not available in PATH. Run: powershell -ExecutionPolicy Bypass -File scripts/setup-latex.ps1"
}

if (-not (Test-Path $templateFile)) {
    throw "Template file not found: $templateFile"
}

if (-not (Test-Path $userInfoFile)) {
    throw "User info file not found: $userInfoFile"
}

$userInfo = Get-Content -Raw $userInfoFile
$resumeName = "noob_resume"
if ($userInfo -match "\\newcommand\{\\ResumeName\}\{([^}]*)\}") {
    $resumeName = $Matches[1]
}

$safeName = ($resumeName -replace "[^A-Za-z0-9]+", "_").Trim("_")
if ([string]::IsNullOrWhiteSpace($safeName)) {
    $safeName = "noob_resume"
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$jobName = "${safeName}_${timestamp}"

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

Push-Location $templateDir
try {
    for ($run = 1; $run -le 2; $run++) {
        pdflatex -interaction=nonstopmode -jobname="$jobName" -output-directory="$outputDir" noob_resume_template.tex
        if ($LASTEXITCODE -ne 0) {
            throw "pdflatex failed with exit code $LASTEXITCODE on run $run. Check build/$jobName.log for details."
        }
    }
}
finally {
    Pop-Location
}

Write-Host "==> Resume PDF built at build/$jobName.pdf"
