export interface Env {
  SITES_KV: KVNamespace;
}

interface SiteConfig {
  url: string;
  anonKey: string;
  table: string;
}

async function pingSite(name: string, config: SiteConfig): Promise<void> {
  try {
    // A real PostgREST query, not /auth/v1/health — Supabase's pause timer
    // only resets on database activity, and the auth health check never touches Postgres.
    const res = await fetch(`${config.url}/rest/v1/${config.table}?select=*&limit=1`, {
      headers: { apikey: config.anonKey, Authorization: `Bearer ${config.anonKey}` },
    });
    if (!res.ok) {
      console.error(`[keepalive] ${name} returned ${res.status}`);
    } else {
      console.log(`[keepalive] ${name} ok (${res.status})`);
    }
  } catch (err) {
    console.error(`[keepalive] ${name} failed:`, err);
  }
}

export default {
  async scheduled(_event: ScheduledEvent, env: Env): Promise<void> {
    const { keys } = await env.SITES_KV.list();

    await Promise.all(
      keys.map(async ({ name }) => {
        const raw = await env.SITES_KV.get(name);
        if (!raw) return;
        await pingSite(name, JSON.parse(raw) as SiteConfig);
      }),
    );
  },
};
