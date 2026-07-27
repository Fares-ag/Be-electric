import { supabase } from '@/lib/supabase';
import {
  buildHistoricalWorkOrderInsert,
  type HistoricalWorkOrderFormInput,
} from '@/lib/historical-work-order';

export async function insertHistoricalWorkOrder(
  input: HistoricalWorkOrderFormInput
): Promise<string> {
  const payload = buildHistoricalWorkOrderInsert(input);
  const { data, error } = await supabase
    .from('work_orders')
    .insert(payload)
    .select('id')
    .single();
  if (error) throw error;
  return data.id as string;
}
