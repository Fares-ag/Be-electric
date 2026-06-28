'use client';

export function SignatureImage({ value, alt }: { value: string; alt: string }) {
  const src = value.startsWith('data:') ? value : `data:image/png;base64,${value}`;
  return (
    <img
      src={src}
      alt={alt}
      className="max-h-24 w-auto rounded border border-border bg-muted/30 object-contain"
    />
  );
}
