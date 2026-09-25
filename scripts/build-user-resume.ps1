param(
    [ValidateSet("user-info", "linkedin", "linkedin-pdf")]
    [string]$Source = "user-info",
    [string]$Template = "noob_resume_template.tex",
    [string]$LinkedInPdf = ""
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
$generatedLinkedInText = Join-Path $outputDir "linkedin-profile.txt"
$generatedLinkedInJson = Join-Path $outputDir "linkedin-profile.generated.json"

function ConvertTo-LatexValue {
    param([AllowNull()][string]$Value)

    if ($null -eq $Value) {
        return ""
    }

    $escaped = $Value.Replace("\", "\textbackslash{}")
    $escaped = $escaped.Replace("&amp;", "&")
    $escaped = $escaped.Replace("&", "\&")
    $escaped = $escaped.Replace("%", "\%")
    $escaped = $escaped.Replace("$", "\$")
    $escaped = $escaped.Replace("#", "\#")
    $escaped = $escaped.Replace("_", "\_")
    $escaped = $escaped.Replace("{", "\{")
    $escaped = $escaped.Replace("}", "\}")
    return $escaped
}

function ConvertTo-CleanText {
    param([AllowNull()][string]$Value)

    if ($null -eq $Value) {
        return ""
    }

    return (($Value -replace "&amp;", "&") -replace "\s+", " ").Trim()
}

function Get-LinkedInBlock {
    param(
        [string]$Text,
        [string]$Start,
        [string]$End
    )

    $pattern = "(?ms)\b" + [regex]::Escape($Start) + "\b(.*?)\b" + [regex]::Escape($End) + "\b"
    $match = [regex]::Match($Text, $pattern)
    if ($match.Success) {
        return $match.Groups[1].Value
    }

    return ""
}

function Get-CleanLines {
    param([string]$Text)

    $result = New-Object System.Collections.Generic.List[string]
    foreach ($line in ($Text -split "`n")) {
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }
        if ($trimmed -match "^Page \d+ of \d+$") { continue }
        $result.Add($trimmed)
    }

    return $result.ToArray()
}

function Get-LeftColumnLines {
    param([string]$Text)

    $result = New-Object System.Collections.Generic.List[string]
    foreach ($line in ($Text -split "`n")) {
        if ($line -match "^\s{8,}" -or [string]::IsNullOrWhiteSpace($line)) { continue }
        $trimmed = $line.Trim()
        if ($trimmed -match "^Page \d+ of \d+$") { continue }
        $result.Add($trimmed)
    }

    return $result.ToArray()
}

function Get-RightColumnLines {
    param([string]$Text)

    $result = New-Object System.Collections.Generic.List[string]
    foreach ($line in ($Text -split "`n")) {
        if ($line -notmatch "^\s{8,}") { continue }
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }
        if ($trimmed -match "^Page \d+ of \d+$") { continue }
        $result.Add($trimmed)
    }

    return $result.ToArray()
}

function Test-DurationLine {
    param([string]$Line)
    return $Line -match "\b\d+\s+(year|years|month|months)\b"
}

function Test-DateRangeLine {
    param([string]$Line)
    return $Line -match "^(January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{4}\s+-\s+(.+)"
}

function Test-BulletLine {
    param([string]$Line)
    return $Line -match "^\d+\.\s+"
}

function Test-CompanyStart {
    param([string[]]$Lines, [int]$Index)
    if ($Index + 1 -ge $Lines.Count) { return $false }
    return (-not (Test-BulletLine $Lines[$Index])) -and (Test-DurationLine $Lines[$Index + 1])
}

function Test-RoleStart {
    param([string[]]$Lines, [int]$Index)
    if ($Index + 1 -ge $Lines.Count) { return $false }
    return (-not (Test-BulletLine $Lines[$Index])) -and (Test-DateRangeLine $Lines[$Index + 1])
}


function Test-CompanyStartAt {
    param([string]$Current, [string]$Next)
    if ([string]::IsNullOrWhiteSpace($Next)) { return $false }
    return (-not (Test-BulletLine $Current)) -and (Test-DurationLine $Next)
}

function Test-RoleStartAt {
    param([string]$Current, [string]$Next)
    if ([string]::IsNullOrWhiteSpace($Next)) { return $false }
    return (-not (Test-BulletLine $Current)) -and (Test-DateRangeLine $Next)
}

function ConvertFrom-LinkedInPdfText {
    param([string]$Text)

    $name = ""
    foreach ($line in Get-CleanLines $Text) {
        if ($line -match "^[A-Z][A-Za-z'.-]+(\s+[A-Z][A-Za-z'.-]+)+$" -and $line -notin @("Contact", "Summary", "Experience", "Education")) {
            $name = $line
            break
        }
    }

    $rawLines = $Text -split "`n"
    $email = ""
    for ($lineIndex = 0; $lineIndex -lt $rawLines.Count; $lineIndex++) {
        $line = $rawLines[$lineIndex].Trim()
        if ($line -notmatch "@") { continue }
        $candidateMatch = [regex]::Match($line, "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+")
        if (-not $candidateMatch.Success) { continue }
        $email = $candidateMatch.Value
        if ($email -match "\.co$") {
            for ($lookAhead = $lineIndex + 1; $lookAhead -lt [Math]::Min($rawLines.Count, $lineIndex + 4); $lookAhead++) {
                if ($rawLines[$lookAhead].Trim().StartsWith("m")) {
                    $email += "m"
                    break
                }
            }
        }
        break
    }

    $joined = ($Text -replace "`r", "") -replace "-\s*`n\s*", "-"
    $joined = $joined -replace "`n", " "
    $linkedInDisplay = ""
    $linkedInUrl = ""
    for ($lineIndex = 0; $lineIndex -lt $rawLines.Count; $lineIndex++) {
        if ($rawLines[$lineIndex] -notmatch "linkedin\.com/in/") { continue }
        $candidate = ($rawLines[$lineIndex].Trim() -split "\s+")[0]
        if ($candidate -match "-$" -and $lineIndex + 1 -lt $rawLines.Count) {
            $candidate += ($rawLines[$lineIndex + 1].Trim() -split "\s+")[0]
        }
        $linkedInMatch = [regex]::Match($candidate, "(www\.)?linkedin\.com/in/[A-Za-z0-9_-]+")
        if ($linkedInMatch.Success) {
            $linkedInDisplay = $linkedInMatch.Value
            $linkedInUrl = "https://" + $linkedInDisplay
            break
        }
    }

    $githubDisplay = ""
    $githubUrl = ""
    $githubMatch = [regex]::Match($joined, "github\.com/[A-Za-z0-9_.-]+")
    if ($githubMatch.Success) {
        $githubDisplay = $githubMatch.Value
        $githubUrl = "https://" + $githubDisplay
    }

    $summaryBlock = Get-LinkedInBlock $Text "Summary" "Experience"
    $summaryLines = Get-RightColumnLines $summaryBlock
    $summary = ConvertTo-CleanText ($summaryLines -join " ")

    $topSkills = Get-LeftColumnLines (Get-LinkedInBlock $Text "Top Skills" "Languages")
    $languages = Get-LeftColumnLines (Get-LinkedInBlock $Text "Languages" "Certifications")
    $certifications = Get-LeftColumnLines (Get-LinkedInBlock $Text "Certifications" "Experience")

    $skills = [ordered]@{}
    if ($topSkills.Count -gt 0) { $skills["Top Skills"] = (ConvertTo-CleanText ($topSkills -join ", ")) }
    if ($languages.Count -gt 0) { $skills["Languages"] = (ConvertTo-CleanText ($languages -join ", ")) }
    if ($certifications.Count -gt 0) { $skills["Certifications"] = (ConvertTo-CleanText ($certifications -join ", ")) }

    $experienceLines = @(Get-CleanLines (Get-LinkedInBlock $Text "Experience" "Education"))
    $experience = New-Object System.Collections.Generic.List[object]
    $currentCompany = ""
    $i = 0
    while ($i -lt $experienceLines.Count) {
        $current = $experienceLines[$i]
        $next = if ($i + 1 -lt $experienceLines.Count) { $experienceLines[$i + 1] } else { "" }
        $isCompanyStart = ($i + 1 -lt $experienceLines.Count) -and ($current -notmatch "^\d+\.\s+") -and ($next -match "\b\d+\s+(year|years|month|months)\b")
        $isRoleStart = ($i + 1 -lt $experienceLines.Count) -and ($current -notmatch "^\d+\.\s+") -and ($next -match "^(January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{4}\s+-\s+.+")

        if ($isCompanyStart) {
            $currentCompany = $current
            $i += 2
            continue
        }

        if ($isRoleStart) {
            $title = $current
            $dates = $next
            $i += 2
            $location = ""
            if ($i -lt $experienceLines.Count) {
                $locationCurrent = $experienceLines[$i]
                $locationNext = if ($i + 1 -lt $experienceLines.Count) { $experienceLines[$i + 1] } else { "" }
                $locationIsCompanyStart = ($i + 1 -lt $experienceLines.Count) -and ($locationCurrent -notmatch "^\d+\.\s+") -and ($locationNext -match "\b\d+\s+(year|years|month|months)\b")
                $locationIsRoleStart = ($i + 1 -lt $experienceLines.Count) -and ($locationCurrent -notmatch "^\d+\.\s+") -and ($locationNext -match "^(January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{4}\s+-\s+.+")
                if (($locationCurrent -notmatch "^\d+\.\s+") -and -not $locationIsCompanyStart -and -not $locationIsRoleStart) {
                    $location = $locationCurrent
                    $i++
                }
            }

            $items = New-Object System.Collections.Generic.List[string]
            while ($i -lt $experienceLines.Count) {
                $line = $experienceLines[$i]
                $lineNext = if ($i + 1 -lt $experienceLines.Count) { $experienceLines[$i + 1] } else { "" }
                $lineIsCompanyStart = ($i + 1 -lt $experienceLines.Count) -and ($line -notmatch "^\d+\.\s+") -and ($lineNext -match "\b\d+\s+(year|years|month|months)\b")
                $lineIsRoleStart = ($i + 1 -lt $experienceLines.Count) -and ($line -notmatch "^\d+\.\s+") -and ($lineNext -match "^(January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{4}\s+-\s+.+")
                if ($lineIsCompanyStart -or $lineIsRoleStart) {
                    break
                }

                if ($line -match "^\d+\.\s+") {
                    $items.Add(($line -replace "^\d+\.\s+", ""))
                }
                elseif ($items.Count -gt 0) {
                    $items[$items.Count - 1] = (ConvertTo-CleanText ($items[$items.Count - 1] + " " + $line))
                }
                elseif (-not [string]::IsNullOrWhiteSpace($line)) {
                    $items.Add($line)
                }
                $i++
            }

            $experience.Add([ordered]@{
                company = $currentCompany
                location = $location
                dates = $dates
                title = $title
                items = @($items | ForEach-Object { ConvertTo-CleanText $_ })
            })
            continue
        }

        $i++
    }

    $educationTextParts = $Text -split "\bEducation\b", 2
    $educationLines = @()
    if ($educationTextParts.Count -gt 1) {
        $educationLines = Get-CleanLines $educationTextParts[1]
    }
    $education = New-Object System.Collections.Generic.List[object]
    $i = 0
    while ($i -lt $educationLines.Count) {
        $school = $educationLines[$i]
        $i++
        $degreeParts = New-Object System.Collections.Generic.List[string]
        while ($i -lt $educationLines.Count) {
            $degreeParts.Add($educationLines[$i])
            if ($educationLines[$i] -match "\(([^)]*)\)") {
                $degreeText = ConvertTo-CleanText ($degreeParts -join " ")
                $dates = $Matches[1]
                $degree = ConvertTo-CleanText ($degreeText -replace "\s+\S\s+\([^)]*\)\s*$", "")
                $education.Add([ordered]@{
                    school = $school
                    dates = $dates
                    degree = $degree
                    location = ""
                })
                $i++
                break
            }
            $i++
        }
    }

    return [ordered]@{
        name = $name
        phoneDisplay = ""
        phoneLink = ""
        email = $email
        linkedinDisplay = $linkedInDisplay
        linkedinUrl = $linkedInUrl
        githubDisplay = $githubDisplay
        githubUrl = $githubUrl
        summary = $summary
        skills = $skills
        experience = @($experience.ToArray())
        projects = @()
        education = @($education.ToArray())
    }
}

function Add-ResumeItems {
    param([System.Collections.IEnumerable]$Items)

    $lines = @("      \resumeItemListStart")
    foreach ($item in @($Items)) {
        if ([string]::IsNullOrWhiteSpace([string]$item)) { continue }
        $lines += "        \resumeItem{$(ConvertTo-LatexValue $item)}"
    }
    $lines += "      \resumeItemListEnd"
    return $lines
}

function ConvertTo-LinkedInContent {
    param($Profile, [string]$SourceLabel)

    $lines = @(
        "% <NOOB_CONTENT_START>",
        "% Generated from $SourceLabel",
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
            if ([string]::IsNullOrWhiteSpace([string]$skill.Value)) { continue }
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

    if ($Profile.experience) {
        foreach ($role in @($Profile.experience)) {
            if ($null -eq $role) { continue }
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
    }
    else {
        $lines += "    \item[]"
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

    if ($Profile.projects) {
        foreach ($project in @($Profile.projects)) {
            if ($null -eq $project) { continue }
            $projectLine = "\textbf{$(ConvertTo-LatexValue $project.name)}"
            if ($project.technologies) {
                $projectLine += " | \emph{$(ConvertTo-LatexValue $project.technologies)}"
            }
            $lines += ""
            $lines += "    \resumeProjectHeading"
            $lines += "          {$projectLine}{$(ConvertTo-LatexValue $project.dates)}"
            $lines += Add-ResumeItems $project.items
        }
    }
    else {
        $lines += "    \item[]"
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

    if ($Profile.education) {
        foreach ($education in @($Profile.education)) {
            if ($null -eq $education) { continue }
            $lines += ""
            $lines += "    \resumeSubheading"
            $lines += "      {$(ConvertTo-LatexValue $education.school)}{$(ConvertTo-LatexValue $education.dates)}"
            $lines += "      {$(ConvertTo-LatexValue $education.degree)}{$(ConvertTo-LatexValue $education.location)}"
        }
    }
    else {
        $lines += "    \item[]"
    }

    $lines += @(
        "",
        "\resumeSubHeadingListEnd",
        "\vspace{-16pt}",
        "% <NOOB_CONTENT_END>"
    )

    return $lines -join [Environment]::NewLine
}

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

if ($Source -eq "linkedin-pdf") {
    if ([string]::IsNullOrWhiteSpace($LinkedInPdf)) {
        throw "LinkedIn PDF path is required. Usage: scripts\build-user-resume.cmd linkedin-pdf path\to\Profile.pdf"
    }

    $linkedInPdfPath = $LinkedInPdf
    if (-not [System.IO.Path]::IsPathRooted($linkedInPdfPath)) {
        $linkedInPdfPath = Join-Path $repoRoot $linkedInPdfPath
    }
    $linkedInPdfPath = Resolve-Path $linkedInPdfPath

    if (-not (Get-Command pdftotext -ErrorAction SilentlyContinue)) {
        throw "pdftotext is not installed or not available in PATH. Install Poppler/Xpdf tools or use the linkedin JSON source."
    }

    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
    $pdfTextLines = & pdftotext -layout $linkedInPdfPath -
    $pdfText = $pdfTextLines -join [Environment]::NewLine
    if ($LASTEXITCODE -ne 0) {
        throw "pdftotext failed with exit code $LASTEXITCODE for $linkedInPdfPath"
    }

    Set-Content -Path $generatedLinkedInText -Value $pdfText -NoNewline
    $parsedProfile = ConvertFrom-LinkedInPdfText $pdfText
    $parsedProfile | ConvertTo-Json -Depth 8 | Set-Content -Path $generatedLinkedInJson
    $linkedInProfileFile = $generatedLinkedInJson
}

$linkedInProfile = $null
if ($Source -in @("linkedin", "linkedin-pdf")) {
    $linkedInProfile = Get-Content -Raw $linkedInProfileFile | ConvertFrom-Json
}

$resumeName = "custom_resume"
if ($Source -eq "user-info") {
    $userInfo = Get-Content -Raw $userInfoFile
    if ($userInfo -match "\\newcommand\{\\ResumeName\}\{([^}]*)\}") {
        $resumeName = $Matches[1]
    }
}
elseif ($linkedInProfile.name) {
    $resumeName = $linkedInProfile.name
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
    $sourceLabel = if ($Source -eq "linkedin-pdf") { "build/linkedin-profile.generated.json" } else { "user-resources/linkedin-profile.json" }
    $profileLines = @(
        "% Generated from $sourceLabel",
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
if ($Source -in @("linkedin", "linkedin-pdf")) {
    if ($generatedContent -notmatch $contentPattern) {
        throw "Template content block markers were not found in $sourceTemplate. Add % <NOOB_CONTENT_START> and % <NOOB_CONTENT_END> around the resume body."
    }

    $sourceLabel = if ($Source -eq "linkedin-pdf") { "build/linkedin-profile.generated.json" } else { "user-resources/linkedin-profile.json" }
    $generatedContent = [regex]::Replace($generatedContent, $contentPattern, (ConvertTo-LinkedInContent $linkedInProfile $sourceLabel))
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
if ($Source -eq "linkedin-pdf") {
    Write-Host "==> Extracted LinkedIn PDF text to build/linkedin-profile.txt"
    Write-Host "==> Generated LinkedIn profile data at build/linkedin-profile.generated.json"
}
Write-Host "==> Generated build/custom_resume_template.tex from resume-template/$Template"
Write-Host "==> User resume PDF built at build/$jobName.pdf"
