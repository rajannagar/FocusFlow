// supabase/functions/auth-apple/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface AuthAPIUser {
  id: string;
  email: string | null;
}

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  // Create a Supabase client using the service role key
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  const supabase = createClient(supabaseUrl, serviceRoleKey);

  try {
    const body = await req.json();
    const appleUserId: string | undefined = body.apple_user_id;
    const appleIdToken: string | undefined = body.apple_id_token;
    const emailFromClient: string | undefined = body.email;

    if (!appleUserId || !appleIdToken) {
      return new Response(
        JSON.stringify({ error: "Missing apple_user_id or apple_id_token" }),
        {
          headers: { "Content-Type": "application/json" },
          status: 400,
        },
      );
    }

    // Use Supabase Auth to sign in the user with the Apple ID token.
    // NOTE: For production you should also verify the token properly.
    const { data, error } = await supabase.auth.signInWithIdToken({
      provider: "apple",
      token: appleIdToken,
    });

    if (error || !data.user) {
      console.error("signInWithIdToken error:", error);
      return new Response(
        JSON.stringify({ error: error?.message ?? "Sign in with Apple failed" }),
        {
          headers: { "Content-Type": "application/json" },
          status: 401,
        },
      );
    }

    const user = data.user;

    const result: AuthAPIUser = {
      id: user.id,
      // Prefer the email from Supabase, fall back to what the client sent (might be null)
      email: user.email ?? emailFromClient ?? null,
    };

    return new Response(JSON.stringify(result), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (err) {
    console.error("auth-apple unhandled error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      {
        headers: { "Content-Type": "application/json" },
        status: 500,
      },
    );
  }
});
