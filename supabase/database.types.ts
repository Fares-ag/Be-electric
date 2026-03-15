export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.1"
  }
  graphql_public: {
    Tables: {
      [_ in never]: never
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      graphql: {
        Args: {
          extensions?: Json
          operationName?: string
          query?: string
          variables?: Json
        }
        Returns: Json
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  public: {
    Tables: {
      admin_users: {
        Row: {
          email: string
          is_admin: boolean
          is_manager: boolean
          updated_at: string | null
        }
        Insert: {
          email: string
          is_admin?: boolean
          is_manager?: boolean
          updated_at?: string | null
        }
        Update: {
          email?: string
          is_admin?: boolean
          is_manager?: boolean
          updated_at?: string | null
        }
        Relationships: []
      }
      assets: {
        Row: {
          assetType: string | null
          companyId: string | null
          createdAt: string
          id: string
          installationDate: string | null
          lastMaintenanceDate: string | null
          location: string | null
          manufacturer: string | null
          metadata: Json | null
          model: string | null
          name: string
          nextMaintenanceDate: string | null
          qrCode: string | null
          serialNumber: string | null
          status: string | null
          updatedAt: string | null
        }
        Insert: {
          assetType?: string | null
          companyId?: string | null
          createdAt?: string
          id: string
          installationDate?: string | null
          lastMaintenanceDate?: string | null
          location?: string | null
          manufacturer?: string | null
          metadata?: Json | null
          model?: string | null
          name: string
          nextMaintenanceDate?: string | null
          qrCode?: string | null
          serialNumber?: string | null
          status?: string | null
          updatedAt?: string | null
        }
        Update: {
          assetType?: string | null
          companyId?: string | null
          createdAt?: string
          id?: string
          installationDate?: string | null
          lastMaintenanceDate?: string | null
          location?: string | null
          manufacturer?: string | null
          metadata?: Json | null
          model?: string | null
          name?: string
          nextMaintenanceDate?: string | null
          qrCode?: string | null
          serialNumber?: string | null
          status?: string | null
          updatedAt?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "assets_companyId_fkey"
            columns: ["companyId"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
        ]
      }
      audit_events: {
        Row: {
          description: string
          id: string
          ipAddress: string | null
          metadata: Json | null
          newValues: Json | null
          oldValues: Json | null
          requestId: string | null
          resourceId: string | null
          resourceType: string | null
          sessionId: string | null
          severity: string
          timestamp: string
          type: string
          userAgent: string | null
          userId: string
          userName: string | null
        }
        Insert: {
          description: string
          id?: string
          ipAddress?: string | null
          metadata?: Json | null
          newValues?: Json | null
          oldValues?: Json | null
          requestId?: string | null
          resourceId?: string | null
          resourceType?: string | null
          sessionId?: string | null
          severity: string
          timestamp?: string
          type: string
          userAgent?: string | null
          userId: string
          userName?: string | null
        }
        Update: {
          description?: string
          id?: string
          ipAddress?: string | null
          metadata?: Json | null
          newValues?: Json | null
          oldValues?: Json | null
          requestId?: string | null
          resourceId?: string | null
          resourceType?: string | null
          sessionId?: string | null
          severity?: string
          timestamp?: string
          type?: string
          userAgent?: string | null
          userId?: string
          userName?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "audit_events_userId_fkey"
            columns: ["userId"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      companies: {
        Row: {
          address: string | null
          contactEmail: string | null
          contactPhone: string | null
          createdAt: string
          id: string
          isActive: boolean
          metadata: Json | null
          name: string
          updatedAt: string | null
        }
        Insert: {
          address?: string | null
          contactEmail?: string | null
          contactPhone?: string | null
          createdAt?: string
          id?: string
          isActive?: boolean
          metadata?: Json | null
          name: string
          updatedAt?: string | null
        }
        Update: {
          address?: string | null
          contactEmail?: string | null
          contactPhone?: string | null
          createdAt?: string
          id?: string
          isActive?: boolean
          metadata?: Json | null
          name?: string
          updatedAt?: string | null
        }
        Relationships: []
      }
      escalation_events: {
        Row: {
          createdAt: string
          currentLevel: string
          data: Json | null
          id: string
          itemId: string
          itemType: string
          notes: string | null
          resolvedAt: string | null
          resolvedBy: string | null
          ruleId: string
          type: string
        }
        Insert: {
          createdAt?: string
          currentLevel: string
          data?: Json | null
          id?: string
          itemId: string
          itemType: string
          notes?: string | null
          resolvedAt?: string | null
          resolvedBy?: string | null
          ruleId: string
          type: string
        }
        Update: {
          createdAt?: string
          currentLevel?: string
          data?: Json | null
          id?: string
          itemId?: string
          itemType?: string
          notes?: string | null
          resolvedAt?: string | null
          resolvedBy?: string | null
          ruleId?: string
          type?: string
        }
        Relationships: [
          {
            foreignKeyName: "escalation_events_resolvedBy_fkey"
            columns: ["resolvedBy"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      inventory_items: {
        Row: {
          category: string | null
          createdAt: string
          currentStock: number
          description: string | null
          id: string
          location: string | null
          maxStock: number | null
          metadata: Json | null
          minStock: number
          name: string
          sku: string | null
          supplier: string | null
          unit: string | null
          unitCost: number | null
          updatedAt: string | null
        }
        Insert: {
          category?: string | null
          createdAt?: string
          currentStock?: number
          description?: string | null
          id: string
          location?: string | null
          maxStock?: number | null
          metadata?: Json | null
          minStock?: number
          name: string
          sku?: string | null
          supplier?: string | null
          unit?: string | null
          unitCost?: number | null
          updatedAt?: string | null
        }
        Update: {
          category?: string | null
          createdAt?: string
          currentStock?: number
          description?: string | null
          id?: string
          location?: string | null
          maxStock?: number | null
          metadata?: Json | null
          minStock?: number
          name?: string
          sku?: string | null
          supplier?: string | null
          unit?: string | null
          unitCost?: number | null
          updatedAt?: string | null
        }
        Relationships: []
      }
      notifications: {
        Row: {
          actions: string[] | null
          channel: string
          createdAt: string
          data: Json | null
          expiresAt: string | null
          id: string
          isRead: boolean
          message: string
          priority: string
          readAt: string | null
          relatedId: string | null
          relatedType: string | null
          title: string
          type: string
          userId: string
        }
        Insert: {
          actions?: string[] | null
          channel: string
          createdAt?: string
          data?: Json | null
          expiresAt?: string | null
          id?: string
          isRead?: boolean
          message: string
          priority: string
          readAt?: string | null
          relatedId?: string | null
          relatedType?: string | null
          title: string
          type: string
          userId: string
        }
        Update: {
          actions?: string[] | null
          channel?: string
          createdAt?: string
          data?: Json | null
          expiresAt?: string | null
          id?: string
          isRead?: boolean
          message?: string
          priority?: string
          readAt?: string | null
          relatedId?: string | null
          relatedType?: string | null
          title?: string
          type?: string
          userId?: string
        }
        Relationships: [
          {
            foreignKeyName: "notifications_userId_fkey"
            columns: ["userId"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      parts_requests: {
        Row: {
          approvedAt: string | null
          approvedBy: string | null
          createdAt: string
          id: string
          metadata: Json | null
          rejectedAt: string | null
          rejectedBy: string | null
          rejectionReason: string | null
          requestedAt: string
          requestedBy: string
          requestedParts: Json
          status: string
          updatedAt: string | null
          workOrderId: string | null
        }
        Insert: {
          approvedAt?: string | null
          approvedBy?: string | null
          createdAt?: string
          id?: string
          metadata?: Json | null
          rejectedAt?: string | null
          rejectedBy?: string | null
          rejectionReason?: string | null
          requestedAt?: string
          requestedBy: string
          requestedParts: Json
          status: string
          updatedAt?: string | null
          workOrderId?: string | null
        }
        Update: {
          approvedAt?: string | null
          approvedBy?: string | null
          createdAt?: string
          id?: string
          metadata?: Json | null
          rejectedAt?: string | null
          rejectedBy?: string | null
          rejectionReason?: string | null
          requestedAt?: string
          requestedBy?: string
          requestedParts?: Json
          status?: string
          updatedAt?: string | null
          workOrderId?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "parts_requests_approvedBy_fkey"
            columns: ["approvedBy"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "parts_requests_rejectedBy_fkey"
            columns: ["rejectedBy"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "parts_requests_requestedBy_fkey"
            columns: ["requestedBy"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "parts_requests_workOrderId_fkey"
            columns: ["workOrderId"]
            isOneToOne: false
            referencedRelation: "work_orders"
            referencedColumns: ["id"]
          },
        ]
      }
      pm_tasks: {
        Row: {
          assetId: string
          assignedTechnicianIds: string[] | null
          completionPhotoPath: string | null
          createdAt: string
          description: string | null
          estimatedDuration: number | null
          frequency: string
          frequencyValue: number
          id: string
          idempotencyKey: string | null
          lastCompletedDate: string | null
          metadata: Json | null
          nextDueDate: string
          status: string
          taskName: string
          updatedAt: string | null
        }
        Insert: {
          assetId: string
          assignedTechnicianIds?: string[] | null
          completionPhotoPath?: string | null
          createdAt?: string
          description?: string | null
          estimatedDuration?: number | null
          frequency: string
          frequencyValue: number
          id: string
          idempotencyKey?: string | null
          lastCompletedDate?: string | null
          metadata?: Json | null
          nextDueDate: string
          status: string
          taskName: string
          updatedAt?: string | null
        }
        Update: {
          assetId?: string
          assignedTechnicianIds?: string[] | null
          completionPhotoPath?: string | null
          createdAt?: string
          description?: string | null
          estimatedDuration?: number | null
          frequency?: string
          frequencyValue?: number
          id?: string
          idempotencyKey?: string | null
          lastCompletedDate?: string | null
          metadata?: Json | null
          nextDueDate?: string
          status?: string
          taskName?: string
          updatedAt?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "pm_tasks_assetId_fkey"
            columns: ["assetId"]
            isOneToOne: false
            referencedRelation: "assets"
            referencedColumns: ["id"]
          },
        ]
      }
      purchase_orders: {
        Row: {
          createdAt: string
          id: string
          metadata: Json | null
          orderedAt: string
          orderedItems: Json
          orderNumber: string | null
          receivedAt: string | null
          requestedBy: string
          status: string
          totalAmount: number | null
          updatedAt: string | null
        }
        Insert: {
          createdAt?: string
          id?: string
          metadata?: Json | null
          orderedAt?: string
          orderedItems: Json
          orderNumber?: string | null
          receivedAt?: string | null
          requestedBy: string
          status: string
          totalAmount?: number | null
          updatedAt?: string | null
        }
        Update: {
          createdAt?: string
          id?: string
          metadata?: Json | null
          orderedAt?: string
          orderedItems?: Json
          orderNumber?: string | null
          receivedAt?: string | null
          requestedBy?: string
          status?: string
          totalAmount?: number | null
          updatedAt?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "purchase_orders_requestedBy_fkey"
            columns: ["requestedBy"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      users: {
        Row: {
          companyId: string | null
          createdAt: string
          department: string | null
          email: string
          id: string
          isActive: boolean
          lastLoginAt: string | null
          name: string
          role: string
          updatedAt: string | null
          workEmail: string | null
        }
        Insert: {
          companyId?: string | null
          createdAt?: string
          department?: string | null
          email: string
          id: string
          isActive?: boolean
          lastLoginAt?: string | null
          name: string
          role: string
          updatedAt?: string | null
          workEmail?: string | null
        }
        Update: {
          companyId?: string | null
          createdAt?: string
          department?: string | null
          email?: string
          id?: string
          isActive?: boolean
          lastLoginAt?: string | null
          name?: string
          role?: string
          updatedAt?: string | null
          workEmail?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "users_companyId_fkey"
            columns: ["companyId"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
        ]
      }
      vendors: {
        Row: {
          address: string | null
          contactEmail: string | null
          contactPhone: string | null
          createdAt: string
          id: string
          isActive: boolean
          name: string
          notes: string | null
          rating: number | null
          updatedAt: string | null
          website: string | null
        }
        Insert: {
          address?: string | null
          contactEmail?: string | null
          contactPhone?: string | null
          createdAt?: string
          id?: string
          isActive?: boolean
          name: string
          notes?: string | null
          rating?: number | null
          updatedAt?: string | null
          website?: string | null
        }
        Update: {
          address?: string | null
          contactEmail?: string | null
          contactPhone?: string | null
          createdAt?: string
          id?: string
          isActive?: boolean
          name?: string
          notes?: string | null
          rating?: number | null
          updatedAt?: string | null
          website?: string | null
        }
        Relationships: []
      }
      work_orders: {
        Row: {
          activityHistory: Json | null
          actualCost: number | null
          afterPhotoPath: string | null
          assetId: string | null
          assignedAt: string | null
          assignedTechnicianId: string | null
          assignedTechnicianIds: string[] | null
          beforePhotoPath: string | null
          category: string | null
          closedAt: string | null
          companyId: string | null
          completedAt: string | null
          completionPhotoPath: string | null
          correctiveActions: string | null
          createdAt: string
          customerEmail: string | null
          customerName: string | null
          customerPhone: string | null
          customerSignature: string | null
          estimatedCost: number | null
          id: string
          idempotencyKey: string | null
          isOffline: boolean | null
          isPaused: boolean | null
          laborCost: number | null
          laborHours: number | null
          lastSyncedAt: string | null
          location: string | null
          metadata: Json | null
          nextMaintenanceDate: string | null
          notes: string | null
          partsCost: number | null
          partsUsed: string[] | null
          pausedAt: string | null
          pauseHistory: Json | null
          pauseReason: string | null
          photoPath: string | null
          primaryTechnicianId: string | null
          priority: string
          problemDescription: string
          recommendations: string | null
          requestorId: string
          requestorName: string | null
          requestorSignature: string | null
          resumedAt: string | null
          startedAt: string | null
          status: string
          technicianEffortMinutes: Json | null
          technicianNotes: string | null
          technicianSignature: string | null
          ticketNumber: string
          totalCost: number | null
          updatedAt: string
        }
        Insert: {
          activityHistory?: Json | null
          actualCost?: number | null
          afterPhotoPath?: string | null
          assetId?: string | null
          assignedAt?: string | null
          assignedTechnicianId?: string | null
          assignedTechnicianIds?: string[] | null
          beforePhotoPath?: string | null
          category?: string | null
          closedAt?: string | null
          companyId?: string | null
          completedAt?: string | null
          completionPhotoPath?: string | null
          correctiveActions?: string | null
          createdAt?: string
          customerEmail?: string | null
          customerName?: string | null
          customerPhone?: string | null
          customerSignature?: string | null
          estimatedCost?: number | null
          id: string
          idempotencyKey?: string | null
          isOffline?: boolean | null
          isPaused?: boolean | null
          laborCost?: number | null
          laborHours?: number | null
          lastSyncedAt?: string | null
          location?: string | null
          metadata?: Json | null
          nextMaintenanceDate?: string | null
          notes?: string | null
          partsCost?: number | null
          partsUsed?: string[] | null
          pausedAt?: string | null
          pauseHistory?: Json | null
          pauseReason?: string | null
          photoPath?: string | null
          primaryTechnicianId?: string | null
          priority: string
          problemDescription: string
          recommendations?: string | null
          requestorId: string
          requestorName?: string | null
          requestorSignature?: string | null
          resumedAt?: string | null
          startedAt?: string | null
          status: string
          technicianEffortMinutes?: Json | null
          technicianNotes?: string | null
          technicianSignature?: string | null
          ticketNumber: string
          totalCost?: number | null
          updatedAt?: string
        }
        Update: {
          activityHistory?: Json | null
          actualCost?: number | null
          afterPhotoPath?: string | null
          assetId?: string | null
          assignedAt?: string | null
          assignedTechnicianId?: string | null
          assignedTechnicianIds?: string[] | null
          beforePhotoPath?: string | null
          category?: string | null
          closedAt?: string | null
          companyId?: string | null
          completedAt?: string | null
          completionPhotoPath?: string | null
          correctiveActions?: string | null
          createdAt?: string
          customerEmail?: string | null
          customerName?: string | null
          customerPhone?: string | null
          customerSignature?: string | null
          estimatedCost?: number | null
          id?: string
          idempotencyKey?: string | null
          isOffline?: boolean | null
          isPaused?: boolean | null
          laborCost?: number | null
          laborHours?: number | null
          lastSyncedAt?: string | null
          location?: string | null
          metadata?: Json | null
          nextMaintenanceDate?: string | null
          notes?: string | null
          partsCost?: number | null
          partsUsed?: string[] | null
          pausedAt?: string | null
          pauseHistory?: Json | null
          pauseReason?: string | null
          photoPath?: string | null
          primaryTechnicianId?: string | null
          priority?: string
          problemDescription?: string
          recommendations?: string | null
          requestorId?: string
          requestorName?: string | null
          requestorSignature?: string | null
          resumedAt?: string | null
          startedAt?: string | null
          status?: string
          technicianEffortMinutes?: Json | null
          technicianNotes?: string | null
          technicianSignature?: string | null
          ticketNumber?: string
          totalCost?: number | null
          updatedAt?: string
        }
        Relationships: [
          {
            foreignKeyName: "work_orders_assetId_fkey"
            columns: ["assetId"]
            isOneToOne: false
            referencedRelation: "assets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "work_orders_assignedTechnicianId_fkey"
            columns: ["assignedTechnicianId"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "work_orders_companyId_fkey"
            columns: ["companyId"]
            isOneToOne: false
            referencedRelation: "companies"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "work_orders_primaryTechnicianId_fkey"
            columns: ["primaryTechnicianId"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "work_orders_requestorId_fkey"
            columns: ["requestorId"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
      workflows: {
        Row: {
          approvers: string[] | null
          assignedToUserId: string | null
          completedAt: string | null
          createdAt: string
          createdByUserId: string
          currentStep: number
          data: Json | null
          description: string | null
          id: string
          metadata: Json | null
          status: string
          stepHistory: Json | null
          title: string
          totalSteps: number
          updatedAt: string | null
          workflowType: string
        }
        Insert: {
          approvers?: string[] | null
          assignedToUserId?: string | null
          completedAt?: string | null
          createdAt?: string
          createdByUserId: string
          currentStep?: number
          data?: Json | null
          description?: string | null
          id: string
          metadata?: Json | null
          status: string
          stepHistory?: Json | null
          title: string
          totalSteps?: number
          updatedAt?: string | null
          workflowType: string
        }
        Update: {
          approvers?: string[] | null
          assignedToUserId?: string | null
          completedAt?: string | null
          createdAt?: string
          createdByUserId?: string
          currentStep?: number
          data?: Json | null
          description?: string | null
          id?: string
          metadata?: Json | null
          status?: string
          stepHistory?: Json | null
          title?: string
          totalSteps?: number
          updatedAt?: string | null
          workflowType?: string
        }
        Relationships: [
          {
            foreignKeyName: "workflows_assignedToUserId_fkey"
            columns: ["assignedToUserId"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "workflows_createdByUserId_fkey"
            columns: ["createdByUserId"]
            isOneToOne: false
            referencedRelation: "users"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      check_user_is_admin_or_manager: { Args: never; Returns: boolean }
      get_current_user_company_id: { Args: never; Returns: string }
      get_my_email: { Args: never; Returns: string }
      get_my_role: { Args: never; Returns: string }
      is_admin_or_manager: { Args: never; Returns: boolean }
      is_current_user_admin_or_manager: { Args: never; Returns: boolean }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
  storage: {
    Tables: {
      buckets: {
        Row: {
          allowed_mime_types: string[] | null
          avif_autodetection: boolean | null
          created_at: string | null
          file_size_limit: number | null
          id: string
          name: string
          owner: string | null
          owner_id: string | null
          public: boolean | null
          type: Database["storage"]["Enums"]["buckettype"]
          updated_at: string | null
        }
        Insert: {
          allowed_mime_types?: string[] | null
          avif_autodetection?: boolean | null
          created_at?: string | null
          file_size_limit?: number | null
          id: string
          name: string
          owner?: string | null
          owner_id?: string | null
          public?: boolean | null
          type?: Database["storage"]["Enums"]["buckettype"]
          updated_at?: string | null
        }
        Update: {
          allowed_mime_types?: string[] | null
          avif_autodetection?: boolean | null
          created_at?: string | null
          file_size_limit?: number | null
          id?: string
          name?: string
          owner?: string | null
          owner_id?: string | null
          public?: boolean | null
          type?: Database["storage"]["Enums"]["buckettype"]
          updated_at?: string | null
        }
        Relationships: []
      }
      buckets_analytics: {
        Row: {
          created_at: string
          deleted_at: string | null
          format: string
          id: string
          name: string
          type: Database["storage"]["Enums"]["buckettype"]
          updated_at: string
        }
        Insert: {
          created_at?: string
          deleted_at?: string | null
          format?: string
          id?: string
          name: string
          type?: Database["storage"]["Enums"]["buckettype"]
          updated_at?: string
        }
        Update: {
          created_at?: string
          deleted_at?: string | null
          format?: string
          id?: string
          name?: string
          type?: Database["storage"]["Enums"]["buckettype"]
          updated_at?: string
        }
        Relationships: []
      }
      buckets_vectors: {
        Row: {
          created_at: string
          id: string
          type: Database["storage"]["Enums"]["buckettype"]
          updated_at: string
        }
        Insert: {
          created_at?: string
          id: string
          type?: Database["storage"]["Enums"]["buckettype"]
          updated_at?: string
        }
        Update: {
          created_at?: string
          id?: string
          type?: Database["storage"]["Enums"]["buckettype"]
          updated_at?: string
        }
        Relationships: []
      }
      migrations: {
        Row: {
          executed_at: string | null
          hash: string
          id: number
          name: string
        }
        Insert: {
          executed_at?: string | null
          hash: string
          id: number
          name: string
        }
        Update: {
          executed_at?: string | null
          hash?: string
          id?: number
          name?: string
        }
        Relationships: []
      }
      objects: {
        Row: {
          bucket_id: string | null
          created_at: string | null
          id: string
          last_accessed_at: string | null
          metadata: Json | null
          name: string | null
          owner: string | null
          owner_id: string | null
          path_tokens: string[] | null
          updated_at: string | null
          user_metadata: Json | null
          version: string | null
        }
        Insert: {
          bucket_id?: string | null
          created_at?: string | null
          id?: string
          last_accessed_at?: string | null
          metadata?: Json | null
          name?: string | null
          owner?: string | null
          owner_id?: string | null
          path_tokens?: string[] | null
          updated_at?: string | null
          user_metadata?: Json | null
          version?: string | null
        }
        Update: {
          bucket_id?: string | null
          created_at?: string | null
          id?: string
          last_accessed_at?: string | null
          metadata?: Json | null
          name?: string | null
          owner?: string | null
          owner_id?: string | null
          path_tokens?: string[] | null
          updated_at?: string | null
          user_metadata?: Json | null
          version?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "objects_bucketId_fkey"
            columns: ["bucket_id"]
            isOneToOne: false
            referencedRelation: "buckets"
            referencedColumns: ["id"]
          },
        ]
      }
      s3_multipart_uploads: {
        Row: {
          bucket_id: string
          created_at: string
          id: string
          in_progress_size: number
          key: string
          owner_id: string | null
          upload_signature: string
          user_metadata: Json | null
          version: string
        }
        Insert: {
          bucket_id: string
          created_at?: string
          id: string
          in_progress_size?: number
          key: string
          owner_id?: string | null
          upload_signature: string
          user_metadata?: Json | null
          version: string
        }
        Update: {
          bucket_id?: string
          created_at?: string
          id?: string
          in_progress_size?: number
          key?: string
          owner_id?: string | null
          upload_signature?: string
          user_metadata?: Json | null
          version?: string
        }
        Relationships: [
          {
            foreignKeyName: "s3_multipart_uploads_bucket_id_fkey"
            columns: ["bucket_id"]
            isOneToOne: false
            referencedRelation: "buckets"
            referencedColumns: ["id"]
          },
        ]
      }
      s3_multipart_uploads_parts: {
        Row: {
          bucket_id: string
          created_at: string
          etag: string
          id: string
          key: string
          owner_id: string | null
          part_number: number
          size: number
          upload_id: string
          version: string
        }
        Insert: {
          bucket_id: string
          created_at?: string
          etag: string
          id?: string
          key: string
          owner_id?: string | null
          part_number: number
          size?: number
          upload_id: string
          version: string
        }
        Update: {
          bucket_id?: string
          created_at?: string
          etag?: string
          id?: string
          key?: string
          owner_id?: string | null
          part_number?: number
          size?: number
          upload_id?: string
          version?: string
        }
        Relationships: [
          {
            foreignKeyName: "s3_multipart_uploads_parts_bucket_id_fkey"
            columns: ["bucket_id"]
            isOneToOne: false
            referencedRelation: "buckets"
            referencedColumns: ["id"]
          },
          {
            foreignKeyName: "s3_multipart_uploads_parts_upload_id_fkey"
            columns: ["upload_id"]
            isOneToOne: false
            referencedRelation: "s3_multipart_uploads"
            referencedColumns: ["id"]
          },
        ]
      }
      vector_indexes: {
        Row: {
          bucket_id: string
          created_at: string
          data_type: string
          dimension: number
          distance_metric: string
          id: string
          metadata_configuration: Json | null
          name: string
          updated_at: string
        }
        Insert: {
          bucket_id: string
          created_at?: string
          data_type: string
          dimension: number
          distance_metric: string
          id?: string
          metadata_configuration?: Json | null
          name: string
          updated_at?: string
        }
        Update: {
          bucket_id?: string
          created_at?: string
          data_type?: string
          dimension?: number
          distance_metric?: string
          id?: string
          metadata_configuration?: Json | null
          name?: string
          updated_at?: string
        }
        Relationships: [
          {
            foreignKeyName: "vector_indexes_bucket_id_fkey"
            columns: ["bucket_id"]
            isOneToOne: false
            referencedRelation: "buckets_vectors"
            referencedColumns: ["id"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      can_insert_object: {
        Args: { bucketid: string; metadata: Json; name: string; owner: string }
        Returns: undefined
      }
      delete_leaf_prefixes: {
        Args: { bucket_ids: string[]; names: string[] }
        Returns: undefined
      }
      extension: { Args: { name: string }; Returns: string }
      filename: { Args: { name: string }; Returns: string }
      foldername: { Args: { name: string }; Returns: string[] }
      get_common_prefix: {
        Args: { p_delimiter: string; p_key: string; p_prefix: string }
        Returns: string
      }
      get_level: { Args: { name: string }; Returns: number }
      get_prefix: { Args: { name: string }; Returns: string }
      get_prefixes: { Args: { name: string }; Returns: string[] }
      get_size_by_bucket: {
        Args: never
        Returns: {
          bucket_id: string
          size: number
        }[]
      }
      list_multipart_uploads_with_delimiter: {
        Args: {
          bucket_id: string
          delimiter_param: string
          max_keys?: number
          next_key_token?: string
          next_upload_token?: string
          prefix_param: string
        }
        Returns: {
          created_at: string
          id: string
          key: string
        }[]
      }
      list_objects_with_delimiter: {
        Args: {
          _bucket_id: string
          delimiter_param: string
          max_keys?: number
          next_token?: string
          prefix_param: string
          sort_order?: string
          start_after?: string
        }
        Returns: {
          created_at: string
          id: string
          last_accessed_at: string
          metadata: Json
          name: string
          updated_at: string
        }[]
      }
      operation: { Args: never; Returns: string }
      search: {
        Args: {
          bucketname: string
          levels?: number
          limits?: number
          offsets?: number
          prefix: string
          search?: string
          sortcolumn?: string
          sortorder?: string
        }
        Returns: {
          created_at: string
          id: string
          last_accessed_at: string
          metadata: Json
          name: string
          updated_at: string
        }[]
      }
      search_by_timestamp: {
        Args: {
          p_bucket_id: string
          p_level: number
          p_limit: number
          p_prefix: string
          p_sort_column: string
          p_sort_column_after: string
          p_sort_order: string
          p_start_after: string
        }
        Returns: {
          created_at: string
          id: string
          key: string
          last_accessed_at: string
          metadata: Json
          name: string
          updated_at: string
        }[]
      }
      search_legacy_v1: {
        Args: {
          bucketname: string
          levels?: number
          limits?: number
          offsets?: number
          prefix: string
          search?: string
          sortcolumn?: string
          sortorder?: string
        }
        Returns: {
          created_at: string
          id: string
          last_accessed_at: string
          metadata: Json
          name: string
          updated_at: string
        }[]
      }
      search_v2: {
        Args: {
          bucket_name: string
          levels?: number
          limits?: number
          prefix: string
          sort_column?: string
          sort_column_after?: string
          sort_order?: string
          start_after?: string
        }
        Returns: {
          created_at: string
          id: string
          key: string
          last_accessed_at: string
          metadata: Json
          name: string
          updated_at: string
        }[]
      }
    }
    Enums: {
      buckettype: "STANDARD" | "ANALYTICS" | "VECTOR"
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  graphql_public: {
    Enums: {},
  },
  public: {
    Enums: {},
  },
  storage: {
    Enums: {
      buckettype: ["STANDARD", "ANALYTICS", "VECTOR"],
    },
  },
} as const