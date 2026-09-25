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

```powershell
# Optional: compile the user-facing wrapper directly
scripts\build-user-resume.cmd
```

```text
Option 2: Upload resume-template/noob_resume_template.tex to Overleaf and compile it there.
```

## Usage

1. Open `user-resources/user-info.tex`.
2. Replace the sample contact details with your own information.
3. Run `scripts\build-resume.cmd`.
4. Use the newest timestamped PDF from `build/` for job applications.

## User Resources

The reusable layout lives in `resume-template/noob_resume_template.tex`. It reads contact variables from `user-resources/user-info.tex`.

- `user-resources/user-info.tex` - edit this file to enter name, phone, email, LinkedIn, and GitHub values.
- `resume-template/noob_resume_template.tex` - canonical resume layout file.
- `user-resources/custom_resume_template.tex` - user-facing wrapper that loads the canonical layout from `resume-template/noob_resume_template.tex`.

This keeps the template flow simple:

```text
user-resources/custom_resume_template.tex
  -> resume-template/noob_resume_template.tex
     -> user-resources/user-info.tex
```

When more layouts are added later, each layout should live in `resume-template/` and read the same user variables from `user-resources/user-info.tex`. The user-facing wrapper can then point to the layout the user wants to compile.

To build the main resume from `resume-template/noob_resume_template.tex`:

```powershell
scripts\build-resume.cmd
```

The PDF is generated in `build/` using the resume name and a timestamp:

```text
build/John_Roe_20260925-113500.pdf
```

If you update `user-resources/user-info.tex`, run `scripts\build-resume.cmd` again and open the newest timestamped PDF from `build/`.

Overleaf template link:

```text

```

## Development

Keep the template simple and ATS-friendly:

- Use standard text sections.
- Avoid images, graphics, and complex tables.
- Keep canonical resume layouts in `resume-template/`.
- Do not commit generated PDFs or temporary LaTeX build files.
- Use `scripts/setup-latex.cmd` to install MiKTeX on Windows with `winget`, the official MiKTeX installer, or Chocolatey.
- Use `scripts/build-resume.cmd` to compile the main variable-driven template into a timestamped PDF in `build/`.
- Use `scripts/build-user-resume.cmd` only when you specifically want to compile the user-facing wrapper at `user-resources/custom_resume_template.tex`.

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
- Dedicated `build/` folder for the compiled PDF
- User-editable profile variables in `user-resources/user-info.tex`
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
