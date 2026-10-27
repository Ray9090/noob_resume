param(
    [string]$Template = "template_1.tex"
)

$ErrorActionPreference = "Stop"

$scriptRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptRoot)) {
    $scriptRoot = $env:NOOB_SCRIPT_DIR
}

$repoRoot = Resolve-Path (Join-Path $scriptRoot "..")
$templateDir = Join-Path $repoRoot "resume-template"
if ([string]::IsNullOrWhiteSpace($Template)) {
    $Template = "template_1.tex"
}
if ([System.IO.Path]::GetExtension($Template) -eq "") {
    $Template = "$Template.tex"
}
$templateFile = Join-Path $templateDir $Template
$outputDir = Join-Path $repoRoot "build"

if (-not (Test-Path $templateFile)) {
    $availableTemplates = Get-ChildItem $templateDir -Filter "*.tex" | ForEach-Object { $_.Name }
    throw "Template file not found: $templateFile. Available templates: $($availableTemplates -join ', ')"
}
$templateContent = Get-Content -Raw $templateFile
$latexEngine = if ($templateContent -match '\\documentclass(?:\[[^]]*\])?\{arthur-cv\}') { 'lualatex' } else { 'pdflatex' }
if (-not (Get-Command $latexEngine -ErrorAction SilentlyContinue)) {
    throw "$latexEngine is not installed or not available in PATH. Run: scripts/setup-latex.cmd"
}

$templateBaseName = [System.IO.Path]::GetFileNameWithoutExtension($Template)
$safeTemplateName = ($templateBaseName -replace "[^A-Za-z0-9]+", "_").Trim("_")
if ([string]::IsNullOrWhiteSpace($safeTemplateName)) {
    $safeTemplateName = "template"
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$jobName = "${safeTemplateName}_${timestamp}"

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

Push-Location $templateDir
try {
    for ($run = 1; $run -le 2; $run++) {
        & $latexEngine -interaction=nonstopmode -halt-on-error -jobname="$jobName" -output-directory="$outputDir" $Template
        if ($LASTEXITCODE -ne 0) {
            throw "$latexEngine failed with exit code $LASTEXITCODE on run $run. Check build/$jobName.log for details."
        }
    }
}
finally {
    Pop-Location
}

Write-Host "==> Template: resume-template/$Template"
Write-Host "==> Resume PDF built at build/$jobName.pdf"
