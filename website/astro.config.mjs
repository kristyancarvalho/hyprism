import { defineConfig } from 'astro/config';
import { unified } from '@astrojs/markdown-remark';
import { remarkDocLinks } from './src/lib/remark-doc-links.ts';

export default defineConfig({
  site: process.env.SITE_URL || undefined,
  markdown: {
    processor: unified({ remarkPlugins: [remarkDocLinks] }),
    shikiConfig: {
      themes: { light: 'gruvbox-light-medium', dark: 'gruvbox-dark-medium' },
      defaultColor: false,
      wrap: true,
    },
  },
});
