'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/lib/supabase';
import { useAuthStore } from '@/stores/auth-store';
import { uploadRequestPhotos } from '@/lib/storage';
import { Card, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { PhotoUploader } from '@/components/PhotoUploader';
import { cn } from '@/lib/utils';

const categories = [
  'mechanicalHvac',
  'electrical',
  'structural',
  'plumbing',
  'interior',
  'exterior',
  'itLowVoltage',
  'specializedEquipment',
  'safetyCompliance',
  'emergency',
  'preventive',
  'reactive',
] as const;

const priorities = ['low', 'medium', 'high', 'urgent', 'critical'] as const;

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
  const [category, setCategory] = useState<(typeof categories)[number]>('reactive');
  const [location, setLocation] = useState('');
  const [assetId, setAssetId] = useState<string | null>(null);
  const [notes, setNotes] = useState('');
  const [photos, setPhotos] = useState<File[]>([]);
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const { data: assets } = useQuery({
    queryKey: ['assets'],
    queryFn: async () => {
      const { data } = await supabase.from('assets').select('id, name, location').order('name');
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
    if (!user) return;
    setSubmitting(true);

    try {
      const ticketNumber = `WO-${Date.now()}`;
      const { data: wo, error: insertError } = await supabase
        .from('work_orders')
        .insert({
          id: crypto.randomUUID(),
          ticketNumber,
          problemDescription: description,
          requestorId: user.id,
          requestorName: user.name,
          status: 'open',
          priority,
          category,
          location: location || null,
          assetId: assetId || null,
          notes: notes || null,
          assignedTechnicianIds: [],
        })
        .select('id')
        .single();

      if (insertError) {
        setError(insertError.message);
        return;
      }

      if (photos.length > 0 && wo?.id) {
        try {
          const urls = await uploadRequestPhotos(photos, wo.id);
          const photoPath = urls.length === 1 ? urls[0] : JSON.stringify(urls);
          await supabase
            .from('work_orders')
            .update({ photoPath })
            .eq('id', wo.id);
        } catch (uploadErr) {
          setError(
            uploadErr instanceof Error
              ? uploadErr.message
              : 'Work order created but photo upload failed.'
          );
          return;
        }
      }
      router.push(`/my-requests`);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div>
      <h1 className="text-2xl font-semibold tracking-tight text-foreground mb-6 md:mb-8">
        Request Maintenance
      </h1>
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
            <div className="grid gap-4 sm:grid-cols-2">
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
                  Category
                </label>
                <select
                  value={category}
                  onChange={(e) => setCategory(e.target.value as (typeof categories)[number])}
                  className={inputClass}
                >
                  {categories.map((c) => (
                    <option key={c} value={c}>{c}</option>
                  ))}
                </select>
              </div>
            </div>
            <div>
              <label className="mb-1.5 block text-sm font-medium text-foreground">
                Asset (optional)
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
            </div>
            <div>
              <label className="mb-1.5 block text-sm font-medium text-foreground">
                Location
              </label>
              <input
                type="text"
                value={location}
                onChange={(e) => setLocation(e.target.value)}
                placeholder="Location if not linked to asset"
                className={inputClass}
              />
            </div>
            <PhotoUploader files={photos} onChange={setPhotos} />
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
            {error && <p className="text-sm text-destructive">{error}</p>}
            <Button type="submit" disabled={submitting} className="min-h-[48px] w-full sm:w-auto touch-manipulation">
              {submitting ? 'Submitting...' : 'Submit Request'}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
