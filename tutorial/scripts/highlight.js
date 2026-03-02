#!/usr/bin/env node

// Build-time syntax highlighting with Shiki.
// Transforms <code class="language-swift"> blocks in index.html into
// Shiki-highlighted HTML. The build script backs up and restores the
// source file around this transformation.
//
// Macro panel code blocks use bare <pre><code> (no class) and are
// left untouched to preserve data-group attributes for hover highlighting.

import { createHighlighter } from 'shiki';
import { readFileSync, writeFileSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const htmlPath = resolve(__dirname, '..', 'index.html');

async function main() {
  const highlighter = await createHighlighter({
    themes: ['catppuccin-mocha'],
    langs: ['swift'],
  });

  let html = readFileSync(htmlPath, 'utf-8');

  const pattern = /<pre><code class="language-swift">([\s\S]*?)<\/code><\/pre>/g;

  html = html.replace(pattern, (_, code) => {
    const raw = code
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>')
      .replace(/&amp;/g, '&')
      .replace(/&#39;/g, "'")
      .replace(/&quot;/g, '"');

    return highlighter.codeToHtml(raw.trim(), {
      lang: 'swift',
      theme: 'catppuccin-mocha',
    });
  });

  writeFileSync(htmlPath, html);
  console.log('Syntax highlighting applied to index.html');
}

main().catch(err => {
  console.error('Highlight error:', err);
  process.exit(1);
});
