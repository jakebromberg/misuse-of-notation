#!/usr/bin/env node

// Generate SVG diagrams from D2 .d2 files using the d2 CLI.
// Requires: d2 installed (https://d2lang.com)
// Uses ELK layout for orthogonal routing with rounded corners.

import { execSync } from 'child_process';
import { readdirSync, mkdirSync } from 'fs';
import { resolve, dirname, basename, extname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const diagramsDir = resolve(__dirname, '..', 'diagrams');
const outputDir = resolve(__dirname, '..', 'public', 'diagrams');

mkdirSync(outputDir, { recursive: true });

const files = readdirSync(diagramsDir).filter(f => f.endsWith('.d2'));

for (const file of files) {
  const name = basename(file, extname(file));
  const input = resolve(diagramsDir, file);
  const output = resolve(outputDir, `${name}.svg`);
  console.log(`Generating ${name}.svg...`);
  execSync(`d2 --layout=elk --theme=0 "${input}" "${output}"`, {
    stdio: 'inherit',
  });
}

console.log(`Generated ${files.length} diagram(s) in ${outputDir}`);
