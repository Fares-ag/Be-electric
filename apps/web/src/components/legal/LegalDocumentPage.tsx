import Link from 'next/link';
import type { ReactNode } from 'react';
import { LEGAL_URLS } from '@/lib/legal-urls';

type Block =
  | { type: 'title'; text: string }
  | { type: 'meta'; text: string }
  | { type: 'heading'; level: 2 | 3; text: string }
  | { type: 'paragraph'; text: string }
  | { type: 'note'; text: string };

function parseLegalDocument(raw: string): Block[] {
  const lines = raw.split('\n').map((line) => line.trim());
  const blocks: Block[] = [];
  let paragraph: string[] = [];

  const flushParagraph = () => {
    if (paragraph.length === 0) return;
    blocks.push({ type: 'paragraph', text: paragraph.join(' ') });
    paragraph = [];
  };

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (!line) {
      flushParagraph();
      continue;
    }

    if (i === 0) {
      flushParagraph();
      blocks.push({ type: 'title', text: line });
      continue;
    }

    if (/^(Effective date|Last updated):/i.test(line)) {
      flushParagraph();
      blocks.push({ type: 'meta', text: line });
      continue;
    }

    if (/^\d+\.\d+\s/.test(line)) {
      flushParagraph();
      blocks.push({ type: 'heading', level: 3, text: line });
      continue;
    }

    if (/^\d+\.\s/.test(line)) {
      flushParagraph();
      blocks.push({ type: 'heading', level: 2, text: line });
      continue;
    }

    if (
      line.startsWith('Manual confirmation required:') ||
      (line.startsWith('*') && line.endsWith('*'))
    ) {
      flushParagraph();
      blocks.push({ type: 'note', text: line.replace(/^\*|\*$/g, '') });
      continue;
    }

    paragraph.push(line);
  }

  flushParagraph();
  return blocks;
}

function renderInlineText(text: string) {
  const parts: ReactNode[] = [];
  const pattern =
    /(\[[^\]]+\]https?:\/\/[^\s]+|https?:\/\/[^\s]+|[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,})/gi;
  let lastIndex = 0;
  let match: RegExpExecArray | null;
  let key = 0;

  while ((match = pattern.exec(text)) !== null) {
    if (match.index > lastIndex) {
      parts.push(text.slice(lastIndex, match.index));
    }

    const token = match[0];
    const bracketMatch = token.match(/^\[([^\]]+)\](https?:\/\/[^\s]+)$/i);
    if (bracketMatch) {
      parts.push(
        <a
          key={key++}
          href={bracketMatch[2]}
          className="text-primary underline underline-offset-2 hover:text-primary-hover"
        >
          {bracketMatch[1]}
        </a>
      );
    } else if (/^https?:\/\//i.test(token)) {
      parts.push(
        <a
          key={key++}
          href={token}
          className="text-primary underline underline-offset-2 hover:text-primary-hover"
          target="_blank"
          rel="noopener noreferrer"
        >
          {token}
        </a>
      );
    } else if (token.includes('@')) {
      parts.push(
        <a
          key={key++}
          href={`mailto:${token}`}
          className="text-primary underline underline-offset-2 hover:text-primary-hover"
        >
          {token}
        </a>
      );
    }

    lastIndex = match.index + token.length;
  }

  if (lastIndex < text.length) {
    parts.push(text.slice(lastIndex));
  }

  return parts.length > 0 ? parts : text;
}

export function LegalDocumentPage({ content }: { content: string }) {
  const blocks = parseLegalDocument(content);

  return (
    <div className="min-h-screen bg-[rgb(var(--background))]">
      <header className="border-b border-border bg-card/80 backdrop-blur-sm">
        <div className="mx-auto flex max-w-3xl items-center justify-between gap-4 px-4 py-4 sm:px-6">
          <Link href="/login" className="text-sm font-semibold text-primary hover:text-primary-hover">
            Be Electric
          </Link>
          <nav className="flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-muted-foreground">
            <Link href={LEGAL_URLS.privacy} className="hover:text-foreground">
              Privacy
            </Link>
            <Link href={LEGAL_URLS.terms} className="hover:text-foreground">
              Terms
            </Link>
            <Link href={LEGAL_URLS.support} className="hover:text-foreground">
              Support
            </Link>
            <Link href={LEGAL_URLS.accountDeletion} className="hover:text-foreground">
              Account deletion
            </Link>
          </nav>
        </div>
      </header>

      <main className="mx-auto max-w-3xl px-4 py-10 sm:px-6 sm:py-14">
        <article className="space-y-5">
          {blocks.map((block, index) => {
            switch (block.type) {
              case 'title':
                return (
                  <h1
                    key={index}
                    className="font-display text-3xl font-bold tracking-tight text-foreground sm:text-4xl"
                  >
                    {block.text}
                  </h1>
                );
              case 'meta':
                return (
                  <p key={index} className="text-sm text-muted-foreground">
                    {block.text}
                  </p>
                );
              case 'heading':
                return block.level === 2 ? (
                  <h2
                    key={index}
                    className="pt-4 font-display text-xl font-semibold text-foreground first:pt-0"
                  >
                    {block.text}
                  </h2>
                ) : (
                  <h3 key={index} className="pt-2 text-base font-semibold text-foreground">
                    {block.text}
                  </h3>
                );
              case 'note':
                return (
                  <p
                    key={index}
                    className="rounded-lg border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-950"
                  >
                    {renderInlineText(block.text)}
                  </p>
                );
              case 'paragraph':
                return (
                  <p key={index} className="text-sm leading-7 text-foreground/90">
                    {renderInlineText(block.text)}
                  </p>
                );
              default:
                return null;
            }
          })}
        </article>
      </main>
    </div>
  );
}
