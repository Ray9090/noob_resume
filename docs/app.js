const templates = [
  { id: "template_1", name: "Template 1", type: "ATS", badge: "ats", description: "Default clean software resume layout for profile-driven builds." },
  { id: "template_2", name: "Template 2", type: "ATS", badge: "ats", description: "Alternate ATS layout for the same reusable profile data." },
  { id: "maang_1", name: "MAANG 1", type: "Engineering", badge: "ats", description: "Compact engineering-focused layout inspired by high-signal SWE resumes." },
  { id: "fanng_1", name: "FANNG 1", type: "Engineering", badge: "ats", description: "A focused resume shape for technical roles and quick recruiter scanning." },
  { id: "europass_1", name: "Europass 1", type: "Europass", badge: "europass", description: "Europass-style layout with a dedicated renderer and section order." }
];

const templateGrid = document.querySelector("#templateGrid");
const templateSelect = document.querySelector("#templateSelect");
const buildCommand = document.querySelector("#buildCommand");

function renderTemplates() {
  templateGrid.innerHTML = templates.map((template) => `
    <article class="template-card">
      <span class="badge ${template.badge}">${template.type}</span>
      <h3>${template.name}</h3>
      <p>${template.description}</p>
      <code>${template.id}.tex</code>
    </article>
  `).join("");

  templateSelect.innerHTML = templates.map((template) => `
    <option value="${template.id}">${template.name}</option>
  `).join("");
}

function updateCommand() {
  buildCommand.textContent = `scripts\\build-user-resume.cmd linkedin ${templateSelect.value}`;
}

function copyText(elementId, button) {
  const target = document.querySelector(`#${elementId}`);
  if (!target) return;
  navigator.clipboard.writeText(target.textContent).then(() => {
    const original = button.textContent;
    button.textContent = "Copied";
    window.setTimeout(() => { button.textContent = original; }, 1200);
  });
}

function downloadProfileJson() {
  const form = document.querySelector("#profileForm");
  const data = new FormData(form);
  const profile = {
    name: data.get("name") || "Your Name",
    phoneDisplay: "",
    phoneLink: "",
    email: data.get("email") || "name@example.com",
    linkedinDisplay: (data.get("linkedin") || "").replace(/^https?:\/\//, ""),
    linkedinUrl: data.get("linkedin") || "",
    githubDisplay: (data.get("github") || "").replace(/^https?:\/\//, ""),
    githubUrl: data.get("github") || "",
    summary: data.get("summary") || "Short professional summary.",
    skills: {
      "Programming Languages": "Python, JavaScript, SQL",
      "Tools": "Git, GitHub Actions, LaTeX"
    },
    experience: [],
    projects: [],
    education: []
  };

  const blob = new Blob([JSON.stringify(profile, null, 2)], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = "linkedin-profile.json";
  document.body.appendChild(link);
  link.click();
  link.remove();
  URL.revokeObjectURL(url);
}

renderTemplates();
updateCommand();

templateSelect.addEventListener("change", updateCommand);
document.querySelectorAll("[data-copy]").forEach((button) => {
  button.addEventListener("click", () => copyText(button.dataset.copy, button));
});
document.querySelector("#downloadJson").addEventListener("click", downloadProfileJson);
