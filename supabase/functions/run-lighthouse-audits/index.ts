// Edge Function: run-lighthouse-audits
// Weekly cron: fetches PageSpeed Insights scores for all active sites.
// Copies current scores to *_prev, writes new scores, inserts site_events.
// Stagger: if client count > 57, each quote audited on a fixed day of week (row_number % 7).
// PSI errors are logged + skipped — function does not crash.

import { createClient } from 'jsr:@supabase/supabase-js@2';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

async function fetchPsiScores(siteUrl: string, apiKey: string): Promise<{
  performance: number;
  accessibility: number;
  bestPractices: number;
  seo: number;
} | null> {
  const psiUrl = `https://www.googleapis.com/pagespeedonline/v5/runPagespeed?url=${encodeURIComponent(siteUrl)}&key=${apiKey}&strategy=mobile&category=performance&category=accessibility&category=best-practices&category=seo`;

  const resp = await fetch(psiUrl);
  if (!resp.ok) {
    console.error(`PSI error for ${siteUrl}: HTTP ${resp.status}`);
    return null;
  }

  const json = await resp.json();
  const cats = json.lighthouseResult?.categories;
  if (!cats) {
    console.error(`PSI no categories for ${siteUrl}`);
    return null;
  }

  return {
    performance: Math.round((cats.performance?.score ?? 0) * 100),
    accessibility: Math.round((cats.accessibility?.score ?? 0) * 100),
    bestPractices: Math.round((cats['best-practices']?.score ?? 0) * 100),
    seo: Math.round((cats.seo?.score ?? 0) * 100),
  };
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const apiKey = Deno.env.get('PAGESPEED_API_KEY');
    if (!apiKey) {
      return new Response(JSON.stringify({ error: 'PAGESPEED_API_KEY not configured.' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { data: quotes, error } = await supabase
      .from('quotes')
      .select('id, site_url, lighthouse_performance, lighthouse_accessibility, lighthouse_best_practices, lighthouse_seo')
      .in('status', ['pending', 'deposit_paid', 'fully_paid', 'active'])
      .not('site_url', 'is', null);

    if (error) {
      console.error('run-lighthouse-audits fetch quotes error:', error);
      return new Response(JSON.stringify({ error: 'Failed to fetch quotes.' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (!quotes || quotes.length === 0) {
      return new Response(JSON.stringify({ audited: 0 }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const dowNow = new Date().getDay(); // 0=Sun..6=Sat
    const useStagger = quotes.length > 57;

    let audited = 0;
    let skipped = 0;
    let failed = 0;

    for (let i = 0; i < quotes.length; i++) {
      const quote = quotes[i];

      // Stagger: only audit this quote if today is its designated day
      if (useStagger && i % 7 !== dowNow) {
        skipped++;
        continue;
      }

      try {
        const scores = await fetchPsiScores(quote.site_url!, apiKey);
        if (!scores) {
          failed++;
          continue;
        }

        // Copy current → prev, write new scores
        await supabase
          .from('quotes')
          .update({
            lighthouse_performance_prev: quote.lighthouse_performance,
            lighthouse_accessibility_prev: quote.lighthouse_accessibility,
            lighthouse_best_practices_prev: quote.lighthouse_best_practices,
            lighthouse_seo_prev: quote.lighthouse_seo,
            lighthouse_performance: scores.performance,
            lighthouse_accessibility: scores.accessibility,
            lighthouse_best_practices: scores.bestPractices,
            lighthouse_seo: scores.seo,
            last_audited_at: new Date().toISOString(),
          })
          .eq('id', quote.id);

        await supabase.from('site_events').insert({
          quote_id: quote.id,
          event_type: 'audit_completed',
          payload: {
            performance: scores.performance,
            accessibility: scores.accessibility,
            best_practices: scores.bestPractices,
            seo: scores.seo,
            prev_performance: quote.lighthouse_performance,
            prev_accessibility: quote.lighthouse_accessibility,
            prev_best_practices: quote.lighthouse_best_practices,
            prev_seo: quote.lighthouse_seo,
          },
        });

        audited++;
      } catch (err) {
        console.error(`run-lighthouse-audits: error auditing ${quote.site_url}:`, err);
        failed++;
      }
    }

    return new Response(JSON.stringify({ audited, skipped, failed }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('run-lighthouse-audits error:', err);
    return new Response(JSON.stringify({ error: 'Internal server error.' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
