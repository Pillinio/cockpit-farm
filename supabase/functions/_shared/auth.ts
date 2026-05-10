// Shared auth helpers for Edge Functions.
//
// Two auth modes are accepted, both via `Authorization: Bearer <token>`:
//   1. User JWT — issued by Supabase Auth for signed-in users.
//   2. Service-role secret — used by GitHub Actions / backend scripts / pg_cron.
//      Accepts both legacy JWT (eyJ…) and new opaque (sb_secret_…) formats;
//      the token is constant-time-compared to SUPABASE_SERVICE_ROLE_KEY.
//
// Callers choose which modes they accept via the `allow` option.
//
// Usage:
//   const auth = await verifyAuth(req, adminClient, { allow: ['user', 'service'] });
//   if (!auth) return json({ error: 'unauthorized' }, 401);
//   if (auth.mode === 'user') { auth.userId, auth.role } else { /* service */ }

import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

export type AuthMode = "user" | "service";

export interface UserAuth {
  mode: "user";
  userId: string;
  role: string | null; // profiles.role (owner/manager/viewer/…)
  token: string;
}

export interface ServiceAuth {
  mode: "service";
  token: string;
}

export type AuthResult = UserAuth | ServiceAuth;

interface VerifyOpts {
  allow: AuthMode[];
  /** If true, user must have profiles.role in this set. */
  requireRole?: string[];
}

/** Decode a JWT payload WITHOUT verifying the signature. The payload is only
 *  used to pick an auth path (user vs. service) — the actual verification
 *  happens afterward by delegating to Supabase's auth server. Never trust
 *  anything here as authenticated. */
function decodeJwtPayload(token: string): Record<string, unknown> | null {
  const parts = token.split(".");
  if (parts.length !== 3) return null;
  try {
    const pad = (s: string) => s + "=".repeat((4 - (s.length % 4)) % 4);
    const b64 = pad(parts[1].replace(/-/g, "+").replace(/_/g, "/"));
    return JSON.parse(atob(b64));
  } catch {
    return null;
  }
}

export async function verifyAuth(
  req: Request,
  admin: SupabaseClient,
  opts: VerifyOpts,
): Promise<AuthResult | null> {
  const header = req.headers.get("Authorization") || "";
  if (!header.startsWith("Bearer ")) return null;
  const token = header.slice("Bearer ".length).trim();
  if (!token) return null;

  // ── Service role ──────────────────────────────────────────────────────────
  // Constant-time-compare the incoming token with the server's own
  // SERVICE_ROLE env var. The token may be a legacy JWT (eyJ…) or a new-format
  // opaque secret key (sb_secret_…); both are long random strings only the
  // rightful holder can know. Forged JWTs with unsigned role=service_role
  // claims fail this comparison.
  if (opts.allow.includes("service")) {
    const expected = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
    if (expected && constantTimeEq(token, expected)) {
      return { mode: "service", token };
    }
  }

  // ── User token: Supabase's getUser verifies signature server-side ─────────
  if (!opts.allow.includes("user")) return null;
  const payload = decodeJwtPayload(token);
  if (!payload) return null;

  const { data, error } = await admin.auth.getUser(token);
  if (error || !data?.user) return null;

  const { data: profile } = await admin
    .from("profiles")
    .select("role")
    .eq("id", data.user.id)
    .maybeSingle();
  const role = (profile?.role as string | null) ?? null;
  if (opts.requireRole && (!role || !opts.requireRole.includes(role))) {
    return null;
  }

  return { mode: "user", userId: data.user.id, role, token };
}

/** Constant-time string equality — avoids timing-oracle on the service key. */
function constantTimeEq(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}
