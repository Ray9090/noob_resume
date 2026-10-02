const DEFAULT_WORKFLOW = "build-sample-pdfs.yml";
const ALLOWED_TEMPLATES = new Set(["template_1", "template_2", "maang_1", "fanng_1", "europass_1"]);

function jsonResponse(body, status = 200, corsHeaders = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders
    }
  });
}

function getCorsHeaders(request, env) {
  const origin = request.headers.get("Origin") || "";
  const allowedOrigin = env.ALLOWED_ORIGIN || "https://ray9090.github.io";
  const corsOrigin = origin === allowedOrigin ? origin : allowedOrigin;
  return {
    "Access-Control-Allow-Origin": corsOrigin,
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, X-Noob-Trigger-Key",
    "Vary": "Origin"
  };
}

function githubHeaders(env) {
  return {
    "Accept": "application/vnd.github+json",
    "Authorization": `Bearer ${env.GITHUB_TOKEN}`,
    "Content-Type": "application/json",
    "User-Agent": "noob-resume-pages-trigger",
    "X-GitHub-Api-Version": "2022-11-28"
  };
}

function getConfig(env) {
  return {
    owner: env.GITHUB_OWNER || "Ray9090",
    repo: env.GITHUB_REPO || "noob_resume",
    workflow: env.GITHUB_WORKFLOW || DEFAULT_WORKFLOW
  };
}

function isAuthorized(request, env) {
  const triggerKey = request.headers.get("X-Noob-Trigger-Key") || "";
  return Boolean(env.CI_TRIGGER_KEY && triggerKey === env.CI_TRIGGER_KEY);
}

async function triggerCi(request, env, corsHeaders) {
  const { owner, repo, workflow } = getConfig(env);
  const body = await request.json().catch(() => ({}));
  const ref = body.ref || env.GITHUB_REF || "main";
  const template = ALLOWED_TEMPLATES.has(body.template) ? body.template : "template_1";

  const response = await fetch(`https://api.github.com/repos/${owner}/${repo}/actions/workflows/${workflow}/dispatches`, {
    method: "POST",
    headers: githubHeaders(env),
    body: JSON.stringify({ ref, inputs: { template } })
  });

  if (!response.ok) {
    const details = await response.text();
    return jsonResponse({ error: "GitHub workflow dispatch failed", details }, response.status, corsHeaders);
  }

  return jsonResponse({ ok: true, ref, template }, 200, corsHeaders);
}

async function workflowStatus(request, env, corsHeaders) {
  const { owner, repo, workflow } = getConfig(env);
  const url = new URL(request.url);
  const branch = url.searchParams.get("branch") || env.GITHUB_REF || "main";
  const createdAfter = Date.parse(url.searchParams.get("created_after") || "");

  const runsUrl = new URL(`https://api.github.com/repos/${owner}/${repo}/actions/workflows/${workflow}/runs`);
  runsUrl.searchParams.set("branch", branch);
  runsUrl.searchParams.set("event", "workflow_dispatch");
  runsUrl.searchParams.set("per_page", "10");

  const response = await fetch(runsUrl, {
    method: "GET",
    headers: githubHeaders(env)
  });

  if (!response.ok) {
    const details = await response.text();
    return jsonResponse({ error: "GitHub workflow status failed", details }, response.status, corsHeaders);
  }

  const payload = await response.json();
  const run = (payload.workflow_runs || []).find((item) => {
    if (!Number.isFinite(createdAfter)) return true;
    return Date.parse(item.created_at) >= createdAfter;
  });

  return jsonResponse({
    ok: true,
    run: run ? {
      id: run.id,
      name: run.name,
      status: run.status,
      conclusion: run.conclusion,
      created_at: run.created_at,
      updated_at: run.updated_at
    } : null
  }, 200, corsHeaders);
}

export default {
  async fetch(request, env) {
    const corsHeaders = getCorsHeaders(request, env);
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    if (url.pathname !== "/trigger-ci" && url.pathname !== "/workflow-status") {
      return jsonResponse({ error: "Not found" }, 404, corsHeaders);
    }

    if (!isAuthorized(request, env)) {
      return jsonResponse({ error: "Unauthorized" }, 401, corsHeaders);
    }

    if (!env.GITHUB_TOKEN) {
      return jsonResponse({ error: "GITHUB_TOKEN is not configured" }, 500, corsHeaders);
    }

    if (url.pathname === "/trigger-ci" && request.method === "POST") {
      return triggerCi(request, env, corsHeaders);
    }

    if (url.pathname === "/workflow-status" && request.method === "GET") {
      return workflowStatus(request, env, corsHeaders);
    }

    return jsonResponse({ error: "Method not allowed" }, 405, corsHeaders);
  }
};