import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// NOTE: We removed bcrypt because Edge Functions cannot use FFI.
// Instead we use WebCrypto (crypto.subtle) to hash the password with SHA-256.
// This is still hashed (not plain text), but for production you'd ideally
// switch to a stronger scheme like Argon2 via a service that supports it.

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

// Simple SHA-256 hashing using WebCrypto (no FFI, works in Edge Functions)
async function sha256Hex(input: string): Promise<string> {
  const data = new TextEncoder().encode(input);
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    // CORS preflight (optional)
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

  if (!email.includes("@") || !email.includes(".")) {
    return jsonResponse({ message: "Please enter a valid email address." }, 400);
  }

  if (password.length < 6) {
    return jsonResponse({ message: "Password must be at least 6 characters." }, 400);
  }

  try {
    // Hash the password with SHA-256 (no FFI)
    const passwordHash = await sha256Hex(password);
    const userId = crypto.randomUUID();

    const { error } = await supabase
      .from("users")
      .insert({
        id: userId,
        email,
        password_hash: passwordHash,
        is_guest: false,
      });

    if (error) {
      console.error("Insert error:", error);

      // 23505 = unique violation (email already exists)
      if ((error as any).code === "23505") {
        return jsonResponse(
          { message: "An account already exists for this email." },
          400,
        );
      }

      return jsonResponse(
        { message: "Error creating account. Please try again." },
        500,
      );
    }

    // Return shape that matches AuthAPIUser on iOS
    return jsonResponse({ id: userId, email }, 200);
  } catch (err) {
    console.error("Unhandled error in auth-email-signup:", err);
    return jsonResponse(
      { message: "Unexpected error while creating account." },
      500,
    );
  }
});
