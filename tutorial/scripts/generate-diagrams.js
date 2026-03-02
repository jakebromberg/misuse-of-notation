#!/usr/bin/env node

// Generate SVG diagrams from Mermaid .mmd files using @mermaid-js/mermaid-cli.
// Post-processes SVGs to inject neo-style drop shadows scraped from the
// reference diagram.

import { run } from '@mermaid-js/mermaid-cli';
import { readdirSync, readFileSync, writeFileSync, mkdirSync } from 'fs';
import { resolve, dirname, basename, extname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const diagramsDir = resolve(__dirname, '..', 'diagrams');
const outputDir = resolve(__dirname, '..', 'public', 'diagrams');
const configPath = resolve(diagramsDir, 'mermaid-config.json');
const cssPath = resolve(diagramsDir, 'mermaid-style.css');
const mermaidConfig = JSON.parse(readFileSync(configPath, 'utf-8'));
const myCSS = readFileSync(cssPath, 'utf-8');

mkdirSync(outputDir, { recursive: true });

// Drop shadow filters scraped from the reference SVG.
const NEO_FILTERS = `
<defs>
  <filter id="drop-shadow" height="130%" width="130%">
    <feDropShadow dx="4" dy="4" stdDeviation="0" flood-opacity="0.06" flood-color="#000000"/>
  </filter>
  <filter id="drop-shadow-small" height="150%" width="150%">
    <feDropShadow dx="2" dy="2" stdDeviation="0" flood-opacity="0.06" flood-color="#000000"/>
  </filter>
</defs>`;

// Neo-look CSS rules scraped from the reference SVG.
const NEO_CSS = `
.node rect, .node polygon { filter: url(#drop-shadow); }
.node circle { filter: url(#drop-shadow-small); }
.cluster rect { filter: url(#drop-shadow); }
`;

function postProcess(svg) {
  // Inject filter defs after the opening <svg> tag.
  svg = svg.replace(/(<svg[^>]*>)/, `$1${NEO_FILTERS}`);

  // Inject neo CSS into the existing <style> block, or add one.
  if (svg.includes('</style>')) {
    svg = svg.replace('</style>', `${NEO_CSS}</style>`);
  } else {
    svg = svg.replace(/(<svg[^>]*>)/, `$1<style>${NEO_CSS}</style>`);
  }

  return svg;
}

const files = readdirSync(diagramsDir).filter(f => f.endsWith('.mmd'));

for (const file of files) {
  const name = basename(file, extname(file));
  const input = resolve(diagramsDir, file);
  const output = resolve(outputDir, `${name}.svg`);
  console.log(`Generating ${name}.svg...`);
  await run(input, output, {
    parseMMDOptions: { mermaidConfig, myCSS },
    puppeteerConfig: { headless: true },
  });

  // Post-process: inject neo drop shadows.
  const svg = readFileSync(output, 'utf-8');
  writeFileSync(output, postProcess(svg));
}

console.log(`Generated ${files.length} diagram(s) in ${outputDir}`);
