import { createClient } from "npm:@supabase/supabase-js@2.49.1";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SECRET_KEYS_RAW = Deno.env.get("SUPABASE_SECRET_KEYS");

if (!SUPABASE_URL) throw new Error("SUPABASE_URL is required");
if (!SECRET_KEYS_RAW) throw new Error("SUPABASE_SECRET_KEYS is required");

const SECRET_KEYS = JSON.parse(SECRET_KEYS_RAW) as Record<string, string>;
const SECRET_KEY = SECRET_KEYS.default;
if (!SECRET_KEY) throw new Error('Secret key "default" is required in SUPABASE_SECRET_KEYS');

const admin = createClient(SUPABASE_URL, SECRET_KEY, {
  auth: { autoRefreshToken: false, persistSession: false },
});

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: corsHeaders,
  });
}

function getBearerToken(req: Request): string | null {
  const header = req.headers.get("authorization");
  if (!header) return null;
  const match = header.match(/^Bearer\s+(.+)$/i);
  return match?.[1] ?? null;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const token = getBearerToken(req);
  if (!token) return json({ error: "Missing bearer token" }, 401);

  // The platform verifies JWTs by default; this additionally resolves the caller's user ID.
  const { data: userData, error: userError } = await admin.auth.getUser(token);
  if (userError || !userData.user) return json({ error: "Unauthorized" }, 401);

  const userId = userData.user.id;

  // Remove only user-owned personal/application data requested by the account-deletion policy.
  // bookings and payments are intentionally not touched.
  const deleteOperations = [
    ["points_transactions", admin.from("points_transactions").delete().eq("user_id", userId)],
    ["user_vouchers", admin.from("user_vouchers").delete().eq("user_id", userId)],
    ["notifications", admin.from("notifications").delete().eq("user_id", userId)],
    ["notification_settings", admin.from("notification_settings").delete().eq("user_id", userId)],
    ["favorites", admin.from("favorites").delete().eq("user_id", userId)],
  ] as const;

  for (const [table, operation] of deleteOperations) {
    const { error } = await operation;
    if (error) {
      console.error(`Failed deleting ${table}`, { userId, error: error.message });
      return json({ error: "Account anonymization failed" }, 500);
    }
  }

  const { error: profileError } = await admin
    .from("profiles")
    .update({
      full_name: "Deleted User",
      phone: null,
      email: null,
      avatar_url: null,
      fcm_token: null,
    })
    .eq("id", userId);

  if (profileError) {
    console.error("Failed anonymizing profile", { userId, error: profileError.message });
    return json({ error: "Account anonymization failed" }, 500);
  }

  // Disable future authentication without deleting the auth record.
  const { error: banError } = await admin.auth.admin.updateUserById(userId, {
    ban_duration: "876000h",
  });

  if (banError) {
    console.error("Failed disabling auth account", { userId, error: banError.message });
    return json({ error: "Account data anonymized, but auth disabling failed" }, 500);
  }

  return json({
    success: true,
    message: "Account anonymized and authentication disabled",
  });
});
