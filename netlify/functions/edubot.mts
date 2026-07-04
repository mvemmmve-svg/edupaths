// netlify/functions/edubot.mts — Phase 5 (B1) server-side proxy.
// The Anthropic key never ships in the Flutter bundle; it lives only in the
// Netlify env var ANTHROPIC_API_KEY.
//
// Env vars used (Netlify dashboard, NOT in the repo):
//   ANTHROPIC_API_KEY  (secret — required)
//   EDUBOT_MODEL       (optional, default "claude-haiku-4-5")
//   SUPABASE_URL, SUPABASE_ANON_KEY (already set for the build)
//
// Auth model: the client sends the user's Supabase JWT. We create a
// JWT-scoped client with the PUBLIC anon key, so Supabase RLS applies as
// that user — no service-role secret is needed anywhere.
//
// Tiers (matches the in-app pricing page):
//   free    →  5 messages per day
//   premium → 20 messages per hour

import type { Context } from "@netlify/functions";
import { createClient } from "@supabase/supabase-js";

const MAX_INPUT_CHARS = 2000;
const MAX_TURNS = 12;
const FREE_PER_DAY = 5;
const PREMIUM_PER_HOUR = 20;

const SYSTEM_PROMPT = `You are EduBot, the assistant inside EduPaths, a UK education-pathways app for students aged 14–19, their parents and careers advisers.
Scope: ONLY education and careers guidance — choosing between university and apprenticeship, entry requirements (UCAS points, A-levels, T Levels, BTECs, GCSEs), degree apprenticeships, application timelines, comparing options in the EduPaths catalogue. Politely decline anything else and steer back to education topics.
Tone: friendly, clear, age-appropriate. Never request or store sensitive personal data (no date of birth, address, or exam candidate numbers).
Honesty: present trade-offs between routes evenhandedly; never push one. Always recommend verifying deadlines and requirements with official sources, and for personal decisions, talking to a school careers adviser or parent.
Length: 2–4 short paragraphs, then offer to go deeper.`;

export default async (req: Request, _ctx: Context) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const jwt = (req.headers.get("authorization") ?? "").replace(/^Bearer\s+/i, "");
  if (!jwt) return json({ error: "Unauthorized" }, 401);

  // JWT-scoped client: all table reads/writes below run under the user's
  // own RLS policies (entitlements_own, usage_own).
  const supabase = createClient(
    process.env.SUPABASE_URL!,
    process.env.SUPABASE_ANON_KEY!,
    {
      auth: { persistSession: false },
      global: { headers: { Authorization: `Bearer ${jwt}` } },
    },
  );

  const { data: userData, error: userErr } = await supabase.auth.getUser(jwt);
  if (userErr || !userData?.user) return json({ error: "Unauthorized" }, 401);
  const userId = userData.user.id;

  // --- Tier lookup: missing row = free ---
  const { data: ent } = await supabase
    .from("entitlements")
    .select("tier")
    .eq("user_id", userId)
    .maybeSingle();
  const tier = ent?.tier === "premium" ? "premium" : "free";

  // --- Rate limit, per tier ---
  const windowStart = new Date(
    Date.now() - (tier === "premium" ? 3600_000 : 86_400_000),
  ).toISOString();
  const { count } = await supabase
    .from("edubot_usage")
    .select("*", { count: "exact", head: true })
    .eq("user_id", userId)
    .gte("created_at", windowStart);
  const limit = tier === "premium" ? PREMIUM_PER_HOUR : FREE_PER_DAY;
  if ((count ?? 0) >= limit) {
    return json({ error: "Rate limit reached", tier }, 429);
  }

  // --- Input caps ---
  let body: { messages?: { role: string; content: string }[] };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }
  const incoming = (body.messages ?? [])
    .filter((m) => m.role === "user" || m.role === "assistant")
    .slice(-MAX_TURNS);
  if (!incoming.length) return json({ error: "No messages" }, 400);
  const last = incoming[incoming.length - 1];
  if (last.role !== "user" || last.content.length > MAX_INPUT_CHARS) {
    return json({ error: "Message too long or malformed" }, 400);
  }

  // --- RAG-lite grounding over the real catalogue (careers + courses) ---
  const terms = last.content.toLowerCase().split(/\W+/).filter((w) => w.length > 3);
  let contextBlock = "";
  if (terms.length) {
    const orExpr = terms.slice(0, 6).map((t) => `name.ilike.%${t}%`).join(",");
    const { data: car } = await supabase
      .from("careers").select("name, category, avg_salary").or(orExpr).limit(4);
    const orExpr2 = terms.slice(0, 6).map((t) => `title.ilike.%${t}%`).join(",");
    const { data: cou } = await supabase
      .from("courses").select("title, url, institutions(name)").or(orExpr2).limit(4);
    const lines: string[] = [];
    for (const c of car ?? []) {
      lines.push(`- CAREER: ${c.name} (${c.category}) — avg salary £${c.avg_salary ?? "n/a"}`);
    }
    for (const c of cou ?? []) {
      const inst = (c as any).institutions?.name ?? "";
      lines.push(`- COURSE: ${c.title}${inst ? " at " + inst : ""} — official page: ${c.url}`);
    }
    if (lines.length) {
      contextBlock =
        "\n\nCONTEXT — matching EduPaths records (prefer these; only share the official page links shown):\n" +
        lines.join("\n");
    }
  }

  // --- Forward to Anthropic with SSE streaming passthrough ---
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

  // Log usage row for rate limiting (fire-and-forget)
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
