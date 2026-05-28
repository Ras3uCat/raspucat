import PostalMime from 'postal-mime';

interface Env {
  FORWARD_TO_EMAIL: string;
  SUPABASE_FUNCTION_URL: string;
  CF_WORKER_SECRET: string;
}

export default {
  async email(
    message: ForwardableEmailMessage,
    env: Env,
    ctx: ExecutionContext,
  ): Promise<void> {
    // Consume the raw stream into a buffer before any other operations.
    // ReadableStream can only be read once; postal-mime needs the bytes,
    // and message.forward() uses a separate internal handle so this is safe.
    const rawBuffer = await new Response(message.raw).arrayBuffer();

    // Forward to personal inbox. Await this so delivery is confirmed before
    // the function exits — Cloudflare drops the email if forward() is never called.
    await message.forward(env.FORWARD_TO_EMAIL);

    // Parse and capture the reply body in the background.
    // If the Supabase call fails the email was already delivered — no data loss.
    ctx.waitUntil(
      (async () => {
        try {
          const parser = new PostalMime();
          const parsed = await parser.parse(rawBuffer);

          const res = await fetch(env.SUPABASE_FUNCTION_URL, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'x-worker-secret': env.CF_WORKER_SECRET,
            },
            body: JSON.stringify({
              from: message.from,
              subject: parsed.subject ?? '',
              text: parsed.text ?? '',
              html: parsed.html ?? '',
            }),
          });

          if (!res.ok) {
            console.error('inbound-outreach-reply returned', res.status, await res.text());
          }
        } catch (err) {
          console.error('Failed to capture reply body:', err);
        }
      })(),
    );
  },
};
