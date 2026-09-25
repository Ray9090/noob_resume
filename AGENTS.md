# Project Overview

Noob Resume is a clean, ATS-friendly LaTeX resume template project for software engineering job applications. The project provides a single editable LaTeX source file that can be compiled into a recruiter-readable PDF.

# Setup

- Ensure `.project-metadata.yml` exists and is classified as `public` or `internal` before making changes.
- Use Overleaf or a local LaTeX installation such as TeX Live or MiKTeX to compile the template.
- Use `scripts/setup-latex.cmd` to prepare a local Windows LaTeX environment.
- No generated PDFs, preview images, or copied promotional assets should be committed.

# Important Commands

```powershell
scripts\setup-latex.cmd
```

```powershell
scripts\setup-latex.cmd --build
```

```powershell
scripts\build-resume.cmd
```

Run these from the repository root.

# Repository Structure

- `README.md` - Project overview, usage, development, support, and license notes.
- `resume-template/noob_resume_template.tex` - Main editable LaTeX resume template.
- `scripts/setup-latex.cmd` - Windows setup script for installing and validating `pdflatex`.
- `scripts/build-resume.cmd` - Local build script for compiling the resume PDF.
- `scripts/setup-latex.ps1` - PowerShell setup script for environments that allow local scripts.
- `scripts/build-resume.ps1` - PowerShell build script for environments that allow local scripts.
- `LICENSE` - MIT license and attribution notice.
- `.project-metadata.yml` - Project classification metadata.

# Coding Conventions

- Keep the resume template as a single LaTeX file.
- Preserve ATS-friendly formatting with simple headings, standard text, and machine-readable PDF output.
- Avoid images, complex visual layouts, and copied external assets.
- Keep sample data fictional and internally consistent.

# Known Pitfalls

- Local compilation requires LaTeX packages including `fontawesome5`, `tikz`, `tabularx`, and `ragged2e`.
- If `pdflatex` is unavailable locally, compile in Overleaf instead.
- On Windows, use `scripts/setup-latex.cmd` to install MiKTeX through `winget`, the official MiKTeX installer, or Chocolatey.
- On managed/corporate machines, installer downloads may be blocked and Chocolatey may require an elevated shell or package-source credentials.
- Do not add unpublished Overleaf links until the template is actually published there.
