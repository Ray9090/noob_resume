param(
    [Parameter(Mandatory = $true)] [string]$PdfPath,
    [Parameter(Mandatory = $true)] [string]$OutputDir
)

$ErrorActionPreference = "Stop"
$DateRangePattern = "^(January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{4}\s+-\s+."

function Clean-Text([AllowNull()][string]$Value) {
    if ($null -eq $Value) { return "" }
    $decoded = $Value
    for ($i = 0; $i -lt 2; $i++) { $decoded = [System.Net.WebUtility]::HtmlDecode($decoded) }
    return (($decoded -replace "\s+", " ").Trim())
}

function Is-DateRange([string]$Line) { return $Line -match $DateRangePattern }
function Is-Duration([string]$Line) { return $Line -match "\b\d+\s+(year|years|month|months)\b" }
function Is-Bullet([string]$Line) { return $Line -match "^\d+\.\s+" }
function Is-CompanyLike([string]$Line) { return $Line -match "\b(GmbH|Group|Ltd|Limited|LLC|Inc|Corporation|Company|Institute|Institut|University|BANGLADESH|Service|Technologies|Power)\b|e\.V\.$" }
function Is-LocationLike([string]$Line) {
    if (-not $Line) { return $false }
    if ($Line -match "\.$|,$") { return $false }
    if ($Line -match "\b(Designed|Built|Created|Developed|Managed|Managing|Delivered|Delivering|Implemented|Working|Building|Integrating|Maintaining|Conduct|Analyze|designed|built|created|developed|managed|delivering)\b") { return $false }
    return $Line -match ",|\b(Germany|Bangladesh|Dhaka|Magdeburg|Dingolfing|Wismar|Dhanmondi|Saxony|Bavaria|Pomerania|IDB|Bhaban|Road|Street|City|State|Remote)\b"
}

function Find-Index {
    param($Lines, [string[]]$Names, [int]$StartIndex = 0)
    for ($i = $StartIndex; $i -lt $Lines.Count; $i++) {
        foreach ($name in $Names) {
            if ($Lines[$i].text -ieq $name) { return $i }
        }
    }
    return -1
}

function Get-Range {
    param($Lines, [string[]]$StartNames, [string[][]]$EndNameGroups)
    $start = Find-Index -Lines $Lines -Names $StartNames
    if ($start -lt 0) { return @() }
    $end = $Lines.Count
    foreach ($names in $EndNameGroups) {
        $candidate = Find-Index -Lines $Lines -Names $names -StartIndex ($start + 1)
        if ($candidate -ge 0 -and $candidate -lt $end) { $end = $candidate }
    }
    if ($end -le ($start + 1)) { return @() }
    return @($Lines[($start + 1)..($end - 1)])
}

function Join-WrappedLines([string[]]$Lines) {
    $result = New-Object System.Collections.Generic.List[string]
    foreach ($line in $Lines) {
        $clean = Clean-Text $line
        if (-not $clean) { continue }
        if ($result.Count -eq 0) { $result.Add($clean); continue }
        $previous = $result[$result.Count - 1]
        if ($previous.EndsWith("-")) { $result[$result.Count - 1] = $previous + $clean }
        else { $result.Add($clean) }
    }
    return $result.ToArray()
}

function Extract-Lines([string]$ResolvedPdfPath, [string]$BboxPath) {
    & pdftotext -bbox-layout $ResolvedPdfPath $BboxPath
    if ($LASTEXITCODE -ne 0) { throw "pdftotext -bbox-layout failed with exit code $LASTEXITCODE for $ResolvedPdfPath" }

    [xml]$xml = Get-Content -Raw $BboxPath
    $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
    $ns.AddNamespace("x", "http://www.w3.org/1999/xhtml")

    $lines = New-Object System.Collections.Generic.List[object]
    $pageNumber = 0
    foreach ($page in $xml.SelectNodes("//x:page", $ns)) {
        $pageNumber++
        foreach ($line in $page.SelectNodes(".//x:line", $ns)) {
            $words = @($line.SelectNodes("./x:word", $ns))
            if ($words.Count -eq 0) { continue }
            $text = Clean-Text (($words | ForEach-Object { Clean-Text $_.InnerText }) -join " ")
            if (-not $text -or $text -match "^Page \d+ of \d+$") { continue }
            $xMin = [double]$line.xMin
            $column = if ($xMin -lt 200) { "sidebar" } else { "main" }
            $lines.Add([pscustomobject][ordered]@{
                page = $pageNumber
                column = $column
                xMin = [math]::Round($xMin, 3)
                xMax = [math]::Round([double]$line.xMax, 3)
                yMin = [math]::Round([double]$line.yMin, 3)
                yMax = [math]::Round([double]$line.yMax, 3)
                text = $text
            })
        }
    }
    return @($lines | Sort-Object page, yMin, xMin)
}

function Get-ContactMatch([string[]]$Lines, [string]$Pattern) {
    foreach ($line in $Lines) {
        $match = [regex]::Match($line, $Pattern)
        if ($match.Success) { return $match.Value }
    }
    return ""
}

function Convert-LinesToProfile($Lines) {
    $main = @($Lines | Where-Object { $_.column -eq "main" } | Sort-Object page, yMin, xMin)
    $sidebar = @($Lines | Where-Object { $_.column -eq "sidebar" } | Sort-Object page, yMin, xMin)
    $sidebarText = @($sidebar | ForEach-Object { $_.text })

    $summaryIndex = Find-Index -Lines $main -Names @("Summary")
    $name = ""
    if ($summaryIndex -gt 0) {
        for ($i = 0; $i -lt $summaryIndex; $i++) {
            if ($main[$i].text -match "[A-Za-z]" -and $main[$i].text -notin @("Contact", "Summary", "Experience", "Education")) {
                $name = $main[$i].text
                break
            }
        }
    }

    $email = ""
    for ($i = 0; $i -lt $sidebarText.Count; $i++) {
        if ($sidebarText[$i] -notmatch "@") { continue }
        $candidate = ($sidebarText[$i] -replace "\s+", "")
        for ($j = $i + 1; $j -lt [Math]::Min($sidebarText.Count, $i + 4); $j++) {
            if ($candidate -match "\.(com|net|org|de)$") { break }
            $piece = ($sidebarText[$j] -replace "\s+", "")
            if ($piece -match "^[A-Za-z]{1,4}$") { $candidate += $piece }
        }
        $match = [regex]::Match($candidate, "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}")
        if ($match.Success) { $email = $match.Value; break }
    }

    $linkedinDisplay = ""
    for ($i = 0; $i -lt $sidebarText.Count; $i++) {
        if ($sidebarText[$i] -notmatch "linkedin\.com/in/") { continue }
        $candidate = ($sidebarText[$i] -replace "\s+", "")
        for ($j = $i + 1; $j -lt [Math]::Min($sidebarText.Count, $i + 4); $j++) {
            if ($sidebarText[$j] -match "^\(") { break }
            $candidate += ($sidebarText[$j] -replace "\s+", "")
            if ($candidate -notmatch "-$") { break }
        }
        $candidate = $candidate -replace "^https?://", ""
        $match = [regex]::Match($candidate, "(www\.)?linkedin\.com/in/[A-Za-z0-9_-]+")
        if ($match.Success) { $linkedinDisplay = $match.Value; break }
    }

    $githubDisplay = Get-ContactMatch $sidebarText "github\.com/[A-Za-z0-9_.-]+"
    $phoneDisplay = ""
    foreach ($line in $sidebarText) {
        if ($line -match "linkedin|github|Blog|Portfolio" -or $line -notmatch "\+") { continue }
        $phoneDisplay = Get-ContactMatch @($line) "\+?[0-9][0-9 ()-]{6,}[0-9]"
        if ($phoneDisplay) { break }
    }
    $phoneLink = $phoneDisplay -replace "[^0-9+]", ""

    $summary = Clean-Text ((@(Get-Range -Lines $main -StartNames @("Summary") -EndNameGroups @(@("Experience"), @("Education")) | ForEach-Object { $_.text })) -join " ")

    $skills = [ordered]@{}
    $top = Join-WrappedLines (@(Get-Range -Lines $sidebar -StartNames @("Top Skills", "Top") -EndNameGroups @(@("Languages"), @("Certifications")) | ForEach-Object { $_.text }) | Where-Object { $_ -ne "Skills" })
    if ($top.Count -gt 0) { $skills["Top Skills"] = Clean-Text ($top -join ", ") }
    $languages = Join-WrappedLines (@(Get-Range -Lines $sidebar -StartNames @("Languages") -EndNameGroups @(@("Certifications")) | ForEach-Object { $_.text }))
    if ($languages.Count -gt 0) { $skills["Languages"] = Clean-Text ($languages -join ", ") }
    $certs = Join-WrappedLines (@(Get-Range -Lines $sidebar -StartNames @("Certifications") -EndNameGroups @(@("Experience"), @("Education")) | ForEach-Object { $_.text }))
    if ($certs.Count -gt 0) { $skills["Certifications"] = Clean-Text ($certs -join ", ") }

    $experienceTexts = @(Get-Range -Lines $main -StartNames @("Experience") -EndNameGroups @(@("Education")) | ForEach-Object { $_.text })
    $experience = New-Object System.Collections.Generic.List[object]
    $currentCompany = ""
    $i = 0
    while ($i -lt $experienceTexts.Count) {
        $line = $experienceTexts[$i]
        $next = if ($i + 1 -lt $experienceTexts.Count) { $experienceTexts[$i + 1] } else { "" }
        $next2 = if ($i + 2 -lt $experienceTexts.Count) { $experienceTexts[$i + 2] } else { "" }
        $companyStart = ((-not (Is-Bullet $line)) -and (-not (Is-DateRange $line)) -and ((Is-Duration $next) -and -not (Is-DateRange $next))) -or ((-not (Is-Bullet $line)) -and (-not (Is-DateRange $line)) -and (-not (Is-Duration $line)) -and (Is-CompanyLike $line) -and (-not (Is-Bullet $next)) -and (-not (Is-DateRange $next)) -and (-not (Is-Duration $next)) -and (Is-DateRange $next2))
        $roleStart = (-not (Is-Bullet $line)) -and (-not (Is-Duration $line)) -and (Is-DateRange $next)
        if ($companyStart) {
            $currentCompany = $line
            if ((Is-Duration $next) -and -not (Is-DateRange $next)) { $i += 2 } else { $i++ }
            continue
        }
        if (-not $roleStart) { $i++; continue }

        $title = $line
        $dates = $next
        $i += 2
        $location = ""
        if ($i -lt $experienceTexts.Count) {
            $candidate = $experienceTexts[$i]
            $candidateNext = if ($i + 1 -lt $experienceTexts.Count) { $experienceTexts[$i + 1] } else { "" }
            $candidateNext2 = if ($i + 2 -lt $experienceTexts.Count) { $experienceTexts[$i + 2] } else { "" }
            $candidateCompany = ((-not (Is-Bullet $candidate)) -and (-not (Is-DateRange $candidate)) -and ((Is-Duration $candidateNext) -and -not (Is-DateRange $candidateNext))) -or ((-not (Is-Bullet $candidate)) -and (-not (Is-DateRange $candidate)) -and (-not (Is-Duration $candidate)) -and (Is-CompanyLike $candidate) -and (-not (Is-Bullet $candidateNext)) -and (-not (Is-DateRange $candidateNext)) -and (-not (Is-Duration $candidateNext)) -and (Is-DateRange $candidateNext2))
            $candidateRole = (-not (Is-Bullet $candidate)) -and (-not (Is-Duration $candidate)) -and (Is-DateRange $candidateNext)
            if (-not (Is-Bullet $candidate) -and -not $candidateCompany -and -not $candidateRole -and -not (Is-DateRange $candidate) -and (Is-LocationLike $candidate)) {
                $location = $candidate
                $i++
            }
        }

        $items = New-Object System.Collections.Generic.List[string]
        while ($i -lt $experienceTexts.Count) {
            $current = $experienceTexts[$i]
            $currentNext = if ($i + 1 -lt $experienceTexts.Count) { $experienceTexts[$i + 1] } else { "" }
            $currentNext2 = if ($i + 2 -lt $experienceTexts.Count) { $experienceTexts[$i + 2] } else { "" }
            $currentCompanyStart = ((-not (Is-Bullet $current)) -and (-not (Is-DateRange $current)) -and ((Is-Duration $currentNext) -and -not (Is-DateRange $currentNext))) -or ((-not (Is-Bullet $current)) -and (-not (Is-DateRange $current)) -and (-not (Is-Duration $current)) -and (Is-CompanyLike $current) -and (-not (Is-Bullet $currentNext)) -and (-not (Is-DateRange $currentNext)) -and (-not (Is-Duration $currentNext)) -and (Is-DateRange $currentNext2))
            $currentRoleStart = (-not (Is-Bullet $current)) -and (-not (Is-Duration $current)) -and (Is-DateRange $currentNext)
            if ($currentCompanyStart -or $currentRoleStart) { break }
            if (Is-DateRange $current -or Is-Duration $current) { $i++; continue }
            if (Is-Bullet $current) { $items.Add(($current -replace "^\d+\.\s+", "")) }
            elseif ($items.Count -gt 0) { $items[$items.Count - 1] = Clean-Text ($items[$items.Count - 1] + " " + $current) }
            elseif ($current) { $items.Add($current) }
            $i++
        }

        $experience.Add([ordered]@{
            company = $currentCompany
            location = $location
            dates = $dates
            title = $title
            items = @($items | ForEach-Object { Clean-Text $_ })
        })
    }

    $educationLines = @(Get-Range -Lines $main -StartNames @("Education") -EndNameGroups @())
    $education = New-Object System.Collections.Generic.List[object]
    $i = 0
    while ($i -lt $educationLines.Count) {
        $school = $educationLines[$i].text
        $i++
        $parts = New-Object System.Collections.Generic.List[string]
        while ($i -lt $educationLines.Count) {
            $parts.Add($educationLines[$i].text)
            $i++
            $degreeText = Clean-Text ($parts -join " ")
            if ($degreeText -match "\(([^)]*)\)") {
                $education.Add([ordered]@{
                    school = $school
                    dates = $Matches[1]
                    degree = Clean-Text ($degreeText -replace "\s*\([^)]*\)", "")
                    location = ""
                })
                break
            }
        }
    }

    return [ordered]@{
        name = $name
        phoneDisplay = $phoneDisplay
        phoneLink = $phoneLink
        email = $email
        linkedinDisplay = $linkedinDisplay
        linkedinUrl = if ($linkedinDisplay) { "https://$linkedinDisplay" } else { "" }
        githubDisplay = $githubDisplay
        githubUrl = if ($githubDisplay) { "https://$githubDisplay" } else { "" }
        summary = $summary
        skills = $skills
        experience = @($experience.ToArray())
        projects = @()
        education = @($education.ToArray())
    }
}

$resolvedPdf = Resolve-Path $PdfPath
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$bboxPath = Join-Path $OutputDir "linkedin-profile.bbox.html"
$linesPath = Join-Path $OutputDir "linkedin-profile.lines.json"
$textPath = Join-Path $OutputDir "linkedin-profile.txt"
$jsonPath = Join-Path $OutputDir "linkedin-profile.generated.json"

$lines = Extract-Lines $resolvedPdf $bboxPath
$lines | ConvertTo-Json -Depth 8 | Set-Content -Path $linesPath
$lines | ForEach-Object { "p$($_.page) $($_.column.PadRight(7)) x=$($_.xMin). y=$($_.yMin)  $($_.text)" } | Set-Content -Path $textPath
Convert-LinesToProfile $lines | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath

Write-Host "==> Extracted LinkedIn PDF layout to build/linkedin-profile.lines.json"
Write-Host "==> Wrote readable LinkedIn PDF text to build/linkedin-profile.txt"
Write-Host "==> Generated LinkedIn profile data at build/linkedin-profile.generated.json"
