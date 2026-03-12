// Supabase database types (extend as schema evolves)
export type WorkOrderStatus =
  | 'open'
  | 'assigned'
  | 'inProgress'
  | 'completed'
  | 'closed'
  | 'cancelled'
  | 'reopened';

export type WorkOrderPriority = 'low' | 'medium' | 'high' | 'urgent' | 'critical';

export type UserRole = 'requestor' | 'technician' | 'manager' | 'admin';

export type RepairCategory =
  | 'mechanicalHvac'
  | 'electrical'
  | 'structural'
  | 'plumbing'
  | 'interior'
  | 'exterior'
  | 'itLowVoltage'
  | 'specializedEquipment'
  | 'safetyCompliance'
  | 'emergency'
  | 'preventive'
  | 'reactive';

export type PMTaskStatus =
  | 'pending'
  | 'inProgress'
  | 'completed'
  | 'overdue'
  | 'cancelled';

export type PMTaskFrequency =
  | 'daily'
  | 'weekly'
  | 'monthly'
  | 'quarterly'
  | 'semiAnnually'
  | 'annually'
  | 'asNeeded';

export type PartsRequestStatus =
  | 'pending'
  | 'approved'
  | 'rejected'
  | 'fulfilled'
  | 'cancelled';

export interface WorkOrder {
  id: string;
  ticketNumber: string;
  problemDescription: string;
  requestorId: string;
  assetId?: string | null;
  location?: string | null;
  companyId?: string | null;
  status: WorkOrderStatus;
  priority: WorkOrderPriority;
  category?: RepairCategory | null;
  assignedTechnicianIds: string[];
  primaryTechnicianId?: string | null;
  photoPath?: string | null;
  completionPhotoPath?: string | null;
  correctiveActions?: string | null;
  recommendations?: string | null;
  requestorSignature?: string | null;
  technicianSignature?: string | null;
  notes?: string | null;
  createdAt: string;
  updatedAt: string;
  assignedAt?: string | null;
  startedAt?: string | null;
  completedAt?: string | null;
  closedAt?: string | null;
  idempotencyKey?: string | null;
  // Joined
  requestor?: User;
  asset?: Asset;
  company?: Company;
}

export interface Asset {
  id: string;
  name: string;
  location: string;
  description?: string | null;
  category?: string | null;
  manufacturer?: string | null;
  model?: string | null;
  serialNumber?: string | null;
  status: string;
  qrCodeId?: string | null;
  companyId?: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface User {
  id: string;
  email: string;
  name: string;
  role: UserRole;
  department?: string | null;
  companyId?: string | null;
  isActive: boolean;
  createdAt: string;
  updatedAt?: string | null;
}

export interface Company {
  id: string;
  name: string;
  contactEmail?: string | null;
  contactPhone?: string | null;
  address?: string | null;
  isActive: boolean;
}

export interface PMTask {
  id: string;
  taskName: string;
  assetId: string;
  description: string;
  frequency: PMTaskFrequency;
  intervalDays: number;
  status: PMTaskStatus;
  assignedTechnicianIds: string[];
  nextDueDate?: string | null;
  lastCompletedAt?: string | null;
  createdAt: string;
  completedAt?: string | null;
  completionNotes?: string | null;
  asset?: Asset;
}

export interface InventoryItem {
  id: string;
  name: string;
  category: string;
  quantity: number;
  unit: string;
  sku?: string | null;
  minimumStock?: number | null;
  maximumStock?: number | null;
  cost?: number | null;
  status: string;
}

export interface PartsRequest {
  id: string;
  workOrderId: string | null;
  requestedBy: string;
  requestedParts: Array<{ name?: string; quantity?: number; unit?: string }>;
  status: PartsRequestStatus;
  requestedAt: string;
  approvedAt?: string | null;
  rejectedAt?: string | null;
  approvedBy?: string | null;
  rejectedBy?: string | null;
  rejectionReason?: string | null;
  workOrder?: WorkOrder;
  requester?: User;
}

export interface Notification {
  id: string;
  userId: string;
  title: string;
  body?: string | null;
  type: string;
  relatedEntityId?: string | null;
  read: boolean;
  createdAt: string;
}

// Re-export generated DB types (source: supabase/database.types.ts)
export type { Database } from '../../../supabase/database.types';
