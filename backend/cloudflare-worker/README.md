# Cloudflare Worker CI Trigger

This backend lets the GitHub Pages site trigger the `Build Sample PDFs` workflow without exposing a GitHub token in browser code.

## Required secrets

Create a fine-grained GitHub token with access to `Ray9090/noob_resume` and repository permission:

- Actions: Read and write
- Metadata: Read

In Cloudflare Workers, set these secrets:

```powershell
wrangler secret put GITHUB_TOKEN
wrangler secret put CI_TRIGGER_KEY
```

`CI_TRIGGER_KEY` is a private passphrase you type into the website when triggering CI. It is not stored by the page.

## Deploy

```powershell
cd backend\cloudflare-worker
copy wrangler.toml.example wrangler.toml
wrangler deploy
```

After deployment, copy the Worker URL into the website trigger form, for example:

```text
https://noob-resume-ci-trigger.<your-subdomain>.workers.dev
```

## Request shape

The page sends:

```http
POST /trigger-ci
X-Noob-Trigger-Key: <your trigger key>
Content-Type: application/json

{"ref":"main"}
```

The Worker calls GitHub's workflow dispatch API for `.github/workflows/build-sample-pdfs.yml`.

## Security notes

- Never put `GITHUB_TOKEN` in `docs/` or browser JavaScript.
- Keep `CI_TRIGGER_KEY` private.
- Restrict `ALLOWED_ORIGIN` to `https://ray9090.github.io` for GitHub Pages.
- Rotate the GitHub token if it is ever exposed.
