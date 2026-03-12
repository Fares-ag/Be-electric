'use client';

import { useRef, useState } from 'react';
import { cn } from '@/lib/utils';
import { Plus, X } from 'lucide-react';

interface PhotoUploaderProps {
  files: File[];
  onChange: (files: File[]) => void;
  maxFiles?: number;
  maxSizeMB?: number;
}

export function PhotoUploader({
  files,
  onChange,
  maxFiles = 5,
  maxSizeMB = 2,
}: PhotoUploaderProps) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [error, setError] = useState('');

  const handleSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    setError('');
    const selected = Array.from(e.target.files ?? []);
    if (selected.length + files.length > maxFiles) {
      setError(`Max ${maxFiles} photos allowed`);
      return;
    }
    const oversized = selected.filter((f) => f.size > maxSizeMB * 1024 * 1024);
    if (oversized.length > 0) {
      setError(`Each image must be under ${maxSizeMB}MB`);
      return;
    }
    const valid = selected.filter((f) =>
      ['image/jpeg', 'image/png', 'image/webp'].includes(f.type)
    );
    if (valid.length !== selected.length) {
      setError('Only JPEG, PNG, and WebP allowed');
    }
    onChange([...files, ...valid].slice(0, maxFiles));
    e.target.value = '';
  };

  const remove = (i: number) => {
    onChange(files.filter((_, idx) => idx !== i));
  };

  return (
    <div>
      <label className="mb-1.5 block text-sm font-medium text-foreground">
        Photos (optional)
      </label>
      <div className="flex flex-wrap gap-3 items-center">
        {files.map((f, i) => (
          <div
            key={i}
            className="relative w-20 h-20 rounded-lg overflow-hidden border border-border bg-muted"
          >
            <img
              src={URL.createObjectURL(f)}
              alt=""
              className="w-full h-full object-cover"
            />
            <button
              type="button"
              onClick={() => remove(i)}
              className="absolute top-1 right-1 h-5 w-5 rounded-full bg-destructive text-white flex items-center justify-center hover:bg-destructive/90 transition-colors"
            >
              <X className="h-3 w-3" />
            </button>
          </div>
        ))}
        {files.length < maxFiles && (
          <button
            type="button"
            onClick={() => inputRef.current?.click()}
            className={cn(
              'w-20 h-20 rounded-lg border-2 border-dashed border-border',
              'flex items-center justify-center text-muted-foreground',
              'hover:border-primary hover:text-primary hover:bg-primary/5',
              'transition-colors'
            )}
          >
            <Plus className="h-5 w-5" />
          </button>
        )}
      </div>
      <input
        ref={inputRef}
        type="file"
        accept="image/jpeg,image/png,image/webp"
        multiple
        className="hidden"
        onChange={handleSelect}
      />
      {error && <p className="text-sm text-destructive mt-1">{error}</p>}
    </div>
  );
}
