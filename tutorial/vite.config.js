import { defineConfig } from 'vite';
import { createHighlighter } from 'shiki';

// Vite plugin: apply Shiki syntax highlighting to code blocks at serve and
// build time. Regular code blocks (class="language-swift") get the dark theme;
// macro panel code blocks (with data-group spans) get the light theme, with
// data-group attributes preserved via Shiki decorations.
function shikiPlugin() {
  let highlighter;

  return {
    name: 'shiki-highlight',
    async buildStart() {
      highlighter = await createHighlighter({
        themes: ['catppuccin-mocha', 'catppuccin-latte'],
        langs: ['swift'],
      });
    },
    transformIndexHtml(html) {
      if (!highlighter) return html;

      // Pass 1: language-swift blocks (dark theme)
      html = html.replace(
        /<pre><code class="language-swift">([\s\S]*?)<\/code><\/pre>/g,
        (_, code) => {
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
        }
      );

      // Pass 2: macro panel code blocks (light theme, data-group preserved)
      html = html.replace(
        /<pre><code>([\s\S]*?)<\/code><\/pre>/g,
        (match, inner) => {
          if (!inner.trim()) return match;

          const { code, decorations } = parseDataGroups(inner);
          if (!code.trim()) return match;

          return highlighter.codeToHtml(code, {
            lang: 'swift',
            themes: { light: 'catppuccin-latte', dark: 'catppuccin-mocha' },
            defaultColor: false,
            decorations,
          });
        }
      );

      return html;
    },
  };
}

/// Parse HTML containing `<span data-group="...">` wrappers into raw code
/// and Shiki decoration ranges that preserve the data-group attributes.
function parseDataGroups(html) {
  const decorations = [];
  let decoded = '';
  let i = 0;
  let currentGroup = null;
  let groupStart = null;

  while (i < html.length) {
    // Opening <span data-group="...">
    const spanMatch = html.slice(i).match(/^<span data-group="([^"]+)">/);
    if (spanMatch) {
      currentGroup = spanMatch[1];
      const lines = decoded.split('\n');
      groupStart = {
        line: lines.length - 1,
        character: lines[lines.length - 1].length,
      };
      i += spanMatch[0].length;
      continue;
    }

    // Closing </span>
    if (html.startsWith('</span>', i)) {
      if (currentGroup) {
        const lines = decoded.split('\n');
        decorations.push({
          start: { ...groupStart },
          end: { line: lines.length - 1, character: lines[lines.length - 1].length },
          properties: { 'data-group': currentGroup },
        });
        currentGroup = null;
      }
      i += 7;
      continue;
    }

    // Decode HTML entities
    if (html.startsWith('&lt;', i))   { decoded += '<'; i += 4; }
    else if (html.startsWith('&gt;', i))   { decoded += '>'; i += 4; }
    else if (html.startsWith('&amp;', i))  { decoded += '&'; i += 5; }
    else if (html.startsWith('&#39;', i))  { decoded += "'"; i += 5; }
    else if (html.startsWith('&quot;', i)) { decoded += '"'; i += 6; }
    else { decoded += html[i]; i++; }
  }

  return { code: decoded, decorations };
}

export default defineConfig({
  root: '.',
  build: {
    outDir: 'dist',
  },
  publicDir: 'public',
  plugins: [shikiPlugin()],
});
