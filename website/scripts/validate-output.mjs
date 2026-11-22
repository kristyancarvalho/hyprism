import { readdir, readFile, access } from 'node:fs/promises';
import { join, relative, resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');
const dist = join(root, 'dist');
const docsRoot = resolve(root, '../docs');
const htmlFiles = [];
const walk = async (directory) => {
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) await walk(path);
    else if (entry.name.endsWith('.html')) htmlFiles.push(path);
  }
};
await walk(dist);

const docs = [];
const walkDocs = async (directory) => {
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) await walkDocs(path);
    else if (entry.name.endsWith('.md')) docs.push(relative(docsRoot, path));
  }
};
await walkDocs(docsRoot);
const routes = new Set(htmlFiles.map((path) => `/${relative(dist, path).replace(/index\.html$/, '').replace(/\.html$/, '')}`));
const failures = [];
for (const path of htmlFiles) {
  const html = await readFile(path, 'utf8');
  const references = [...html.matchAll(/(?:href|src)="([^"]+)"/g)].map((match) => match[1]);
  for (const reference of references) {
    if (!reference.startsWith('/') || reference.startsWith('//')) continue;
    const pathname = decodeURIComponent(reference.split(/[?#]/, 1)[0]);
    const normalized = pathname.endsWith('/') ? pathname : `${pathname}/`;
    const route = pathname.endsWith('.xml') || pathname.endsWith('.json') || pathname.endsWith('.txt') || /\.[a-z0-9]{2,5}$/i.test(pathname)
      ? join(dist, pathname.slice(1))
      : join(dist, pathname.slice(1), 'index.html');
    try {
      await access(route);
    } catch {
      if (!routes.has(normalized) && !routes.has(pathname)) failures.push(`${relative(dist, path)} references missing ${reference}`);
    }
  }
}

const search = JSON.parse(await readFile(join(dist, 'search-index.json'), 'utf8'));
for (const entry of docs) {
  const slug = entry.replace(/\.md$/, '').split(/\\/).join('/');
  if (!routes.has(`/docs/${slug}/`)) failures.push(`Missing generated docs route: ${slug}`);
  if (!search.some((item) => item.slug === slug)) failures.push(`Missing search index entry: ${slug}`);
}
if (!routes.has('/404')) failures.push('Missing 404 page');
if (failures.length) {
  process.stderr.write(`${failures.join('\n')}\n`);
  process.exitCode = 1;
} else {
  process.stdout.write(`Validated ${htmlFiles.length} HTML pages, ${docs.length} documentation routes, and ${search.length} search records.\n`);
}
