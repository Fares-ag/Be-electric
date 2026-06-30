import type { Json } from '../../../../supabase/database.types';
import { supabase } from '@/lib/supabase';
import {
  buildUpsertWorkOrderPayload,
  type CreateWorkOrderInput,
} from '@/lib/work-order-create-payload';

export type { CreateWorkOrderInput };
export { buildUpsertWorkOrderPayload };

export async function upsertWorkOrderViaRpc(input: CreateWorkOrderInput): Promise<void> {
  const { error } = await supabase.rpc('upsert_work_order', {
    p_row: buildUpsertWorkOrderPayload(input) as Json,
  });
  if (error) throw error;
}
