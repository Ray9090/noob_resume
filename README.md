# Noob Resume

## Description

Noob Resume is a clean, ATS-friendly one-page LaTeX resume template for software engineering job applications. It is designed to keep resume content easy for applicant tracking systems to parse while still looking polished for recruiters.

The template includes structured sections for contact information, professional summary, technical skills, experience, projects, and education.

## Installation

Use one of these options:

```powershell
# Option 1: Compile locally after installing MiKTeX or TeX Live
cd resume-template
pdflatex noob_resume_template.tex
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

## Features

- One-page software engineering resume layout
- ATS-friendly structure
- Editable single-file LaTeX source in `resume-template/`
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
