# Project Overview

Noob Resume is a clean, ATS-friendly LaTeX resume template project for software engineering job applications. The project provides a single editable LaTeX source file that can be compiled into a recruiter-readable PDF.

# Setup

- Ensure `.project-metadata.yml` exists and is classified as `public` or `internal` before making changes.
- Use Overleaf or a local LaTeX installation such as TeX Live or MiKTeX to compile the template.
- No generated PDFs, preview images, or copied promotional assets should be committed.

# Important Commands

```powershell
pdflatex noob_resume.tex
```

Run this from the repository root after installing a LaTeX distribution locally.

# Repository Structure

- `README.md` - Project overview, usage, development, support, and license notes.
- `noob_resume.tex` - Main editable LaTeX resume template.
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
- Do not add unpublished Overleaf links until the template is actually published there.
