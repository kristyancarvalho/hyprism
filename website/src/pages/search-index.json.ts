import type { APIRoute } from 'astro';
import { getCollection } from 'astro:content';

export const GET: APIRoute = async () => {
  const docs = await getCollection('docs');
  const index = docs.map((doc) => ({
    slug: doc.id,
    title: doc.data.title ?? doc.id,
    description: doc.data.description ?? '',
    category: doc.data.category ?? 'Guides',
    text: (doc.body ?? '').replace(/```[\s\S]*?```/g, ' ').replace(/[`*_>#|\[\]()]/g, ' ').replace(/\s+/g, ' ').slice(0, 12000),
  }));
  return new Response(JSON.stringify(index), { headers: { 'content-type': 'application/json; charset=utf-8' } });
};
