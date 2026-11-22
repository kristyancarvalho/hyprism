import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';

const api = 'https://api.github.com/repos/kristyancarvalho/hyprism/releases?per_page=100';
const releases = [];
let page = 1;

while (true) {
  const response = await fetch(`${api}&page=${page}`, {
    headers: {
      accept: 'application/vnd.github+json',
      'x-github-api-version': '2022-11-28',
      'user-agent': 'hyprism-website-release-sync',
    },
  });
  if (!response.ok) throw new Error(`GitHub Releases API returned ${response.status}: ${await response.text()}`);
  const batch = await response.json();
  releases.push(...batch.filter((release) => !release.draft && !release.prerelease).map((release) => ({
    tag: release.tag_name,
    version: release.tag_name.replace(/^v/, ''),
    title: release.name || `Hyprism ${release.tag_name.replace(/^v/, '')}`,
    publishedAt: release.published_at,
    url: release.html_url,
    tagUrl: `https://github.com/kristyancarvalho/hyprism/tree/${encodeURIComponent(release.tag_name)}`,
    body: release.body || '',
  })));
  if (batch.length < 100) break;
  page += 1;
}

releases.sort((a, b) => Date.parse(b.publishedAt) - Date.parse(a.publishedAt));
const output = resolve(import.meta.dirname, '../src/data/releases.json');
await mkdir(dirname(output), { recursive: true });
await writeFile(output, `${JSON.stringify(releases, null, 2)}\n`);
process.stdout.write(`Imported ${releases.length} published releases into ${output}\n`);
