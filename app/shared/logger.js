// Client-side logger that sends to Supabase
//
// Buffer-Strategie:
// - MAX_BUFFER (100) als harter Cap, damit bei wiederholtem Insert-Fail
//   (z.B. Session expired, RLS reject) der Puffer nicht unbegrenzt wächst.
// - Bei Flush-Fail: erste MAX_BUFFER Einträge bleiben erhalten (älteste
//   wenn Puffer voll wird → werden gedroppt).
// - Errors triggern Flush, aber respektieren MIN_RETRY_MS Backoff um
//   Spam-Loops zu vermeiden.
const MAX_BUFFER = 100;
const MIN_RETRY_MS = 5000;

export class AppLogger {
  constructor(supabase, source) {
    this.supabase = supabase;
    this.source = source;
    this.buffer = [];
    this._lastFailAt = 0;
    this.flushInterval = setInterval(() => this.flush(), 10000); // flush every 10s
  }

  log(level, message, details = null) {
    const entry = { level, source: this.source, message, details, created_at: new Date().toISOString() };
    console[level === 'error' ? 'error' : level === 'warn' ? 'warn' : 'log'](`[${this.source}] ${message}`, details || '');
    this.buffer.push(entry);
    // Hard cap: drop oldest beyond MAX_BUFFER.
    if (this.buffer.length > MAX_BUFFER) this.buffer.splice(0, this.buffer.length - MAX_BUFFER);
    // Errors trigger immediate flush, aber Backoff seit letztem Fail.
    if (level === 'error' && (Date.now() - this._lastFailAt) > MIN_RETRY_MS) {
      this.flush();
    }
  }

  info(msg, details) { this.log('info', msg, details); }
  warn(msg, details) { this.log('warn', msg, details); }
  error(msg, details) { this.log('error', msg, details); }

  async flush() {
    if (this.buffer.length === 0) return;
    const entries = [...this.buffer];
    this.buffer = [];
    try {
      const { error } = await this.supabase.from('app_logs').insert(entries);
      if (error) throw error;
      this._lastFailAt = 0;
    } catch (e) {
      console.error('Failed to flush logs:', e);
      this._lastFailAt = Date.now();
      // Re-add bis MAX_BUFFER, älteste droppen wenn nötig.
      const merged = [...entries, ...this.buffer];
      this.buffer = merged.length > MAX_BUFFER
        ? merged.slice(merged.length - MAX_BUFFER)
        : merged;
    }
  }
}
