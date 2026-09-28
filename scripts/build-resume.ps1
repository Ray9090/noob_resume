$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$templateDir = Join-Path $repoRoot "resume-template"
$templateFile = Join-Path $templateDir "template_1.tex"
$outputDir = Join-Path $repoRoot "build"

if (-not (Get-Command pdflatex -ErrorAction SilentlyContinue)) {
    throw "pdflatex is not installed or not available in PATH. Run: powershell -ExecutionPolicy Bypass -File scripts/setup-latex.ps1"
}

if (-not (Test-Path $templateFile)) {
    throw "Template file not found: $templateFile"
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$jobName = "template_1_${timestamp}"

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

Push-Location $templateDir
try {
    for ($run = 1; $run -le 2; $run++) {
        pdflatex -interaction=nonstopmode -jobname="$jobName" -output-directory="$outputDir" template_1.tex
        if ($LASTEXITCODE -ne 0) {
            throw "pdflatex failed with exit code $LASTEXITCODE on run $run. Check build/$jobName.log for details."
        }
    }
}
finally {
    Pop-Location
}

Write-Host "==> Resume PDF built at build/$jobName.pdf"
