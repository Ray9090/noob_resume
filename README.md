# Noob ATS Resume

## Description

Noob ATS Resume is a clean, ATS-friendly one-page LaTeX resume template for software engineering job applications. It is designed to keep resume content easy for applicant tracking systems to parse while still looking polished for recruiters.

The template includes structured sections for contact information, professional summary, technical skills, experience, optional projects, and education.

## Installation

Use one of these options:

```powershell
# Option 1: Prepare the local Windows LaTeX environment
scripts\setup-latex.cmd
```

```powershell
# After setup, list available templates
scripts\build-resume.cmd templates

# Compile a ready-made template locally
scripts\build-resume.cmd template_1.tex
```

```powershell
# Generate and compile a user-customized resume from user-info.tex and a selected template
scripts\build-user-resume.cmd user-info template_1.tex
```

```powershell
# Generate and compile from LinkedIn-style profile data and a selected template
scripts\build-user-resume.cmd linkedin template_1.tex
```

```text
Option 2: Upload resume-template/template_1.tex to Overleaf and compile it there.
```

## Usage

1. Choose a profile source: `user-info`, `linkedin`, or `linkedin-pdf`.
2. For `user-info`, edit `user-resources/user-info.tex`.
3. For `linkedin`, edit `user-resources/linkedin-profile.json`. This tracked file is the curated profile JSON; later parser improvements can update it from LinkedIn data.
4. Run `scripts\build-user-resume.cmd templates` to see available templates, then build with `scripts\build-user-resume.cmd user-info template_1.tex`, `scripts\build-user-resume.cmd linkedin template_1.tex`, or `scripts\build-user-resume.cmd linkedin-pdf path\to\Profile.pdf template_1.tex`.
5. Use the newest timestamped PDF from `build/`; the filename includes both the resume name and selected template.

## User Resources

The ready-made layout lives in `resume-template/template_1.tex`. It contains its own sample contact details and can compile by itself.

- `user-resources/user-info.tex` - edit this file to enter name, phone, email, LinkedIn, and GitHub values.
- `user-resources/linkedin-profile.example.json` - tracked example for LinkedIn-style profile data.
- `user-resources/linkedin-profile.json` - tracked curated profile JSON used by the `linkedin` build source.
- `resume-template/template_1.tex` - standalone ready-made Noob ATS Resume template with sample contact details.
- `build/custom_resume_template.tex` - generated during the custom build; do not edit or commit it.
- `build/profile-info.tex` - generated during LinkedIn-source builds; do not edit or commit it.
- `build/linkedin-profile.bbox.html` - generated coordinate-aware PDF extraction from `pdftotext -bbox-layout`; useful for parser debugging.
- `build/linkedin-profile.lines.json` - generated normalized line data with page, column, coordinates, and text.
- `build/linkedin-profile.txt` - generated readable line-by-line text extracted from a LinkedIn PDF.
- `build/linkedin-profile.generated.json` - generated profile data classified from the normalized LinkedIn PDF lines.

This keeps the template flow simple:

```text
resume-template/template_1.tex
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

The custom build replaces the profile block with the selected source at build time. For the `linkedin` source, it also replaces the marked resume body with generated summary, skills, experience, optional projects, and education sections from `user-resources/linkedin-profile.json`. No permanent custom template file is required.

To list and build ready-made templates from `resume-template/`:

```powershell
scripts\build-resume.cmd templates
scripts\build-resume.cmd template_1.tex
scripts\build-resume.cmd template_2.tex
```

To build the customized resume from a selected ready-made template plus `user-resources/user-info.tex`:

```powershell
scripts\build-user-resume.cmd templates
scripts\build-user-resume.cmd user-info template_1.tex
scripts\build-user-resume.cmd user-info template_2.tex
```

To build from `user-resources/linkedin-profile.json` and a selected template:

```powershell
scripts\build-user-resume.cmd linkedin template_1.tex
scripts\build-user-resume.cmd linkedin template_2.tex
```

To build from a LinkedIn profile PDF saved by the user and a selected template:

```powershell
scripts\build-user-resume.cmd linkedin-pdf path\to\Profile.pdf template_1.tex
scripts\build-user-resume.cmd linkedin-pdf path\to\Profile.pdf template_2.tex
```

The LinkedIn options read local data only; they do not log in to LinkedIn or scrape a profile page. The `linkedin-pdf` source uses a two-stage importer: first it extracts coordinate-aware PDF lines with `pdftotext -bbox-layout`, then it classifies those lines into contact details, summary, skills, experience, and education. It writes `build/linkedin-profile.bbox.html`, `build/linkedin-profile.lines.json`, `build/linkedin-profile.txt`, and `build/linkedin-profile.generated.json`, then compiles from the generated JSON. PDF parsing is still best-effort because LinkedIn can change the export layout, so review the generated JSON/PDF and refine with the JSON source if needed.

To build from a different template in `resume-template/`, pass the template filename:

```powershell
scripts\build-user-resume.cmd user-info another_template.tex
scripts\build-user-resume.cmd linkedin another_template.tex
scripts\build-user-resume.cmd linkedin-pdf path\to\Profile.pdf another_template.tex
```

The customized PDF is generated in `build/` using the resume name, selected template, and a timestamp:

```text
build/John_Roe_template_2_20260925-113500.pdf
```

If you update `user-resources/user-info.tex`, `user-resources/linkedin-profile.json`, or the LinkedIn PDF, run the matching build command again and open the newest timestamped PDF from `build/`.

Overleaf template link:

```text

```



## GitHub Pages Website

The static project website lives in `docs/` and can be hosted with GitHub Pages.

To enable it:

1. Open the repository on GitHub.
2. Go to `Settings` -> `Pages`.
3. Set source to `Deploy from a branch`.
4. Select branch `main` and folder `/docs`.
5. Save and wait for GitHub Pages to publish the site.

The site is static. It documents templates, local build commands, the manual GitHub Actions workflow, and includes a browser-only JSON starter helper. It does not process payments, store user data, or generate PDFs in the browser.

## GitHub Actions CI

This repository builds sample PDFs with GitHub Actions on pushes to `main`, pull requests, and manual workflow runs from the Actions tab.

The CI workflow uses a standard GitHub-hosted `ubuntu-latest` runner, installs TeX Live, builds each supported template with `user-resources/linkedin-profile.json`, and uploads the generated PDFs as short-lived workflow artifacts.

The workflow is intentionally read-only:

- It does not commit generated PDFs.
- It does not push changes back to the repository.
- Generated artifacts are retained for 7 days.

To inspect the CI output, open GitHub -> Actions -> Build Sample PDFs -> latest run -> Artifacts.

## Development

Keep the template simple and ATS-friendly:

- Use standard text sections.
- Avoid images, graphics, and complex tables.
- Keep canonical resume layouts in `resume-template/`.
- Do not commit generated PDFs or temporary LaTeX build files.
- Use `scripts/setup-latex.cmd` to install MiKTeX on Windows with `winget`, the official MiKTeX installer, or Chocolatey.
- Use `scripts/build-resume.cmd templates` to list layouts, then `scripts/build-resume.cmd template_1.tex` or `scripts/build-resume.cmd template_2.tex` to compile a standalone ready-made template into a timestamped PDF in `build/`.
- Use `scripts/build-user-resume.cmd user-info template_1.tex` or another selected template to generate `build/custom_resume_template.tex` and compile it with values from `user-resources/user-info.tex`.
- Use `scripts/build-user-resume.cmd linkedin template_1.tex` or another selected template to generate the resume from `user-resources/linkedin-profile.json`.
- Use `scripts/build-user-resume.cmd linkedin-pdf path\to\Profile.pdf template_1.tex` or another selected template to generate a resume from a locally saved LinkedIn profile PDF through the coordinate-aware line extractor and classifier.

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
