import { fetchMatch, frenchWhen, supportersLine, appLink, APP_URL } from '../lib/match.js';

export const config = { runtime: 'edge' };

const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

export default async function handler(req) {
  const url = new URL(req.url);
  const id = url.searchParams.get('id');
  const m = await fetchMatch(id);
  const target = m ? appLink(m.id) : APP_URL;
  const title = m ? m.title : 'FanZone';
  const desc = m
    ? `${frenchWhen(m.date, m.time)}, ${m.venue}. ${supportersLine(m)} On y va ensemble ?`
    : 'Les matchs du coin, et les collectifs pour y aller ensemble.';
  const image = `${url.origin}/og/${m ? m.id : 0}.png`;
  const html = `<!DOCTYPE html>
<html lang="fr"><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(title)}, sur FanZone</title>
<meta name="description" content="${esc(desc)}">
<meta property="og:type" content="website">
<meta property="og:site_name" content="FanZone">
<meta property="og:locale" content="fr_FR">
<meta property="og:title" content="${esc(title)}">
<meta property="og:description" content="${esc(desc)}">
<meta property="og:url" content="${esc(url.origin + url.pathname)}">
<meta property="og:image" content="${esc(image)}">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="${esc(title)}">
<meta name="twitter:description" content="${esc(desc)}">
<meta name="twitter:image" content="${esc(image)}">
<meta name="theme-color" content="#2B1A12">
<link rel="icon" href="${APP_URL}favicon.png">
<style>
  body{margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;background:#2B1A12;color:#FFF3E0;font:600 17px/1.4 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;text-align:center}
  a{color:#FFB420}
</style>
<script>location.replace(${JSON.stringify(target)});</script>
</head><body>
<p>On t'emmène au match.<br><a href="${esc(target)}">Ouvrir FanZone</a></p>
</body></html>`;
  return new Response(html, {
    status: m ? 200 : 404,
    headers: { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'public, max-age=60, s-maxage=120' },
  });
}
