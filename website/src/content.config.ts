import { defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';
import { z } from 'astro/zod';

const docs = defineCollection({
  loader: glob({ pattern: '**/*.md', base: '../docs' }),
  schema: z.object({
    title: z.string().optional(),
    description: z.string().optional(),
    category: z.string().optional(),
    order: z.number().optional(),
    icon: z.string().optional(),
  }),
});

export const collections = { docs };
