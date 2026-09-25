$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$templateDir = Join-Path $repoRoot "user-resources"
$templateFile = Join-Path $templateDir "custom_resume_template.tex"
$outputDir = Join-Path $repoRoot "build"

if (-not (Get-Command pdflatex -ErrorAction SilentlyContinue)) {
    throw "pdflatex is not installed or not available in PATH. Run: powershell -ExecutionPolicy Bypass -File scripts/setup-latex.ps1"
}

if (-not (Test-Path $templateFile)) {
    throw "Template file not found: $templateFile"
}

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

Push-Location $templateDir
try {
    for ($run = 1; $run -le 2; $run++) {
        pdflatex -interaction=nonstopmode -output-directory="$outputDir" custom_resume_template.tex
        if ($LASTEXITCODE -ne 0) {
            throw "pdflatex failed with exit code $LASTEXITCODE on run $run. Check build/custom_resume_template.log for details."
        }
    }
}
finally {
    Pop-Location
}

Write-Host "==> User resume PDF built at build/custom_resume_template.pdf"
