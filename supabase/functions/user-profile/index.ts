// supabase/functions/user-profile/index.ts

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.48.0";

type ProfileBody = {
  user_id?: string;              // preferred from client
  id?: string;                   // fallback (older client)
  full_name?: string | null;
  display_name?: string | null;
  email?: string | null;
  avatar_url?: string | null;
  preferred_theme?: string | null;
  timer_sound?: string | null;
  notifications_enabled?: boolean | null;
};

// Supabase URL + SERVICE ROLE key – this function runs on the server,
// so it is allowed to use the service role to bypass RLS.
const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const supabase = createClient(supabaseUrl, serviceRoleKey);

Deno.serve(async (req) => {
  const url = new URL(req.url);
  const method = req.method.toUpperCase();

  // ----------------------------------------------------
  // GET  /user-profile?user_id=...
  //   -> fetch a user's profile (or null if none)
  // ----------------------------------------------------
  if (method === "GET") {
    const userId = url.searchParams.get("user_id");

    if (!userId) {
      return json({ error: "Missing user_id" }, 400);
    }

    const { data, error } = await supabase
      .from("user_profiles")
      .select("*")
      .eq("id", userId)
      .maybeSingle();

    if (error) {
      console.error("Error selecting user_profile (GET):", error);
      return json({ error: error.message }, 400);
    }

    // If no row yet, return null so the app can treat it as "no profile yet".
    return json(data ?? null, 200);
  }

  // ----------------------------------------------------
  // POST /user-profile
  //   Body: { user_id / id, full_name?, display_name?, email?, ... }
  //
  //   -> merge into existing profile or create a new one
  // ----------------------------------------------------
  if (method === "POST") {
    let body: ProfileBody;

    try {
      body = (await req.json()) as ProfileBody;
    } catch (_err) {
      return json({ error: "Invalid JSON body" }, 400);
    }

    // Accept user_id, id, or query param ?user_id=...
    const userId =
      body.user_id ??
      body.id ??
      url.searchParams.get("user_id") ??
      null;

    if (!userId) {
      return json({ error: "Missing user_id" }, 400);
    }

    try {
      // 1) Fetch existing profile (if any)
      const { data: existing, error: selectError } = await supabase
        .from("user_profiles")
        .select("*")
        .eq("id", userId)
        .maybeSingle();

      if (selectError) {
        console.error("Error selecting user_profile (POST):", selectError);
        return json({ error: selectError.message }, 400);
      }

      // 2) Merge fields:
      //    - if a field is present in the request (even null), use that
      //    - else keep existing value
      //    - else default
      const merged = {
        id: userId,
        full_name:
          body.full_name !== undefined
            ? body.full_name
            : existing?.full_name ?? null,
        display_name:
          body.display_name !== undefined
            ? body.display_name
            : existing?.display_name ?? null,
        email:
          body.email !== undefined
            ? body.email
            : existing?.email ?? null,
        avatar_url:
          body.avatar_url !== undefined
            ? body.avatar_url
            : existing?.avatar_url ?? null,
        preferred_theme:
          body.preferred_theme !== undefined
            ? body.preferred_theme
            : existing?.preferred_theme ?? null,
        timer_sound:
          body.timer_sound !== undefined
            ? body.timer_sound
            : existing?.timer_sound ?? null,
        notifications_enabled:
          body.notifications_enabled !== undefined
            ? body.notifications_enabled
            : existing?.notifications_enabled ?? true,
      };

      // 3) Upsert by id
      const { data, error: upsertError } = await supabase
        .from("user_profiles")
        .upsert(merged, { onConflict: "id" })
        .select("*")
        .single();

      if (upsertError) {
        console.error("Error upserting user_profile:", upsertError);
        return json({ error: upsertError.message }, 400);
      }

      return json(data, 200);
    } catch (err) {
      console.error("Unexpected error in user-profile function:", err);
      return json({ error: "Unexpected error" }, 500);
    }
  }

  // Any other method
  return json({ error: "Only GET and POST are allowed" }, 405);
});

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
