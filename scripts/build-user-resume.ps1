param(
    [ValidateSet("user-info", "linkedin")]
    [string]$Source = "user-info",
    [string]$Template = "noob_resume_template.tex"
)

$ErrorActionPreference = "Stop"

$scriptRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptRoot)) {
    $scriptRoot = $env:NOOB_SCRIPT_DIR
}

$repoRoot = Resolve-Path (Join-Path $scriptRoot "..")
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
$contentPattern = "(?s)% <NOOB_CONTENT_START>.*?% <NOOB_CONTENT_END>"
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

    function Add-ResumeItems {
        param([System.Collections.IEnumerable]$Items)

        $lines = @("      \resumeItemListStart")
        foreach ($item in $Items) {
            $lines += "        \resumeItem{$(ConvertTo-LatexValue $item)}"
        }
        $lines += "      \resumeItemListEnd"
        return $lines
    }

    function ConvertTo-LinkedInContent {
        param($Profile)

        $lines = @(
            "% <NOOB_CONTENT_START>",
            "% Generated from user-resources/linkedin-profile.json",
            "%-----------SUMMARY-----------",
            "\section{Professional Summary}",
            "\begin{justify}",
            "\small{$(ConvertTo-LatexValue $Profile.summary)}",
            "\end{justify}",
            "\vspace{-10pt}",
            "",
            "%-----------TECHNICAL SKILLS-----------",
            "\section{Technical Skills}",
            "\begin{itemize}[leftmargin=0.15in, label={}]",
            "    \small{\item{"
        )

        if ($Profile.skills) {
            foreach ($skill in $Profile.skills.PSObject.Properties) {
                $lines += "        \textbf{$(ConvertTo-LatexValue $skill.Name)}{: $(ConvertTo-LatexValue $skill.Value)} \\"
            }
        }

        $lines += @(
            "    }}",
            "\end{itemize}",
            "\vspace{-16pt}",
            "",
            "%-----------EXPERIENCE-----------",
            "\section{Experience}",
            "\resumeSubHeadingListStart"
        )

        foreach ($role in @($Profile.experience)) {
            $companyLine = "$(ConvertTo-LatexValue $role.company)"
            if ($role.location) {
                $companyLine += " -- $(ConvertTo-LatexValue $role.location)"
            }
            $lines += ""
            $lines += "    \resumeSubheading"
            $lines += "      {$companyLine}{$(ConvertTo-LatexValue $role.dates)}"
            $lines += "      {$(ConvertTo-LatexValue $role.title)}{}"
            $lines += Add-ResumeItems $role.items
        }

        $lines += @(
            "",
            "\resumeSubHeadingListEnd",
            "\vspace{-16pt}",
            "",
            "%-----------PROJECTS-----------",
            "\section{Projects}",
            "\resumeSubHeadingListStart"
        )

        foreach ($project in @($Profile.projects)) {
            $projectLine = "\textbf{$(ConvertTo-LatexValue $project.name)}"
            if ($project.technologies) {
                $projectLine += " | \emph{$(ConvertTo-LatexValue $project.technologies)}"
            }
            $lines += ""
            $lines += "    \resumeProjectHeading"
            $lines += "          {$projectLine}{$(ConvertTo-LatexValue $project.dates)}"
            $lines += Add-ResumeItems $project.items
        }

        $lines += @(
            "",
            "\resumeSubHeadingListEnd",
            "\vspace{-16pt}",
            "",
            "%-----------EDUCATION-----------",
            "\section{Education}",
            "\resumeSubHeadingListStart"
        )

        foreach ($education in @($Profile.education)) {
            $lines += ""
            $lines += "    \resumeSubheading"
            $lines += "      {$(ConvertTo-LatexValue $education.school)}{$(ConvertTo-LatexValue $education.dates)}"
            $lines += "      {$(ConvertTo-LatexValue $education.degree)}{$(ConvertTo-LatexValue $education.location)}"
        }

        $lines += @(
            "",
            "\resumeSubHeadingListEnd",
            "\vspace{-16pt}",
            "% <NOOB_CONTENT_END>"
        )

        return $lines -join [Environment]::NewLine
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
if ($Source -eq "linkedin") {
    if ($generatedContent -notmatch $contentPattern) {
        throw "Template content block markers were not found in $sourceTemplate. Add % <NOOB_CONTENT_START> and % <NOOB_CONTENT_END> around the resume body."
    }

    $generatedContent = [regex]::Replace($generatedContent, $contentPattern, (ConvertTo-LinkedInContent $linkedInProfile))
}
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
