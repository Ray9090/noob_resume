# Noob Resume

## Description

Noob Resume is a clean, ATS-friendly one-page LaTeX resume template for software engineering job applications. It is designed to keep resume content easy for applicant tracking systems to parse while still looking polished for recruiters.

The template includes structured sections for contact information, professional summary, technical skills, experience, projects, and education.

## Installation

Use one of these options:

```powershell
# Option 1: Prepare the local Windows LaTeX environment
scripts\setup-latex.cmd
```

```powershell
# After setup, compile locally
scripts\build-resume.cmd
```

```text
Option 2: Upload resume-template/noob_resume_template.tex to Overleaf and compile it there.
```

## Usage

1. Open `resume-template/noob_resume_template.tex`.
2. Replace the sample John Doe details with your own information.
3. Compile the file with `pdflatex` or Overleaf.
4. Download the generated PDF and use it for job applications.

Overleaf template link:

```text

```

## Development

Keep the template simple and ATS-friendly:

- Use standard text sections.
- Avoid images, graphics, and complex tables.
- Keep the resume source as a single LaTeX file.
- Do not commit generated PDFs or temporary LaTeX build files.
- Use `scripts/setup-latex.cmd` to install MiKTeX on Windows with `winget`, the official MiKTeX installer, or Chocolatey.
- Use `scripts/build-resume.cmd` to compile the template after LaTeX is installed.

If local setup fails on a managed/corporate machine:

- `winget` error `0x8a15000f` means the local winget source metadata is broken or restricted.
- A blocked `basic-miktex-*.exe` download means the host or proxy blocks downloaded installer files.
- Chocolatey may require an elevated shell or configured package-source credentials.
- In that case, install MiKTeX through the approved company software portal, then run `scripts\build-resume.cmd`.

## Features

- One-page software engineering resume layout
- ATS-friendly structure
- Editable single-file LaTeX source in `resume-template/`
- One-command Windows LaTeX setup script
- Recruiter-readable headings and bullet points
- Fictional sample data for easy replacement
- No copied preview images or promotional assets

## Contributing

Contributions should keep the template clean, readable, and easy to compile. Use conventional commit messages such as:

```text
feat: improve skills section layout
fix: resolve latex compile warning
docs: update usage instructions
```

## Support

Open an issue in this repository if you find a compile problem, typo, or formatting issue.

## License

This project is released under the MIT License. See `LICENSE` for details and attribution.
