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

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: corsHeaders() });
  if (req.method !== "POST") return jsonResponse({ message: "Method not allowed" }, 405);

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const anonKey =
    Deno.env.get("SUPABASE_ANON_KEY") ??
    Deno.env.get("SUPABASE_ANON_PUBLIC_KEY") ??
    "";

  if (!supabaseUrl || !anonKey) {
    console.error("Missing SUPABASE_URL or SUPABASE_ANON_KEY env vars.");
    return jsonResponse(
      { message: "Server misconfigured. Missing env vars." },
      500,
    );
  }

  const supabase = createClient(supabaseUrl, anonKey, {
    auth: { persistSession: false },
  });

  let payload: any;
  try {
    payload = await req.json();
  } catch {
    return jsonResponse({ message: "Invalid JSON body" }, 400);
  }

  const rawEmail = (payload.email ?? "").toString().trim();
  const email = rawEmail.toLowerCase();
  const password = (payload.password ?? "").toString();

  if (!email || !password) return jsonResponse({ message: "Email and password are required." }, 400);
  if (!email.includes("@") || !email.includes(".")) return jsonResponse({ message: "Please enter a valid email address." }, 400);
  if (password.length < 6) return jsonResponse({ message: "Password must be at least 6 characters." }, 400);

  try {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
    });

    if (error || !data.user) {
      return jsonResponse(
        { message: error?.message ?? "Error creating account." },
        400,
      );
    }

    const result: AuthResponse = {
      user: { id: data.user.id, email: data.user.email ?? email },
      // If email confirmation is ON, session may be null until verify + login.
      access_token: data.session?.access_token ?? null,
      refresh_token: data.session?.refresh_token ?? null,
    };

    return jsonResponse(result, 200);
  } catch (err) {
    console.error("Unhandled error in auth-email-signup:", err);
    return jsonResponse(
      { message: "Unexpected error while creating account." },
      500,
    );
  }
});
