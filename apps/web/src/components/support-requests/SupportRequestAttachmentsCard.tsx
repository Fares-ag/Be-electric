'use client';

import { ExternalLink } from 'lucide-react';
import { DetailCard } from '@/components/ui/DetailCard';
import type { SupportAttachment } from '@/lib/support-requests';

function isImageAttachment(file: SupportAttachment): boolean {
  if (file.contentType?.startsWith('image/')) return true;
  return /\.(jpe?g|png|gif|webp)$/i.test(file.url);
}

export function SupportRequestAttachmentsCard({
  attachments,
}: {
  attachments: SupportAttachment[];
}) {
  return (
    <DetailCard title="Attachments">
      {attachments.length === 0 ? (
        <p className="text-sm text-muted-foreground">No attachments uploaded.</p>
      ) : (
        <ul className="space-y-4">
          {attachments.map((file, index) => (
            <li key={`${file.url}-${index}`} className="space-y-2">
              <div className="flex flex-wrap items-center gap-2">
                <a
                  href={file.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center gap-1 text-sm font-medium text-primary underline-offset-2 hover:underline"
                >
                  {file.fileName ?? `Attachment ${index + 1}`}
                  <ExternalLink className="h-3.5 w-3.5" aria-hidden />
                </a>
                {file.contentType ? (
                  <span className="text-xs text-muted-foreground">{file.contentType}</span>
                ) : null}
              </div>
              {isImageAttachment(file) ? (
                <a
                  href={file.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="block max-w-md overflow-hidden rounded-lg border border-border bg-muted/30"
                >
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img
                    src={file.url}
                    alt={file.fileName ?? `Support attachment ${index + 1}`}
                    className="max-h-64 w-full object-contain"
                    loading="lazy"
                  />
                </a>
              ) : null}
            </li>
          ))}
        </ul>
      )}
    </DetailCard>
  );
}
