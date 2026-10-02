const templates = [
  { id: "template_1", name: "Template 1", type: "ATS", badge: "ats", description: "Default clean software resume layout for profile-driven builds." },
  { id: "template_2", name: "Template 2", type: "ATS", badge: "ats", description: "Alternate ATS layout for the same reusable profile data." },
  { id: "maang_1", name: "MAANG 1", type: "Engineering", badge: "ats", description: "Compact engineering-focused layout inspired by high-signal SWE resumes." },
  { id: "fanng_1", name: "FANNG 1", type: "Engineering", badge: "ats", description: "A focused resume shape for technical roles and quick recruiter scanning." },
  { id: "europass_1", name: "Europass 1", type: "Europass", badge: "europass", description: "Europass-style layout with a dedicated renderer and section order." }
];

const endpoint = "https://noob-resume-ci-trigger.ray9090.workers.dev";
const templateGrid = document.querySelector("#templateGrid");
const triggerTemplateSelect = document.querySelector("#triggerTemplate");
const progressShell = document.querySelector("#progressShell");
const progressBar = document.querySelector("#buildProgressBar");
const progressLabel = document.querySelector("#buildProgressLabel");
const latestPdf = document.querySelector("#latestPdf");
const triggerButton = document.querySelector("#triggerCi");
let statusTimer;

function renderTemplates() {
  templateGrid.innerHTML = templates.map((template) => `
    <article class="template-card">
      <span class="badge ${template.badge}">${template.type}</span>
      <h3>${template.name}</h3>
      <p>${template.description}</p>
      <code>${template.id}.tex</code>
    </article>
  `).join("");

  triggerTemplateSelect.innerHTML = templates.map((template) => `
    <option value="${template.id}">${template.name}</option>
  `).join("");
}

function setProgress(percent, label) {
  progressShell.hidden = false;
  progressBar.style.width = `${percent}%`;
  progressLabel.textContent = label;
}

function renderPdfCard(latest) {
  latestPdf.innerHTML = `
    <strong>Latest PDF</strong>
    <span>${latest.template} generated ${latest.generated_at}</span>
    <div class="latest-actions">
      <a class="button primary" href="${latest.pdf_url}" target="_blank" rel="noreferrer">View PDF</a>
      <a class="button secondary" href="${latest.pdf_url}" download>Download PDF</a>
    </div>
  `;
}

async function loadLatestPdf() {
  try {
    const response = await fetch("generated/latest.json", { cache: "no-store" });
    if (!response.ok) return false;
    const latest = await response.json();
    renderPdfCard(latest);
    return true;
  } catch (_) {
    return false;
  }
}

async function waitForPublishedPdf(status, template) {
  status.textContent = "Build finished. Publishing PDF to the page...";
  setProgress(95, "Publishing PDF");

  for (let attempt = 0; attempt < 18; attempt += 1) {
    const loaded = await loadLatestPdf();
    if (loaded) {
      status.textContent = `PDF is ready for ${template}.`;
      setProgress(100, "PDF ready");
      return;
    }
    await new Promise((resolve) => window.setTimeout(resolve, 5000));
  }

  status.textContent = "Build finished, but the PDF is still publishing. Refresh the page in a moment.";
}

function progressForRun(run) {
  if (!run) return { percent: 18, label: "Waiting for GitHub Actions" };
  if (run.status === "queued" || run.status === "requested" || run.status === "pending") {
    return { percent: 25, label: "Queued" };
  }
  if (run.status === "in_progress") {
    return { percent: 70, label: "Building PDF" };
  }
  if (run.status === "completed" && run.conclusion === "success") {
    return { percent: 90, label: "Build complete" };
  }
  return { percent: 100, label: `Build ${run.conclusion || run.status}` };
}

async function pollWorkflow({ key, branch, template, createdAfter, status }) {
  window.clearInterval(statusTimer);

  statusTimer = window.setInterval(async () => {
    try {
      const url = new URL(`${endpoint}/workflow-status`);
      url.searchParams.set("branch", branch);
      url.searchParams.set("created_after", createdAfter);

      const response = await fetch(url, {
        headers: { "X-Noob-Trigger-Key": key }
      });
      const payload = await response.json().catch(() => ({}));
      if (!response.ok) {
        throw new Error(payload.error || `Status request failed with ${response.status}`);
      }

      const progress = progressForRun(payload.run);
      setProgress(progress.percent, progress.label);

      if (!payload.run) {
        status.textContent = "Build requested. Waiting for GitHub Actions to start...";
        return;
      }

      if (payload.run.status === "completed") {
        window.clearInterval(statusTimer);
        triggerButton.disabled = false;

        if (payload.run.conclusion === "success") {
          await waitForPublishedPdf(status, template);
        } else {
          status.textContent = `Build failed with conclusion: ${payload.run.conclusion}.`;
        }
        return;
      }

      status.textContent = `${progress.label} for ${template}...`;
    } catch (error) {
      window.clearInterval(statusTimer);
      triggerButton.disabled = false;
      status.textContent = `Could not check build status: ${error.message}`;
    }
  }, 5000);
}

async function triggerCiRun() {
  const form = document.querySelector("#triggerForm");
  const status = document.querySelector("#triggerStatus");
  const data = new FormData(form);
  const key = (data.get("key") || "").trim();
  const branch = (data.get("branch") || "main").trim();
  const template = (data.get("template") || "template_1").trim();
  const createdAfter = new Date(Date.now() - 15000).toISOString();

  if (!key) {
    status.textContent = "Enter your build key.";
    return;
  }

  triggerButton.disabled = true;
  setProgress(8, "Starting build");
  status.textContent = "Starting cloud build...";

  try {
    const response = await fetch(`${endpoint}/trigger-ci`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Noob-Trigger-Key": key
      },
      body: JSON.stringify({ ref: branch, template })
    });
    const payload = await response.json().catch(() => ({}));
    if (!response.ok) {
      throw new Error(payload.error || `Request failed with ${response.status}`);
    }

    status.textContent = `Build started for ${payload.template}.`;
    setProgress(15, "Build requested");
    pollWorkflow({ key, branch, template: payload.template, createdAfter, status });
  } catch (error) {
    triggerButton.disabled = false;
    setProgress(0, "Build not started");
    status.textContent = `Could not start build: ${error.message}`;
  }
}

renderTemplates();
document.querySelector("#triggerCi").addEventListener("click", triggerCiRun);
loadLatestPdf();