param(
    [ValidateSet("user-info", "linkedin")]
    [string]$Source = "user-info",
    [string]$Template = "noob_resume_template.tex"
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$templateDir = Join-Path $repoRoot "resume-template"
$sourceTemplate = Join-Path $templateDir $Template
$userInfoFile = Join-Path $repoRoot "user-resources\user-info.tex"
$linkedInProfileFile = Join-Path $repoRoot "user-resources\linkedin-profile.json"
$outputDir = Join-Path $repoRoot "build"
$generatedTemplate = Join-Path $outputDir "custom_resume_template.tex"
$generatedProfile = Join-Path $outputDir "profile-info.tex"

if (-not (Get-Command pdflatex -ErrorAction SilentlyContinue)) {
    throw "pdflatex is not installed or not available in PATH. Run: powershell -ExecutionPolicy Bypass -File scripts/setup-latex.ps1"
}

if (-not (Test-Path $sourceTemplate)) {
    throw "Template file not found: $sourceTemplate"
}

if ($Source -eq "user-info" -and -not (Test-Path $userInfoFile)) {
    throw "User info file not found: $userInfoFile"
}

if ($Source -eq "linkedin" -and -not (Test-Path $linkedInProfileFile)) {
    throw "LinkedIn profile file not found: $linkedInProfileFile"
}

$resumeName = "custom_resume"
if ($Source -eq "user-info") {
    $userInfo = Get-Content -Raw $userInfoFile
    if ($userInfo -match "\\newcommand\{\\ResumeName\}\{([^}]*)\}") {
        $resumeName = $Matches[1]
    }
}
else {
    $linkedInProfile = Get-Content -Raw $linkedInProfileFile | ConvertFrom-Json
    if ($linkedInProfile.name) {
        $resumeName = $linkedInProfile.name
    }
}

$safeName = ($resumeName -replace "[^A-Za-z0-9]+", "_").Trim("_")
if ([string]::IsNullOrWhiteSpace($safeName)) {
    $safeName = "custom_resume"
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$jobName = "${safeName}_${timestamp}"

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

$templateContent = Get-Content -Raw $sourceTemplate
$profilePattern = "(?s)% <NOOB_PROFILE_START>.*?% <NOOB_PROFILE_END>"
$profileReplacement = "% User-editable profile variables."

if ($Source -eq "user-info") {
    $profileReplacement += [Environment]::NewLine + "\input{../user-resources/user-info.tex}"
}
else {
    function ConvertTo-LatexValue {
        param([AllowNull()][string]$Value)

        if ($null -eq $Value) {
            return ""
        }

        $escaped = $Value.Replace("\", "\textbackslash{}")
        $escaped = $escaped.Replace("&", "\&")
        $escaped = $escaped.Replace("%", "\%")
        $escaped = $escaped.Replace("$", "\$")
        $escaped = $escaped.Replace("#", "\#")
        $escaped = $escaped.Replace("_", "\_")
        $escaped = $escaped.Replace("{", "\{")
        $escaped = $escaped.Replace("}", "\}")
        return $escaped
    }

    $profileLines = @(
        "% Generated from user-resources/linkedin-profile.json",
        "\newcommand{\ResumeName}{$(ConvertTo-LatexValue $linkedInProfile.name)}",
        "\newcommand{\ResumePhoneDisplay}{$(ConvertTo-LatexValue $linkedInProfile.phoneDisplay)}",
        "\newcommand{\ResumePhoneLink}{$(ConvertTo-LatexValue $linkedInProfile.phoneLink)}",
        "\newcommand{\ResumeEmail}{$(ConvertTo-LatexValue $linkedInProfile.email)}",
        "\newcommand{\ResumeLinkedInDisplay}{$(ConvertTo-LatexValue $linkedInProfile.linkedinDisplay)}",
        "\newcommand{\ResumeLinkedInUrl}{$(ConvertTo-LatexValue $linkedInProfile.linkedinUrl)}",
        "\newcommand{\ResumeGitHubDisplay}{$(ConvertTo-LatexValue $linkedInProfile.githubDisplay)}",
        "\newcommand{\ResumeGitHubUrl}{$(ConvertTo-LatexValue $linkedInProfile.githubUrl)}"
    )
    Set-Content -Path $generatedProfile -Value ($profileLines -join [Environment]::NewLine) -NoNewline
    $profileReplacement += [Environment]::NewLine + "\input{profile-info.tex}"
}

if ($templateContent -notmatch $profilePattern) {
    throw "Template profile block markers were not found in $sourceTemplate. Add % <NOOB_PROFILE_START> and % <NOOB_PROFILE_END> around the profile defaults."
}

$generatedContent = [regex]::Replace($templateContent, $profilePattern, $profileReplacement)
Set-Content -Path $generatedTemplate -Value $generatedContent -NoNewline

Push-Location $outputDir
try {
    for ($run = 1; $run -le 2; $run++) {
        pdflatex -interaction=nonstopmode -jobname="$jobName" custom_resume_template.tex
        if ($LASTEXITCODE -ne 0) {
            throw "pdflatex failed with exit code $LASTEXITCODE on run $run. Check build/$jobName.log for details."
        }
    }
}
finally {
    Pop-Location
}

Write-Host "==> Source: $Source"
Write-Host "==> Generated build/custom_resume_template.tex from resume-template/$Template"
Write-Host "==> User resume PDF built at build/$jobName.pdf"
