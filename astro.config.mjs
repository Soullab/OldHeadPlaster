// @ts-check
import { defineConfig } from 'astro/config';
import tailwindcss from '@tailwindcss/vite';
import node from '@astrojs/node';

// https://astro.build/config
export default defineConfig({
  output: 'hybrid',
  adapter: node({ mode: 'standalone' }),
  vite: {
    plugins: [tailwindcss()]
  }
});