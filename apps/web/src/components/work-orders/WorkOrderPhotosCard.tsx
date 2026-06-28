'use client';

import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';

type Props = {
  requestPhotos: string[];
  beforePhotos: string[];
  afterPhotos: string[];
  completionPhotos: string[];
  isCompleted: boolean;
};

function PhotoGrid({ photos, labelPrefix }: { photos: string[]; labelPrefix: string }) {
  return (
    <div className="flex flex-wrap gap-2">
      {photos.map((src, i) => (
        <a
          key={`${labelPrefix}-${i}-${src}`}
          href={src}
          target="_blank"
          rel="noopener noreferrer"
          className="block h-32 w-32 overflow-hidden rounded-lg border border-border bg-muted"
        >
          {/* eslint-disable-next-line @next/next/no-img-element -- dynamic Supabase/storage URLs */}
          <img
            src={src}
            alt={`${labelPrefix} ${i + 1}`}
            className="h-full w-full object-cover"
            onError={(e) => {
              (e.currentTarget as HTMLImageElement).style.display = 'none';
            }}
          />
        </a>
      ))}
    </div>
  );
}

export function WorkOrderPhotosCard({
  requestPhotos,
  beforePhotos,
  afterPhotos,
  completionPhotos,
  isCompleted,
}: Props) {
  return (
    <Card className="mt-4">
      <CardHeader>
        <CardTitle>Photos</CardTitle>
      </CardHeader>
      <CardContent className="space-y-6">
        <div>
          <p className="mb-2 text-sm font-semibold text-foreground">Request photos</p>
          {requestPhotos.length > 0 ? (
            <PhotoGrid photos={requestPhotos} labelPrefix="Request" />
          ) : (
            <p className="text-sm text-muted-foreground">No request photos uploaded.</p>
          )}
        </div>

        {(beforePhotos.length > 0 || afterPhotos.length > 0) && (
          <div className="grid gap-4 sm:grid-cols-2">
            {beforePhotos.length > 0 && (
              <div>
                <p className="mb-2 text-sm font-semibold text-foreground">Before</p>
                <PhotoGrid photos={beforePhotos} labelPrefix="Before" />
              </div>
            )}
            {afterPhotos.length > 0 && (
              <div>
                <p className="mb-2 text-sm font-semibold text-foreground">After</p>
                <PhotoGrid photos={afterPhotos} labelPrefix="After" />
              </div>
            )}
          </div>
        )}

        <div>
          <p className="mb-2 text-sm font-semibold text-foreground">Completion photos</p>
          {completionPhotos.length > 0 ? (
            <PhotoGrid photos={completionPhotos} labelPrefix="Completion" />
          ) : (
            <p className="text-sm text-muted-foreground">
              {isCompleted
                ? 'No completion photos uploaded by technician.'
                : 'Completion photos will appear here once the technician marks this work order as done.'}
            </p>
          )}
        </div>
      </CardContent>
    </Card>
  );
}
