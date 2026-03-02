#!/usr/bin/env node

// Generate SVG diagrams from Mermaid .mmd files using @mermaid-js/mermaid-cli.

import { run } from '@mermaid-js/mermaid-cli';
import { readdirSync, mkdirSync } from 'fs';
import { resolve, dirname, basename, extname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const diagramsDir = resolve(__dirname, '..', 'diagrams');
const outputDir = resolve(__dirname, '..', 'public', 'diagrams');

mkdirSync(outputDir, { recursive: true });

const files = readdirSync(diagramsDir).filter(f => f.endsWith('.mmd'));

for (const file of files) {
  const name = basename(file, extname(file));
  const input = resolve(diagramsDir, file);
  const output = resolve(outputDir, `${name}.svg`);
  console.log(`Generating ${name}.svg...`);
  await run(input, output, { puppeteerConfig: { headless: true } });
}

console.log(`Generated ${files.length} diagram(s) in ${outputDir}`);
