import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

if (!supabaseUrl || !serviceRoleKey) {
  console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY env vars.");
}

const supabase = createClient(supabaseUrl, serviceRoleKey);

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
}

// Same SHA-256 helper we used in auth-email-signup
async function sha256Hex(input: string): Promise<string> {
  const data = new TextEncoder().encode(input);
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
      },
    });
  }

  if (req.method !== "POST") {
    return jsonResponse({ message: "Method not allowed" }, 405);
  }

  let payload: any;
  try {
    payload = await req.json();
  } catch {
    return jsonResponse({ message: "Invalid JSON body" }, 400);
  }

  const rawEmail = (payload.email ?? "").toString().trim();
  const email = rawEmail.toLowerCase();
  const password = (payload.password ?? "").toString();

  if (!email || !password) {
    return jsonResponse({ message: "Email and password are required." }, 400);
  }

  try {
    // Look up user by email
    const { data: user, error } = await supabase
      .from("users")
      .select("id, email, password_hash")
      .eq("email", email)
      .maybeSingle();

    if (error) {
      console.error("Query error in auth-email-login:", error);
      return jsonResponse(
        { message: "Error checking account. Please try again." },
        500,
      );
    }

    if (!user) {
      return jsonResponse(
        { message: "No account found for that email." },
        400,
      );
    }

    const passwordHash = await sha256Hex(password);

    if (passwordHash !== user.password_hash) {
      return jsonResponse(
        { message: "Incorrect email or password." },
        400,
      );
    }

    // Success – return shape that matches AuthAPIUser on iOS
    return jsonResponse(
      { id: user.id, email: user.email ?? email },
      200,
    );
  } catch (err) {
    console.error("Unhandled error in auth-email-login:", err);
    return jsonResponse(
      { message: "Unexpected error while logging in." },
      500,
    );
  }
});
