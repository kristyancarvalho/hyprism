import releases from '../data/releases.json';
import type { APIRoute } from 'astro';
import { getCollection } from 'astro:content';

export const GET: APIRoute = async ({ site }) => {
  const docs = await getCollection('docs');
  const paths = site ? ['/', '/docs/', '/gallery/', '/releases/', ...docs.map((doc) => `/docs/${doc.id}/`), ...releases.map((release) => `/releases/${release.tag}/`)] : [];
  const urls = paths.map((path) => `  <url><loc>${new URL(path, site!)}</loc></url>`).join('\n');
  return new Response(`<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${urls}\n</urlset>`, { headers: { 'content-type': 'application/xml; charset=utf-8' } });
};
