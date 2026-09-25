$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "==> $Message"
}

function Get-CommandPath {
    param([string]$Name)
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }
    return $null
}

function Add-KnownLatexPaths {
    $paths = @(
        "C:\Program Files\MiKTeX\miktex\bin\x64",
        "$env:LOCALAPPDATA\Programs\MiKTeX\miktex\bin\x64",
        "C:\texlive\2026\bin\windows",
        "C:\texlive\2025\bin\windows",
        "C:\texlive\2024\bin\windows"
    )

    foreach ($path in $paths) {
        if ((Test-Path $path) -and ($env:Path -notlike "*$path*")) {
            $env:Path = "$path;$env:Path"
        }
    }
}

function Assert-SupportedHost {
    $osDescription = [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
    $architecture = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture

    Write-Step "Detected host: $osDescription, architecture: $architecture"

    if (-not $IsWindows -and $env:OS -ne "Windows_NT") {
        throw "This setup script currently supports Windows only. Detected: $osDescription."
    }

    if ($architecture -ne [System.Runtime.InteropServices.Architecture]::X64) {
        throw "This setup script expects Windows x64. Detected architecture: $architecture."
    }
}

function Install-Latex {
    $winget = Get-CommandPath "winget"
    $choco = Get-CommandPath "choco"

    if ($winget) {
        Write-Step "Installing MiKTeX with winget"
        & winget install --id MiKTeX.MiKTeX --exact --accept-package-agreements --accept-source-agreements
        return
    }

    if ($choco) {
        Write-Step "Installing MiKTeX with Chocolatey"
        & choco install miktex -y
        return
    }

    throw "No supported package manager was found. Install winget or Chocolatey, then run this script again."
}

function Assert-PdfLatex {
    Add-KnownLatexPaths
    $pdflatex = Get-CommandPath "pdflatex"

    if (-not $pdflatex) {
        throw "pdflatex was not found after setup. Restart PowerShell or add the MiKTeX bin folder to PATH."
    }

    Write-Step "pdflatex found at: $pdflatex"
    & pdflatex --version
}

Assert-SupportedHost

if (Get-CommandPath "pdflatex") {
    Write-Step "pdflatex is already installed"
}
else {
    Install-Latex
}

Assert-PdfLatex

Write-Step "LaTeX setup complete"
