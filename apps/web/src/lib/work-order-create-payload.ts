export type CreateWorkOrderInput = {
  id: string;
  ticketNumber: string;
  problemDescription: string;
  priority: string;
  requestorId: string;
  requestorName: string;
  companyId: string | null;
  assetId: string | null;
  location: string | null;
  notes: string | null;
  photoUrls: string[];
};

/** Payload shape expected by upsert_work_order RPC (matches Flutter requestor flow). */
export function buildUpsertWorkOrderPayload(input: CreateWorkOrderInput): Record<string, unknown> {
  const photoPath =
    input.photoUrls.length === 1
      ? input.photoUrls[0]
      : input.photoUrls.length > 1
        ? JSON.stringify(input.photoUrls)
        : null;

  return {
    id: input.id,
    ticketNumber: input.ticketNumber,
    problemDescription: input.problemDescription,
    status: 'open',
    priority: input.priority,
    requestorId: input.requestorId,
    requestorName: input.requestorName,
    companyId: input.companyId,
    assetId: input.assetId,
    location: input.location,
    notes: input.notes,
    photoPath,
    metadata: { photoPaths: input.photoUrls },
    assignedTechnicianIds: [],
  };
}
