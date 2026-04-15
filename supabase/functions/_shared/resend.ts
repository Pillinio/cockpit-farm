// Shared Resend email helper
// Usage: import { sendEmail } from "../_shared/resend.ts";

const RESEND_API_URL = "https://api.resend.com/emails";

export async function sendEmail(options: {
  to: string | string[];
  subject: string;
  html: string;
  from?: string;
}): Promise<{ sent: boolean; error?: string }> {
  // EMAIL SAFETY: Only send to whitelisted addresses until fully tested
  // Set RESEND_WHITELIST to a comma-separated list of allowed emails
  // If not set or empty, falls back to DRY RUN (no emails sent)
  const whitelist = (Deno.env.get("RESEND_WHITELIST") || "").split(",").map(e => e.trim().toLowerCase()).filter(Boolean);
  const recipients = Array.isArray(options.to) ? options.to : [options.to];

  if (whitelist.length === 0) {
    // No whitelist = full dry run
    console.log(`[DRY RUN] Email NOT sent — To: ${recipients.join(", ")} | Subject: ${options.subject}`);
    return { sent: true, error: "dry_run" };
  }

  // Filter recipients to only whitelisted emails
  const allowedRecipients = recipients.filter(r => whitelist.includes(r.toLowerCase()));
  const blockedRecipients = recipients.filter(r => !whitelist.includes(r.toLowerCase()));

  if (blockedRecipients.length > 0) {
    console.log(`[WHITELIST] Blocked: ${blockedRecipients.join(", ")} | Allowed: ${allowedRecipients.join(", ") || "none"}`);
  }

  if (allowedRecipients.length === 0) {
    console.log(`[WHITELIST] All recipients blocked — Subject: ${options.subject}`);
    return { sent: true, error: "all_recipients_blocked" };
  }

  // Override recipients with only allowed ones
  options.to = allowedRecipients;

  const apiKey = Deno.env.get("RESEND_API_KEY");
  if (!apiKey) return { sent: false, error: "RESEND_API_KEY not set" };

  const from =
    options.from ||
    Deno.env.get("CALENDAR_NOTIFY_FROM") ||
    "kalender@erichsfelde.farm";

  try {
    const res = await fetch(RESEND_API_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        from,
        to: Array.isArray(options.to) ? options.to : [options.to],
        subject: options.subject,
        html: options.html,
      }),
    });

    if (!res.ok) {
      const errText = await res.text();
      return { sent: false, error: `Resend ${res.status}: ${errText}` };
    }
    return { sent: true };
  } catch (err) {
    return { sent: false, error: (err as Error).message };
  }
}
