/**
 * RailsPress Markdown Mode
 * Toggle between rich text (Lexxy) and raw markdown editing
 */

(function() {
  'use strict';

  // ============================================
  // HTML to Markdown Converter (Simple)
  // ============================================

  function htmlToMarkdown(html) {
    if (!html || html.trim() === '' || html === '<p></p>' || html === '<p><br></p>') {
      return '';
    }

    let md = html;

    // Normalize whitespace
    md = md.replace(/\r\n/g, '\n');

    // Convert block elements first

    // Headings
    md = md.replace(/<h1[^>]*>(.*?)<\/h1>/gi, '# $1\n\n');
    md = md.replace(/<h2[^>]*>(.*?)<\/h2>/gi, '## $1\n\n');
    md = md.replace(/<h3[^>]*>(.*?)<\/h3>/gi, '### $1\n\n');
    md = md.replace(/<h4[^>]*>(.*?)<\/h4>/gi, '#### $1\n\n');
    md = md.replace(/<h5[^>]*>(.*?)<\/h5>/gi, '##### $1\n\n');
    md = md.replace(/<h6[^>]*>(.*?)<\/h6>/gi, '###### $1\n\n');

    // Code blocks (before inline code)
    md = md.replace(/<pre[^>]*><code[^>]*class="[^"]*language-(\w+)[^"]*"[^>]*>([\s\S]*?)<\/code><\/pre>/gi, function(match, lang, code) {
      return '```' + lang + '\n' + decodeHtmlEntities(code.trim()) + '\n```\n\n';
    });
    md = md.replace(/<pre[^>]*><code[^>]*>([\s\S]*?)<\/code><\/pre>/gi, function(match, code) {
      return '```\n' + decodeHtmlEntities(code.trim()) + '\n```\n\n';
    });
    md = md.replace(/<pre[^>]*>([\s\S]*?)<\/pre>/gi, function(match, code) {
      return '```\n' + decodeHtmlEntities(code.trim()) + '\n```\n\n';
    });

    // Blockquotes
    md = md.replace(/<blockquote[^>]*>([\s\S]*?)<\/blockquote>/gi, function(match, content) {
      const lines = content.replace(/<\/?p[^>]*>/gi, '\n').trim().split('\n');
      return lines.map(line => '> ' + line.trim()).join('\n') + '\n\n';
    });

    // Horizontal rules
    md = md.replace(/<hr[^>]*>/gi, '---\n\n');

    // Lists
    md = md.replace(/<ul[^>]*>([\s\S]*?)<\/ul>/gi, function(match, content) {
      return content.replace(/<li[^>]*>([\s\S]*?)<\/li>/gi, '- $1\n') + '\n';
    });
    md = md.replace(/<ol[^>]*>([\s\S]*?)<\/ol>/gi, function(match, content) {
      let index = 1;
      return content.replace(/<li[^>]*>([\s\S]*?)<\/li>/gi, function(m, item) {
        return (index++) + '. ' + item.trim() + '\n';
      }) + '\n';
    });

    // Paragraphs
    md = md.replace(/<p[^>]*>([\s\S]*?)<\/p>/gi, '$1\n\n');

    // Line breaks
    md = md.replace(/<br\s*\/?>/gi, '  \n');

    // Now inline elements

    // Images (before links to avoid nested issues)
    md = md.replace(/<img[^>]*src="([^"]*)"[^>]*alt="([^"]*)"[^>]*>/gi, '![$2]($1)');
    md = md.replace(/<img[^>]*alt="([^"]*)"[^>]*src="([^"]*)"[^>]*>/gi, '![$1]($2)');
    md = md.replace(/<img[^>]*src="([^"]*)"[^>]*>/gi, '![]($1)');

    // Links
    md = md.replace(/<a[^>]*href="([^"]*)"[^>]*>([\s\S]*?)<\/a>/gi, '[$2]($1)');

    // Bold and italic (order matters)
    md = md.replace(/<(strong|b)[^>]*>([\s\S]*?)<\/\1>/gi, '**$2**');
    md = md.replace(/<(em|i)[^>]*>([\s\S]*?)<\/\1>/gi, '*$2*');

    // Inline code
    md = md.replace(/<code[^>]*>(.*?)<\/code>/gi, '`$1`');

    // Strikethrough
    md = md.replace(/<(del|s|strike)[^>]*>([\s\S]*?)<\/\1>/gi, '~~$2~~');

    // Remove remaining tags
    md = md.replace(/<[^>]+>/g, '');

    // Decode HTML entities
    md = decodeHtmlEntities(md);

    // Clean up whitespace
    md = md.replace(/\n{3,}/g, '\n\n');
    md = md.trim();

    return md;
  }

  // ============================================
  // Markdown to HTML Converter (Simple)
  // ============================================

  function markdownToHtml(md) {
    if (!md || md.trim() === '') {
      return '<p></p>';
    }

    let html = md;

    // Escape HTML entities in the source
    html = html.replace(/&/g, '&amp;');
    html = html.replace(/</g, '&lt;');
    html = html.replace(/>/g, '&gt;');

    // Code blocks first (to protect their contents)
    const codeBlocks = [];
    html = html.replace(/```(\w*)\n([\s\S]*?)```/g, function(match, lang, code) {
      const index = codeBlocks.length;
      const langClass = lang ? ` class="language-${lang}"` : '';
      codeBlocks.push(`<pre><code${langClass}>${code.trim()}</code></pre>`);
      return `%%CODEBLOCK${index}%%`;
    });

    // Inline code (protect before other processing)
    const inlineCodes = [];
    html = html.replace(/`([^`]+)`/g, function(match, code) {
      const index = inlineCodes.length;
      inlineCodes.push(`<code>${code}</code>`);
      return `%%INLINECODE${index}%%`;
    });

    // Headings
    html = html.replace(/^###### (.*)$/gm, '<h6>$1</h6>');
    html = html.replace(/^##### (.*)$/gm, '<h5>$1</h5>');
    html = html.replace(/^#### (.*)$/gm, '<h4>$1</h4>');
    html = html.replace(/^### (.*)$/gm, '<h3>$1</h3>');
    html = html.replace(/^## (.*)$/gm, '<h2>$1</h2>');
    html = html.replace(/^# (.*)$/gm, '<h1>$1</h1>');

    // Horizontal rules
    html = html.replace(/^---$/gm, '<hr>');
    html = html.replace(/^\*\*\*$/gm, '<hr>');
    html = html.replace(/^___$/gm, '<hr>');

    // Blockquotes
    html = html.replace(/^> (.*)$/gm, '<blockquote>$1</blockquote>');
    // Merge consecutive blockquotes
    html = html.replace(/<\/blockquote>\n<blockquote>/g, '\n');

    // Unordered lists
    html = html.replace(/^[\*\-] (.*)$/gm, '<li>$1</li>');
    html = html.replace(/(<li>.*<\/li>\n?)+/g, function(match) {
      return '<ul>\n' + match + '</ul>\n';
    });

    // Ordered lists
    html = html.replace(/^\d+\. (.*)$/gm, '<oli>$1</oli>');
    html = html.replace(/(<oli>.*<\/oli>\n?)+/g, function(match) {
      return '<ol>\n' + match.replace(/oli>/g, 'li>') + '</ol>\n';
    });

    // Images
    html = html.replace(/!\[([^\]]*)\]\(([^)]+)\)/g, '<img src="$2" alt="$1">');

    // Links
    html = html.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>');

    // Bold and italic
    html = html.replace(/\*\*\*([^*]+)\*\*\*/g, '<strong><em>$1</em></strong>');
    html = html.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
    html = html.replace(/\*([^*]+)\*/g, '<em>$1</em>');
    html = html.replace(/__([^_]+)__/g, '<strong>$1</strong>');
    html = html.replace(/_([^_]+)_/g, '<em>$1</em>');

    // Strikethrough
    html = html.replace(/~~([^~]+)~~/g, '<del>$1</del>');

    // Line breaks (two spaces at end of line)
    html = html.replace(/  \n/g, '<br>\n');

    // Paragraphs - wrap remaining text blocks
    html = html.split(/\n\n+/).map(function(block) {
      block = block.trim();
      if (!block) return '';
      // Don't wrap if already a block element
      if (/^<(h[1-6]|ul|ol|blockquote|pre|hr|div|p)/i.test(block)) {
        return block;
      }
      // Don't wrap code block placeholders
      if (/^%%CODEBLOCK\d+%%$/.test(block)) {
        return block;
      }
      return '<p>' + block.replace(/\n/g, '<br>') + '</p>';
    }).join('\n');

    // Restore code blocks
    codeBlocks.forEach(function(code, index) {
      html = html.replace(`%%CODEBLOCK${index}%%`, code);
    });

    // Restore inline code
    inlineCodes.forEach(function(code, index) {
      html = html.replace(`%%INLINECODE${index}%%`, code);
    });

    return html;
  }

  // ============================================
  // Helper Functions
  // ============================================

  function decodeHtmlEntities(text) {
    const textarea = document.createElement('textarea');
    textarea.innerHTML = text;
    return textarea.value;
  }

  // ============================================
  // Markdown Mode Controller
  // ============================================

  function initMarkdownMode() {
    console.log('[MarkdownMode] Initializing...');
    const containers = document.querySelectorAll('[data-markdown-mode]');
    console.log('[MarkdownMode] Found containers:', containers.length);

    containers.forEach(function(container, index) {
      console.log('[MarkdownMode] Container', index, ':', container);
      const editor = container.querySelector('lexxy-editor');
      const textarea = container.querySelector('[data-markdown-textarea]');
      const toggleBtn = container.querySelector('[data-markdown-toggle]');
      const richLabel = container.querySelector('[data-mode-label="rich"]');
      const mdLabel = container.querySelector('[data-mode-label="markdown"]');

      console.log('[MarkdownMode] Container', index, 'elements:', {
        editor: !!editor,
        textarea: !!textarea,
        toggleBtn: !!toggleBtn
      });

      if (!editor || !textarea || !toggleBtn) {
        console.log('[MarkdownMode] Container', index, 'missing required elements, skipping');
        return;
      }
      console.log('[MarkdownMode] Container', index, 'initialized successfully');

      let isMarkdownMode = false;

      function updateLabels() {
        if (richLabel) richLabel.hidden = isMarkdownMode;
        if (mdLabel) mdLabel.hidden = !isMarkdownMode;
      }

      function switchToMarkdown() {
        // Get HTML from Lexxy
        const html = editor.value || '';

        // Convert to markdown
        const markdown = htmlToMarkdown(html);

        // Show textarea, hide editor
        textarea.value = markdown;
        textarea.hidden = false;
        editor.style.display = 'none';

        isMarkdownMode = true;
        toggleBtn.setAttribute('aria-pressed', 'true');
        updateLabels();
      }

      function switchToRichText() {
        // Get markdown from textarea
        const markdown = textarea.value || '';

        // Convert to HTML
        const html = markdownToHtml(markdown);

        // Show editor, hide textarea
        editor.style.display = '';
        textarea.hidden = true;

        // Load HTML into Lexxy
        editor.value = html;

        isMarkdownMode = false;
        toggleBtn.setAttribute('aria-pressed', 'false');
        updateLabels();
      }

      toggleBtn.addEventListener('click', function() {
        console.log('[MarkdownMode] Toggle clicked, current mode:', isMarkdownMode ? 'markdown' : 'rich');
        if (isMarkdownMode) {
          switchToRichText();
        } else {
          switchToMarkdown();
        }
      });

      // Sync textarea changes back to hidden input on form submit
      const form = container.closest('form');
      if (form) {
        form.addEventListener('submit', function() {
          if (isMarkdownMode) {
            // Convert markdown to HTML before submit
            const markdown = textarea.value || '';
            const html = markdownToHtml(markdown);
            editor.value = html;
          }
        });
      }

      // Initialize labels
      updateLabels();
    });
  }

  // ============================================
  // Export for testing/external use
  // ============================================

  window.RailsPress = window.RailsPress || {};
  window.RailsPress.MarkdownMode = {
    htmlToMarkdown: htmlToMarkdown,
    markdownToHtml: markdownToHtml,
    init: initMarkdownMode
  };

  // ============================================
  // Initialize
  // ============================================

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initMarkdownMode);
  } else {
    initMarkdownMode();
  }

})();
