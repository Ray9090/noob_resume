# Emits Arthur CV's original textblock/minipage layout, with explicit pages
# because absolute textblocks cannot paginate their contents automatically.
function ConvertTo-ArthurLinkedInContent {
    param($Profile, [string]$SourceLabel)

    $skills = @($Profile.skills.PSObject.Properties | ForEach-Object {
        @{ Name = [string]$_.Name; Value = [string]$_.Value }
    })
    $roles = @($Profile.experience)
    $projects = @($Profile.projects)
    $rightEntries = @()
    foreach ($role in $roles) { $rightEntries += @{ Kind = 'role'; Data = $role } }
    foreach ($project in $projects) { $rightEntries += @{ Kind = 'project'; Data = $project } }

    $entryPages = [Math]::Ceiling($rightEntries.Count / 2.0)
    $pageCount = [int][Math]::Max(1, [Math]::Max([Math]::Ceiling($skills.Count / 3.0), $entryPages))
    $skillsPerPage = [int][Math]::Floor($skills.Count / $pageCount)
    $extraSkillPages = $skills.Count % $pageCount
    $lines = @("% <NOOB_CONTENT_START>", "% Generated from $SourceLabel")

    for ($page = 0; $page -lt $pageCount; $page++) {
        if ($page -eq 0) {
            $lines += '\makeprofile'
            $y = '3.5'
        }
        else {
            $lines += '\newcvpage'
            $y = '0.5'
        }
        $lines += "\begin{textblock}{20.5}(0.25,$y)"
        $lines += '\begin{minipage}[t]{0.37\textwidth}'

        if ($page -eq 0 -and @($Profile.education).Count -gt 0) {
            $lines += '\sectionleft{Education}'
            foreach ($school in @($Profile.education)) {
                $label = @($school.degree, $school.school, $school.location, $school.dates) | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }
                $lines += "\subsectionleft{$(ConvertTo-LatexValue ($label -join ', '))}{}"
            }
        }
        $skillStart = ($page * $skillsPerPage) + [Math]::Max(0, $page - ($pageCount - $extraSkillPages))
        $skillCount = $skillsPerPage + [int]($page -ge ($pageCount - $extraSkillPages))
        $pageSkills = if ($skillCount -gt 0) { @($skills | Select-Object -Skip $skillStart -First $skillCount) } else { @() }
        if ($pageSkills.Count -gt 0) {
            $lines += '\sectionleft{Skills}'
            foreach ($skill in $pageSkills) {
                $lines += "\subsectionleft{\textbf{$(ConvertTo-LatexValue $skill.Name)}: $(ConvertTo-LatexValue $skill.Value)}{}"
            }
        }
        $lines += '\end{minipage}\hfill\begin{minipage}[t]{0.61\textwidth}'

        if ($page -eq 0 -and -not [string]::IsNullOrWhiteSpace([string]$Profile.summary)) {
            $lines += '\section{About me}'
            $lines += "$(ConvertTo-LatexValue $Profile.summary)\par"
        }
        $entryStart = $page * 2
        $pageEntries = @($rightEntries | Select-Object -Skip $entryStart -First 2)
        $previousKind = ''
        foreach ($entry in $pageEntries) {
            if ($entry.Kind -ne $previousKind) {
                $heading = if ($entry.Kind -eq 'role') { 'Experiences' } else { 'Projects' }
                if ($entryStart -gt 0 -and $rightEntries[$entryStart - 1].Kind -eq $entry.Kind) { $heading += ' (continued)' }
                $lines += "\section{$heading}"
                $previousKind = $entry.Kind
            }
            $data = $entry.Data
            if ($entry.Kind -eq 'role') {
                $place = @($data.company, $data.location) | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }
                $lines += "\textbf{$(ConvertTo-LatexValue $data.dates)}\quad\textbf{$(ConvertTo-LatexValue $data.title)}\par"
                $lines += "\textit{$(ConvertTo-LatexValue ($place -join ', '))}\par"
            }
            else {
                $lines += "\textbf{$(ConvertTo-LatexValue $data.name)}\quad\textit{$(ConvertTo-LatexValue $data.dates)}\par"
                if ($data.technologies) { $lines += "$(ConvertTo-LatexValue $data.technologies)\par" }
            }
            if (@($data.items).Count -gt 0) {
                $lines += '\begin{itemize}[leftmargin=5mm,topsep=1mm,itemsep=0mm]'
                foreach ($item in @($data.items)) { $lines += "\item $(ConvertTo-LatexValue $item)" }
                $lines += '\end{itemize}'
            }
        }
        $lines += '\end{minipage}'
        $lines += '\end{textblock}'
    }
    $lines += '% <NOOB_CONTENT_END>'
    return $lines -join [Environment]::NewLine
}
