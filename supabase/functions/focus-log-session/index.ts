// supabase/functions/focus-log-session/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

type FocusSessionPayload = {
  userId: string;
  startedAt: string;       // ISO timestamp
  endedAt: string;         // ISO timestamp
  durationSeconds: number;
  label?: string | null;
  deviceId?: string | null;
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    const body = (await req.json()) as FocusSessionPayload;

    // Validate required fields
    if (!body.userId || !body.startedAt || !body.endedAt || !body.durationSeconds) {
      return new Response(
        JSON.stringify({ error: "Missing required fields." }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const duration = Number(body.durationSeconds);
    if (!Number.isFinite(duration) || duration <= 0) {
      return new Response(
        JSON.stringify({ error: "Invalid durationSeconds." }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Insert row into Supabase using the service role
    const insertRes = await fetch(`${SUPABASE_URL}/rest/v1/focus_sessions`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
        Prefer: "return=representation",
      },
      body: JSON.stringify({
        user_id: body.userId,
        started_at: body.startedAt,
        ended_at: body.endedAt,
        duration_seconds: duration,
        label: body.label ?? null,
        device_id: body.deviceId ?? null,
      }),
    });

    if (!insertRes.ok) {
      const err = await insertRes.text();
      console.error("Insert error:", err);
      return new Response(
        JSON.stringify({ error: "Failed to insert focus session." }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    const json = await insertRes.json();

    return new Response(JSON.stringify({ success: true, session: json[0] }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });

  } catch (err) {
    console.error("Unexpected error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error." }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
