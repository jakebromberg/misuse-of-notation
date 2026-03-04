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
import { readdirSync, mkdirSync } from 'fs';
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

for (const file of files) {
  const name = basename(file, extname(file));
  const input = resolve(diagramsDir, file);
  const output = resolve(outputDir, `${name}.svg`);
  console.log(`Generating ${name}.svg...`);
  execSync(`d2 --layout=elk --theme=${opts['theme']} ${elkFlags} "${input}" "${output}"`, {
    stdio: 'inherit',
  });
}

console.log(`Generated ${files.length} diagram(s) in ${outputDir}`);
