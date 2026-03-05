#!/usr/bin/env node

// Generate SVG diagrams from D2 .d2 files using the d2 CLI.
// Requires: d2 installed (https://d2lang.com)
// Uses ELK layout for orthogonal routing with rounded corners.
//
// Usage:
//   node generate-diagrams.js [options]
//
// ELK layout options:
//   --node-spacing <int>   spacing between nodes in adjacent layers (default: d2's 70)
//   --edge-spacing <int>   spacing between edges and nodes in adjacent layers (default: d2's 40)
//   --padding <string>     parent element padding, e.g. "[top=50,left=50,bottom=50,right=50]"
//   --self-loop <int>      spacing between a node and its self loops (default: d2's 50)
//
// Other options:
//   --pad <int>            pixels padded around the rendered diagram (default: 20)
//   --theme <int>          diagram theme ID (default: 0)

import { execSync } from 'child_process';
import { readdirSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import { resolve, dirname, basename, extname } from 'path';
import { fileURLToPath } from 'url';
import { parseArgs } from 'util';

const __dirname = dirname(fileURLToPath(import.meta.url));
const diagramsDir = resolve(__dirname, '..', 'diagrams');
const outputDir = resolve(__dirname, '..', 'public', 'diagrams');

const { values: opts } = parseArgs({
  options: {
    'node-spacing':  { type: 'string' },
    'edge-spacing':  { type: 'string' },
    'padding':       { type: 'string' },
    'self-loop':     { type: 'string' },
    'pad':           { type: 'string', default: '20' },
    'theme':         { type: 'string', default: '0' },
    'dark-theme':    { type: 'string', default: '200' },
  },
  strict: false,
});

const elkFlags = [
  opts['node-spacing'] != null && `--elk-nodeNodeBetweenLayers=${opts['node-spacing']}`,
  opts['edge-spacing'] != null && `--elk-edgeNodeBetweenLayers=${opts['edge-spacing']}`,
  opts['padding']      != null && `--elk-padding="${opts['padding']}"`,
  opts['self-loop']    != null && `--elk-nodeSelfLoop=${opts['self-loop']}`,
  opts['pad']          != null && `--pad=${opts['pad']}`,
].filter(Boolean).join(' ');

mkdirSync(outputDir, { recursive: true });

const files = readdirSync(diagramsDir).filter(f => f.endsWith('.d2'));

// Light-mode fills → dark-mode equivalents (preserving semantic color relationships).
const darkFillMap = {
  '#cce5ff': '#1a3a5c',  // light blue → dark blue
  '#e1f5ff': '#1a3550',  // very light blue → dark blue variant
  '#d4edda': '#1a3a2a',  // light green → dark green
  '#fff3cd': '#3d3520',  // light yellow → dark amber
  '#e2e3e5': '#3a3a3c',  // light gray → dark gray
  '#f8d7da': '#4a2028',  // light pink → dark red
};

function stripBackground(filePath) {
  let svg = readFileSync(filePath, 'utf-8');
  svg = svg.replace(/<rect[^>]*class="\s*fill-N7\s*"[^>]*\/>/g, '');
  writeFileSync(filePath, svg);
}

// Set width/height in em units anchored to d2's font size (16px).
// This ensures diagram text renders at 1em regardless of container width,
// keeping diagram labels proportional to the page's body text.
const D2_FONT_SIZE = 16;

function setIntrinsicSize(filePath) {
  let svg = readFileSync(filePath, 'utf-8');
  const match = svg.match(/(<svg\b[^>]*?)viewBox="0 0 (\d+) (\d+)"/);
  if (match) {
    const [fullMatch, before, w, h] = match;
    if (!before.includes('width=')) {
      const emW = (parseInt(w) / D2_FONT_SIZE).toFixed(2);
      const emH = (parseInt(h) / D2_FONT_SIZE).toFixed(2);
      svg = svg.replace(
        fullMatch,
        `${before}width="${emW}em" height="${emH}em" viewBox="0 0 ${w} ${h}"`
      );
      writeFileSync(filePath, svg);
    }
  }
}

function swapFillsForDark(filePath) {
  let svg = readFileSync(filePath, 'utf-8');
  for (const [light, dark] of Object.entries(darkFillMap)) {
    svg = svg.replaceAll(light, dark);
  }
  writeFileSync(filePath, svg);
}

for (const file of files) {
  const name = basename(file, extname(file));
  const input = resolve(diagramsDir, file);

  // Light theme
  const lightOutput = resolve(outputDir, `${name}.svg`);
  console.log(`Generating ${name}.svg (light)...`);
  execSync(`d2 --layout=elk --theme=${opts['theme']} ${elkFlags} "${input}" "${lightOutput}"`, {
    stdio: 'inherit',
  });
  stripBackground(lightOutput);
  setIntrinsicSize(lightOutput);

  // Dark theme
  const darkOutput = resolve(outputDir, `${name}-dark.svg`);
  console.log(`Generating ${name}-dark.svg (dark)...`);
  execSync(`d2 --layout=elk --theme=${opts['dark-theme']} ${elkFlags} "${input}" "${darkOutput}"`, {
    stdio: 'inherit',
  });
  stripBackground(darkOutput);
  setIntrinsicSize(darkOutput);
  swapFillsForDark(darkOutput);
}

console.log(`Generated ${files.length * 2} diagram(s) in ${outputDir}`);
