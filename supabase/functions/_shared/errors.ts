// Shared error handling: log full context server-side, return sanitized
// response to the client so we don't leak API keys, JWTs, stack frames, etc.

type Logger = {
  error: (msg: string, details?: Record<string, unknown>) => Promise<void>;
};

const SENSITIVE_PATTERNS: RegExp[] = [
  /sk-ant-[A-Za-z0-9_-]+/g,      // Anthropic API keys
  /sbp_[A-Za-z0-9]+/g,           // Supabase service role keys
  /Bearer\s+[A-Za-z0-9._-]+/gi,  // Bearer tokens in error text
  /eyJ[A-Za-z0-9._-]{20,}/g,     // Anything that looks like a JWT
];

function redact(text: string): string {
  let out = text;
  for (const re of SENSITIVE_PATTERNS) out = out.replace(re, "[REDACTED]");
  // Trim huge upstream payloads
  if (out.length > 500) out = out.slice(0, 500) + "…";
  return out;
}

/**
 * Log full error context (redacted of secrets) and return a Response with
 * a minimal error message to the client.
 *
 * @param logger  createLogger() instance
 * @param err     the caught error
 * @param publicMessage  what the client should see (generic)
 * @param status  HTTP status
 * @param context extra key/values to include in the log entry
 */
export async function logAndReply(
  logger: Logger,
  err: unknown,
  publicMessage: string,
  status = 500,
  context: Record<string, unknown> = {},
): Promise<Response> {
  const raw = err instanceof Error ? err.message : String(err);
  const details: Record<string, unknown> = { ...context, raw: redact(raw) };
  try {
    await logger.error(publicMessage, details);
  } catch {
    console.error("[errors.logAndReply] logger failed", publicMessage, details);
  }
  return new Response(
    JSON.stringify({ error: publicMessage }),
    { status, headers: { "Content-Type": "application/json" } },
  );
}

/**
 * Wrap an `await`-ed Supabase insert/update where we don't want to abort the
 * whole request on failure (e.g. audit-trail writes) but we also don't want
 * silent swallows. Logs the failure, returns void.
 */
export async function tryAudit(
  logger: Logger,
  label: string,
  op: Promise<{ error: unknown } | null | undefined>,
): Promise<void> {
  try {
    const res = await op;
    if (res && (res as { error?: unknown }).error) {
      const errObj = (res as { error: unknown }).error;
      const msg = errObj instanceof Error ? errObj.message : String(errObj);
      await logger.error(`audit-write failed: ${label}`, { raw: redact(msg) });
    }
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    await logger.error(`audit-write threw: ${label}`, { raw: redact(msg) });
  }
}
