import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.48.0";

type AuthResponse = {
  user: { id: string; email: string | null };
  access_token: string | null;
  refresh_token: string | null;
};

function corsHeaders() {
  return {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization, apikey",
  };
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: corsHeaders(),
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: corsHeaders() });
  if (req.method !== "POST") return jsonResponse({ message: "Method not allowed" }, 405);

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const anonKey =
    Deno.env.get("SUPABASE_ANON_KEY") ??
    Deno.env.get("SUPABASE_ANON_PUBLIC_KEY") ??
    "";

  if (!supabaseUrl || !anonKey) {
    return jsonResponse(
      { message: "Missing SUPABASE_URL or SUPABASE_ANON_KEY env vars." },
      500,
    );
  }

  const supabase = createClient(supabaseUrl, anonKey, {
    auth: { persistSession: false },
  });

  try {
    const body = await req.json();
    const appleIdToken: string | undefined = body.apple_id_token;
    const emailFromClient: string | undefined = body.email;

    if (!appleIdToken) return jsonResponse({ message: "Missing apple_id_token" }, 400);

    const { data, error } = await supabase.auth.signInWithIdToken({
      provider: "apple",
      token: appleIdToken,
    });

    if (error || !data.user) {
      return jsonResponse(
        { message: error?.message ?? "Sign in with Apple failed" },
        401,
      );
    }

    const result: AuthResponse = {
      user: {
        id: data.user.id,
        email: data.user.email ?? emailFromClient ?? null,
      },
      access_token: data.session?.access_token ?? null,
      refresh_token: data.session?.refresh_token ?? null,
    };

    return jsonResponse(result, 200);
  } catch (err) {
    console.error("auth-apple unhandled error:", err);
    return jsonResponse({ message: "Internal server error" }, 500);
  }
});
