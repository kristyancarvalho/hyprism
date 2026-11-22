import type { APIRoute } from 'astro';

export const GET: APIRoute = ({ site }) => {
  const sitemap = site ? `Sitemap: ${new URL('/sitemap.xml', site)}\n` : '';
  return new Response(`User-agent: *\nAllow: /\n${sitemap}`, { headers: { 'content-type': 'text/plain; charset=utf-8' } });
};
