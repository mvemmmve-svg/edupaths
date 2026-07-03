// netlify/functions/edubot.mts
// MISSING FROM THE PREVIOUS UPDATE — Phase 5 (B1) server-side proxy.
// The client being Flutter changes nothing here: Netlify Functions are
// Node/TS regardless of the frontend framework, and the non-negotiable rule
// stands — the Anthropic key never ships in the Flutter bundle (never a
// --dart-define; QA row 14 greps the built JS for it).
//
// Env vars (Netlify dashboard, NOT in the repo):
//   ANTHROPIC_API_KEY, EDUBOT_MODEL (e.g. "claude-haiku-4-5"),
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
//
// Verify the current Anthropic request format/model IDs against
// https://docs.claude.com at implementation time (spec note).

import type { Context } from "@netlify/functions";
import { createClient } from "@supabase/supabase-js";

const MAX_INPUT_CHARS = 2000;
const MAX_TURNS = 12;
const RATE_LIMIT_PER_HOUR = 20;

const SYSTEM_PROMPT = `You are EduBot, the assistant inside EduPaths, a UK education-pathways app for students aged 14–19, their parents and careers advisers.
Scope: ONLY education and careers guidance — choosing between university and apprenticeship, entry requirements (UCAS points, A-levels, T Levels), degree apprenticeships, application timelines, comparing options in the EduPaths catalogue. Politely decline anything else and steer back to education topics.
Tone: friendly, clear, age-appropriate. Never request or store sensitive personal data (no date of birth, address, or exam candidate numbers).
Honesty: present trade-offs between routes evenhandedly; never push one. Always recommend verifying deadlines and requirements with official sources, and for personal decisions, talking to a school careers adviser or parent.
Links: only link to in-app pages using the paths provided in CONTEXT below (e.g. /universities/<slug>). Never invent URLs.
Length: 2–4 short paragraphs, then offer to go deeper.`;

export default async (req: Request, _ctx: Context) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  // --- Premium enforcement is server-side (B1.3) ---
  const jwt = (req.headers.get("authorization") ?? "").replace(/^Bearer\s+/i, "");
  if (!jwt) return json({ error: "Unauthorized" }, 401);

  const supabase = createClient(
    process.env.SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
    { auth: { persistSession: false } },
  );

  const { data: userData, error: userErr } = await supabase.auth.getUser(jwt);
  if (userErr || !userData?.user) return json({ error: "Unauthorized" }, 401);
  const userId = userData.user.id;

  const { data: ent } = await supabase
    .from("entitlements")
    .select("tier")
    .eq("user_id", userId)
    .maybeSingle();
  if (ent?.tier !== "premium") return json({ error: "Premium required" }, 403);

  // --- Rate limit (B1.4): 20 msgs/hour per user, stored in Supabase ---
  const hourAgo = new Date(Date.now() - 3600_000).toISOString();
  const { count } = await supabase
    .from("edubot_usage")
    .select("*", { count: "exact", head: true })
    .eq("user_id", userId)
    .gte("created_at", hourAgo);
  if ((count ?? 0) >= RATE_LIMIT_PER_HOUR) {
    return json({ error: "Rate limit reached", resetsInMinutes: 60 }, 429);
  }

  // --- Input caps (B1.4) ---
  let body: { messages?: { role: string; content: string }[] };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }
  const incoming = (body.messages ?? []).slice(-MAX_TURNS);
  if (!incoming.length) return json({ error: "No messages" }, 400);
  const last = incoming[incoming.length - 1];
  if (last.role !== "user" || last.content.length > MAX_INPUT_CHARS) {
    return json({ error: "Message too long or malformed" }, 400);
  }

  // --- RAG-lite grounding (B2): keyword match over the verified catalogue ---
  const terms = last.content.toLowerCase().split(/\W+/).filter((w) => w.length > 3);
  let contextBlock = "";
  if (terms.length) {
    const { data: matches } = await supabase
      .from("catalogue")
      .select("name, slug, type, key_data, website_url")
      .or(terms.map((t) => `name.ilike.%${t}%`).join(","))
      .limit(5);
    if (matches?.length) {
      contextBlock =
        "\n\nCONTEXT — matching EduPaths records (prefer these; link with the in-app path shown):\n" +
        matches
          .map(
            (m) =>
              `- ${m.name} (${m.type}) — in-app: /${m.type === "university" ? "universities" : "apprenticeships"}/${m.slug} — data: ${JSON.stringify(m.key_data)} — official: ${m.website_url}`,
          )
          .join("\n");
    }
  }

  // --- Forward to Anthropic with SSE streaming passthrough (B1.2) ---
  const upstream = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-api-key": process.env.ANTHROPIC_API_KEY!,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: process.env.EDUBOT_MODEL ?? "claude-haiku-4-5",
      max_tokens: 700,
      stream: true,
      system: SYSTEM_PROMPT + contextBlock,
      messages: incoming,
    }),
  });

  if (!upstream.ok || !upstream.body) {
    return json({ error: "EduBot is unavailable right now" }, 502);
  }

  // Log usage row for rate limiting + cost monitoring (fire-and-forget)
  supabase.from("edubot_usage").insert({ user_id: userId }).then(() => {});

  return new Response(upstream.body, {
    status: 200,
    headers: {
      "content-type": "text/event-stream",
      "cache-control": "no-cache",
    },
  });
};

function json(obj: unknown, status: number) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { "content-type": "application/json" },
  });
}
