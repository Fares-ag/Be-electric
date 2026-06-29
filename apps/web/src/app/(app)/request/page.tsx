'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { useAuthStore } from '@/stores/auth-store';
import { uploadRequestPhotos } from '@/lib/storage';
import { useFormSubmitLock } from '@/hooks/useFormSubmitLock';
import { Card, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { PhotoUploader } from '@/components/PhotoUploader';
import { PageHeader } from '@/components/ui/PageStates';
import { cn } from '@/lib/utils';

const priorities = ['low', 'medium', 'high', 'urgent', 'critical'] as const;

const MIN_PHOTOS = 2;

const inputClass = cn(
  'w-full rounded-lg border border-input bg-background px-4 py-3 text-sm min-h-[44px]',
  'placeholder:text-muted-foreground',
  'focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary',
  'transition-colors touch-manipulation'
);

export default function RequestMaintenancePage() {
  const router = useRouter();
  const user = useAuthStore((s) => s.user);
  const [description, setDescription] = useState('');
  const [priority, setPriority] = useState<(typeof priorities)[number]>('medium');
  const [location, setLocation] = useState('');
  const [assetId, setAssetId] = useState<string | null>(null);
  const [notes, setNotes] = useState('');
  const [photos, setPhotos] = useState<File[]>([]);
  const [error, setError] = useState('');
  const { submitting, runSubmit } = useFormSubmitLock();

  const isRequestor = user?.role === 'requestor';
  const companyId = user?.companyId ?? null;

  const { data: assets } = useQuery({
    queryKey: ['assets', 'request', isRequestor ? companyId : 'all'],
    staleTime: 60 * 1000,
    queryFn: async () => {
      if (isRequestor && !companyId) return [];
      let q = supabase.from('assets').select('id, name, location').order('name');
      if (isRequestor && companyId) {
        q = q.eq('companyId', companyId);
      }
      const { data } = await q;
      return data ?? [];
    },
  });

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    if (!description.trim()) {
      setError('Problem description is required');
      return;
    }
    if (photos.length < MIN_PHOTOS) {
      setError(`Please add at least ${MIN_PHOTOS} photos.`);
      return;
    }
    if (isRequestor && !companyId) {
      setError(
        'Your account is not linked to a company. Contact your administrator before submitting requests.'
      );
      return;
    }
    if (!user) return;

    await runSubmit(async () => {
      const workOrderId = crypto.randomUUID();
      const ticketNumber = `WO-${Date.now()}`;
      let photoPath: string | null = null;

      const urls = await uploadRequestPhotos(photos, workOrderId);
      if (urls.length > 0) {
        photoPath = urls.length === 1 ? urls[0] : JSON.stringify(urls);
      }

      const { error: insertError } = await supabase.from('work_orders').insert({
        id: workOrderId,
        ticketNumber,
        problemDescription: description,
        requestorId: user.id,
        requestorName: user.name,
        companyId: companyId || null,
        status: 'open',
        priority,
        category: null,
        location: location || null,
        assetId: assetId || null,
        notes: notes || null,
        photoPath,
        assignedTechnicianIds: [],
      });

      if (insertError) {
        setError(insertError.message);
        return;
      }

      router.push(`/my-requests`);
    });
  }

  return (
    <div className="space-y-6 sm:space-y-8">
      <PageHeader
        title="Request Maintenance"
        description="Describe the issue and attach photos so technicians can respond quickly."
      />
      <Card>
        <CardContent className="pt-6 px-4 sm:px-6 pb-6">
          <form onSubmit={handleSubmit} className="space-y-6 max-w-xl">
            <div>
              <label className="mb-1.5 block text-sm font-medium text-foreground">
                Problem Description *
              </label>
              <textarea
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Describe the issue..."
                required
                rows={4}
                className={cn(inputClass, 'min-h-[100px] py-3')}
              />
            </div>
            <div>
              <label className="mb-1.5 block text-sm font-medium text-foreground">
                Priority
              </label>
              <select
                value={priority}
                onChange={(e) => setPriority(e.target.value as (typeof priorities)[number])}
                className={inputClass}
              >
                {priorities.map((p) => (
                  <option key={p} value={p}>{p}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="mb-1.5 block text-sm font-medium text-foreground">
                Charger (optional)
              </label>
              <select
                value={assetId ?? ''}
                onChange={(e) => setAssetId(e.target.value || null)}
                className={inputClass}
              >
                <option value="">— None —</option>
                {assets?.map((a: { id: string; name: string }) => (
                  <option key={a.id} value={a.id}>{a.name}</option>
                ))}
              </select>
              {isRequestor && !companyId && (
                <p className="mt-1.5 text-xs text-muted-foreground">
                  No company assigned. Contact your administrator to get access to chargers.
                </p>
              )}
              {isRequestor && companyId && assets?.length === 0 && (
                <p className="mt-1.5 text-xs text-muted-foreground">
                  No chargers in your company.
                </p>
              )}
            </div>
            <div>
              <label className="mb-1.5 block text-sm font-medium text-foreground">
                Location
              </label>
              <input
                type="text"
                value={location}
                onChange={(e) => setLocation(e.target.value)}
                placeholder="Location if not linked to charger"
                className={inputClass}
              />
            </div>
            <div>
              <label className="mb-1.5 block text-sm font-medium text-foreground">
                Photos <span className="text-destructive">*</span> (at least {MIN_PHOTOS} required)
              </label>
              <PhotoUploader files={photos} onChange={setPhotos} showLabel={false} />
              {photos.length > 0 && photos.length < MIN_PHOTOS && (
                <p className="mt-1.5 text-sm text-muted-foreground">
                  Add {MIN_PHOTOS - photos.length} more photo{MIN_PHOTOS - photos.length === 1 ? '' : 's'}.
                </p>
              )}
            </div>
            <div>
              <label className="mb-1.5 block text-sm font-medium text-foreground">
                Notes
              </label>
              <textarea
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                placeholder="Additional notes"
                rows={2}
                className={cn(inputClass, 'min-h-[80px] py-3')}
              />
            </div>
            {error && (
              <p className="text-sm text-destructive" role="alert">
                {error}
              </p>
            )}
            <Button
              type="submit"
              disabled={submitting || photos.length < MIN_PHOTOS}
              className="min-h-[48px] w-full touch-manipulation sm:w-auto"
            >
              {submitting ? 'Submitting…' : 'Submit Request'}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
