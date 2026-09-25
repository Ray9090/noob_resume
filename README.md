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
# After setup, compile the ready-made template locally
scripts\build-resume.cmd
```

```powershell
# Generate and compile a user-customized resume from user-info.tex
scripts\build-user-resume.cmd user-info
```

```powershell
# Generate and compile from LinkedIn-style profile data
scripts\build-user-resume.cmd linkedin
```

```text
Option 2: Upload resume-template/noob_resume_template.tex to Overleaf and compile it there.
```

## Usage

1. Choose a profile source: `user-info`, `linkedin`, or `linkedin-pdf`.
2. For `user-info`, edit `user-resources/user-info.tex`.
3. For `linkedin`, copy `user-resources/linkedin-profile.example.json` to `user-resources/linkedin-profile.json`, then edit it with details copied or exported from your LinkedIn profile.
4. Run `scripts\build-user-resume.cmd user-info`, `scripts\build-user-resume.cmd linkedin`, or `scripts\build-user-resume.cmd linkedin-pdf path\to\Profile.pdf`.
5. Use the newest timestamped PDF from `build/` for job applications.

## User Resources

The ready-made layout lives in `resume-template/noob_resume_template.tex`. It contains its own sample contact details and can compile by itself.

- `user-resources/user-info.tex` - edit this file to enter name, phone, email, LinkedIn, and GitHub values.
- `user-resources/linkedin-profile.example.json` - tracked example for LinkedIn-style profile data.
- `user-resources/linkedin-profile.json` - local private LinkedIn-derived profile data; ignored by Git.
- `resume-template/noob_resume_template.tex` - standalone ready-made template with sample contact details.
- `build/custom_resume_template.tex` - generated during the custom build; do not edit or commit it.
- `build/profile-info.tex` - generated during LinkedIn-source builds; do not edit or commit it.
- `build/linkedin-profile.bbox.html` - generated coordinate-aware PDF extraction from `pdftotext -bbox-layout`; useful for parser debugging.
- `build/linkedin-profile.lines.json` - generated normalized line data with page, column, coordinates, and text.
- `build/linkedin-profile.txt` - generated readable line-by-line text extracted from a LinkedIn PDF.
- `build/linkedin-profile.generated.json` - generated profile data classified from the normalized LinkedIn PDF lines.

This keeps the template flow simple:

```text
resume-template/noob_resume_template.tex
  -> standalone ready-made template

scripts/build-user-resume.cmd
  -> copies a template from resume-template/
  -> generates build/custom_resume_template.tex
  -> injects user-resources/user-info.tex, user-resources/linkedin-profile.json, or generated LinkedIn PDF data
  -> compiles the customized PDF
```

When more layouts are added later, each ready-made layout should live in `resume-template/` and include the profile block markers used by the build script:

```latex
% <NOOB_PROFILE_START>
% default profile values
% <NOOB_PROFILE_END>
```

The custom build replaces the profile block with the selected source at build time. For the `linkedin` source, it also replaces the marked resume body with generated summary, skills, experience, projects, and education sections from `user-resources/linkedin-profile.json`. No permanent custom template file is required.

To build the ready-made template from `resume-template/noob_resume_template.tex`:

```powershell
scripts\build-resume.cmd
```

To build the customized resume from the default ready-made template plus `user-resources/user-info.tex`:

```powershell
scripts\build-user-resume.cmd user-info
```

To build from `user-resources/linkedin-profile.json`:

```powershell
scripts\build-user-resume.cmd linkedin
```

To build from a LinkedIn profile PDF saved by the user:

```powershell
scripts\build-user-resume.cmd linkedin-pdf path\to\Profile.pdf
```

The LinkedIn options read local data only; they do not log in to LinkedIn or scrape a profile page. The `linkedin-pdf` source uses a two-stage importer: first it extracts coordinate-aware PDF lines with `pdftotext -bbox-layout`, then it classifies those lines into contact details, summary, skills, experience, and education. It writes `build/linkedin-profile.bbox.html`, `build/linkedin-profile.lines.json`, `build/linkedin-profile.txt`, and `build/linkedin-profile.generated.json`, then compiles from the generated JSON. PDF parsing is still best-effort because LinkedIn can change the export layout, so review the generated JSON/PDF and refine with the JSON source if needed.

To build from a different template in `resume-template/`, pass the template filename:

```powershell
scripts\build-user-resume.cmd user-info another_template.tex
scripts\build-user-resume.cmd linkedin another_template.tex
scripts\build-user-resume.cmd linkedin-pdf path\to\Profile.pdf another_template.tex
```

The customized PDF is generated in `build/` using the resume name and a timestamp:

```text
build/John_Roe_20260925-113500.pdf
```

If you update `user-resources/user-info.tex`, `user-resources/linkedin-profile.json`, or the LinkedIn PDF, run the matching build command again and open the newest timestamped PDF from `build/`.

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
- Use `scripts/build-resume.cmd` to compile the standalone ready-made template into a timestamped PDF in `build/`.
- Use `scripts/build-user-resume.cmd user-info` to generate `build/custom_resume_template.tex` from a ready-made template and compile it with values from `user-resources/user-info.tex`.
- Use `scripts/build-user-resume.cmd linkedin` to generate the resume from `user-resources/linkedin-profile.json`.
- Use `scripts/build-user-resume.cmd linkedin-pdf path\to\Profile.pdf` to generate a resume from a locally saved LinkedIn profile PDF through the coordinate-aware line extractor and classifier.

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
- Local LinkedIn PDF import with generated profile data
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
