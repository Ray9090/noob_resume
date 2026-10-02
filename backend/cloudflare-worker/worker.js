const DEFAULT_WORKFLOW = "build-sample-pdfs.yml";

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
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, X-Noob-Trigger-Key",
    "Vary": "Origin"
  };
}

export default {
  async fetch(request, env) {
    const corsHeaders = getCorsHeaders(request, env);
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    if (url.pathname !== "/trigger-ci") {
      return jsonResponse({ error: "Not found" }, 404, corsHeaders);
    }

    if (request.method !== "POST") {
      return jsonResponse({ error: "Method not allowed" }, 405, corsHeaders);
    }

    const triggerKey = request.headers.get("X-Noob-Trigger-Key") || "";
    if (!env.CI_TRIGGER_KEY || triggerKey !== env.CI_TRIGGER_KEY) {
      return jsonResponse({ error: "Unauthorized" }, 401, corsHeaders);
    }

    if (!env.GITHUB_TOKEN) {
      return jsonResponse({ error: "GITHUB_TOKEN is not configured" }, 500, corsHeaders);
    }

    const owner = env.GITHUB_OWNER || "Ray9090";
    const repo = env.GITHUB_REPO || "noob_resume";
    const workflow = env.GITHUB_WORKFLOW || DEFAULT_WORKFLOW;
    const body = await request.json().catch(() => ({}));
    const ref = body.ref || env.GITHUB_REF || "main";

    const response = await fetch(`https://api.github.com/repos/${owner}/${repo}/actions/workflows/${workflow}/dispatches`, {
      method: "POST",
      headers: {
        "Accept": "application/vnd.github+json",
        "Authorization": `Bearer ${env.GITHUB_TOKEN}`,
        "Content-Type": "application/json",
        "User-Agent": "noob-resume-pages-trigger",
        "X-GitHub-Api-Version": "2022-11-28"
      },
      body: JSON.stringify({ ref })
    });

    if (!response.ok) {
      const details = await response.text();
      return jsonResponse({ error: "GitHub workflow dispatch failed", details }, response.status, corsHeaders);
    }

    return jsonResponse({
      ok: true,
      ref,
      actions_url: `https://github.com/${owner}/${repo}/actions/workflows/${workflow}`
    }, 200, corsHeaders);
  }
};
