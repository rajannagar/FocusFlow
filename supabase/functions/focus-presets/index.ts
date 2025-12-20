// supabase/functions/focus-presets/index.ts
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ message: "Missing Authorization header" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    // IMPORTANT: Forward the user's JWT so RLS + auth.uid() work
    const supabase = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    // Validate token
    const { data: userData, error: userErr } = await supabase.auth.getUser();
    if (userErr || !userData?.user) {
      return new Response(JSON.stringify({ message: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const userId = userData.user.id;

    // ---------- GET: fetch presets + active preset id ----------
    if (req.method === "GET") {
      const { data: presets, error: presetsErr } = await supabase
        .from("focus_presets")
        .select(
          "id,name,duration_seconds,sound_id,emoji,is_system_default,theme_raw,external_music_app_raw,sort_order"
        )
        .eq("user_id", userId)
        .order("sort_order", { ascending: true });

      if (presetsErr) {
        return new Response(JSON.stringify({ message: "Forbidden", details: presetsErr.message }), {
          status: 403,
          headers: { "Content-Type": "application/json" },
        });
      }

      const { data: settings, error: settingsErr } = await supabase
        .from("focus_preset_settings")
        .select("active_preset_id")
        .eq("user_id", userId)
        .maybeSingle();

      if (settingsErr) {
        return new Response(JSON.stringify({ message: "Forbidden", details: settingsErr.message }), {
          status: 403,
          headers: { "Content-Type": "application/json" },
        });
      }

      return new Response(
        JSON.stringify({
          presets: presets ?? [],
          active_preset_id: settings?.active_preset_id ?? null,
        }),
        {
          status: 200,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    // ---------- POST: upsert presets + active preset id ----------
    if (req.method === "POST") {
      const body = await req.json().catch(() => ({}));

      const incomingPresets = Array.isArray(body.presets) ? body.presets : [];
      const activePresetId = body.active_preset_id ?? null;

      // Force user_id on every row (no spoofing)
      const rows = incomingPresets.map((p: any) => ({
        user_id: userId,
        id: p.id,
        name: p.name ?? "Untitled",
        duration_seconds: Number(p.duration_seconds ?? 25 * 60),
        sound_id: p.sound_id ?? "",
        emoji: p.emoji ?? null,
        is_system_default: Boolean(p.is_system_default ?? false),
        theme_raw: p.theme_raw ?? null,
        external_music_app_raw: p.external_music_app_raw ?? null,
        sort_order: Number(p.sort_order ?? 0),
      }));

      // 1) Upsert presets
      if (rows.length > 0) {
        const { error: upsertErr } = await supabase
          .from("focus_presets")
          .upsert(rows, { onConflict: "user_id,id" });

        if (upsertErr) {
          return new Response(JSON.stringify({ message: "Forbidden", details: upsertErr.message }), {
            status: 403,
            headers: { "Content-Type": "application/json" },
          });
        }
      }

      // 2) Delete presets removed locally (mirror behavior)
      // If client sends empty list, wipe all cloud presets for this user.
      if (rows.length === 0) {
        const { error: delAllErr } = await supabase
          .from("focus_presets")
          .delete()
          .eq("user_id", userId);

        if (delAllErr) {
          return new Response(JSON.stringify({ message: "Forbidden", details: delAllErr.message }), {
            status: 403,
            headers: { "Content-Type": "application/json" },
          });
        }
      } else {
        const ids = rows.map((r) => `'${r.id}'`).join(",");
        // delete where user_id = userId AND id NOT IN (ids...)
        const { error: delErr } = await supabase
          .from("focus_presets")
          .delete()
          .eq("user_id", userId)
          .not("id", "in", `(${ids})`);

        if (delErr) {
          return new Response(JSON.stringify({ message: "Forbidden", details: delErr.message }), {
            status: 403,
            headers: { "Content-Type": "application/json" },
          });
        }
      }

      // 3) Upsert active preset setting (one row per user)
      const { error: settingsUpsertErr } = await supabase
        .from("focus_preset_settings")
        .upsert(
          { user_id: userId, active_preset_id: activePresetId },
          { onConflict: "user_id" }
        );

      if (settingsUpsertErr) {
        return new Response(
          JSON.stringify({ message: "Forbidden", details: settingsUpsertErr.message }),
          { status: 403, headers: { "Content-Type": "application/json" } }
        );
      }

      // Return fresh state
      const { data: presets, error: presetsErr } = await supabase
        .from("focus_presets")
        .select(
          "id,name,duration_seconds,sound_id,emoji,is_system_default,theme_raw,external_music_app_raw,sort_order"
        )
        .eq("user_id", userId)
        .order("sort_order", { ascending: true });

      if (presetsErr) {
        return new Response(JSON.stringify({ message: "Forbidden", details: presetsErr.message }), {
          status: 403,
          headers: { "Content-Type": "application/json" },
        });
      }

      return new Response(
        JSON.stringify({
          presets: presets ?? [],
          active_preset_id: activePresetId,
        }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    return new Response(JSON.stringify({ message: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ message: "Server error", details: String(e) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
