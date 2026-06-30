# RC1 — work_orders Permission Matrix

**Scope:** `public.work_orders` effective policies after migrations through `20260703120000`.  
**Enforcement layers:** PostgreSQL RLS (row access) + `enforce_requestor_work_order_update` trigger (requestor field guard) + RPCs (`upsert_work_order`, `update_work_order_assignees`).

---

## 1. Table-level GRANTs

| Role (DB) | SELECT | INSERT | UPDATE | DELETE |
|-----------|--------|--------|--------|--------|
| `authenticated` | ✓ | ✓ | ✓ | ✓ |
| `anon` | ✗ (revoked `20260629160000`) | ✗ | ✗ | ✗ |

RLS further restricts each operation per app role.

---

## 2. RLS policies by app role

### Requestor

| Operation | Allowed when | Source |
|-----------|--------------|--------|
| **SELECT** | `"requestorId" = auth.uid()` | `20250311120000` |
| **INSERT** | `"requestorId" = auth.uid()` (direct) OR via `upsert_work_order` RPC | `20260629160000` |
| **UPDATE** | `"requestorId" = auth.uid()` (no column restriction in RLS) | `20250311120000` |
| **DELETE** | Not granted by RLS policy | ✗ |

### Technician

| Operation | Allowed when | Source |
|-----------|--------------|--------|
| **SELECT** | `auth.uid() = ANY(assignedTechnicianIds)` | `20260311180000` |
| **INSERT** | Same as requestor if `requestorId = auth.uid()` | Rare |
| **UPDATE** | `auth.uid() = ANY(assignedTechnicianIds)` | `20260311180000` |
| **DELETE** | ✗ | |

### Manager / Admin

| Operation | Allowed when | Source |
|-----------|--------------|--------|
| **SELECT** | `get_my_role() IN ('admin','manager')` | `20250311120000` |
| **INSERT** | Admin path (any requestorId via RPC or direct) | `20260629160000` |
| **UPDATE** | `get_my_role() IN ('admin','manager')` | `20250311120000` |
| **DELETE** | No explicit DELETE policy | ✗ (not used by apps) |

---

## 3. UPDATE — allowed fields by role

### Admin / Manager

**All columns** via direct UPDATE or RPC. React Admin also uses:

- `update_work_order_assignees(uuid, text[])` — assignees only (`20260629140000`, admin/manager auth inside function)
- `upsert_work_order(jsonb)` — full payload
- Direct `.update()` on detail page — status, metadata, activityHistory, reopen (web)

**Trigger:** Bypassed (`v_role IN ('admin','manager')`).

### Technician (assigned)

**Typical Flutter `updateWorkOrder` completion path** (`docs/FLUTTER_USER_FLOW.md` §4.3):

| Field group | Fields |
|-------------|--------|
| Status / time | `status`, `startedAt`, `completedAt`, `updatedAt` |
| Completion content | `correctiveActions`, `recommendations`, `technicianNotes`, `technicianSignature` |
| Photos | `completionPhotoPath`, `beforePhotoPath`, `afterPhotoPath`, `photoPath`, `metadata` |
| Pause | `isPaused`, `pausedAt`, `pauseReason`, `resumedAt`, `pauseHistory` |
| Cost (if used) | `actualCost`, `laborCost`, `partsCost`, `totalCost`, `laborHours`, `technicianEffortMinutes` |

**Trigger:** Bypassed when `auth.uid() = ANY(assignedTechnicianIds)`.

### Requestor (own row, not assigned tech)

#### A. Open / reopened — edit request

| Field | Allowed |
|-------|---------|
| `problemDescription`, `photoPath`, `metadata`, `location`, `category`, `notes`, `priority`, `updatedAt` | ✓ |
| `status`, assignees, technician completion fields | ✗ |

#### B. Reopen — `docs/WORK_ORDER_REOPEN.md`

| Field | New value |
|-------|-----------|
| `status` | `reopened` |
| Assignees / timestamps | cleared per doc |
| `metadata` | reopen keys merged |
| Completion data | preserved |

#### C. Sign-off — `docs/FLUTTER_USER_FLOW.md` §4.3 (RC1 P0-1 fix)

| Field | Allowed |
|-------|---------|
| `requestorSignature` | ✓ |
| `customerSignature` | ✓ (optional) |
| `status` | `completed`/`inProgress` → `closed` |
| `closedAt` | ✓ when closing |

**Prior bug (Batch B):** `requestorSignature` blocked → **fixed in `20260703120000`**.

---

## 4. Allow / deny verification matrix (requestor trigger path)

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Edit `problemDescription` on open WO | ALLOW |
| 2 | Add `metadata.photoPaths` on open WO | ALLOW |
| 3 | Reopen completed → `reopened`, clear assignees | ALLOW |
| 4 | Set `requestorSignature` on completed WO | ALLOW |
| 5 | Sign-off: signature + `status=closed` + `closedAt` | ALLOW |
| 6 | Set non-empty `assignedTechnicianIds` | DENY |
| 7 | Set `primaryTechnicianId` | DENY |
| 8 | Change `status` open → `assigned` | DENY |
| 9 | Set `technicianSignature` as requestor | DENY |
| 10 | Modify `correctiveActions` as requestor | DENY |
| 11 | Change `requestorId` | DENY |
| 12 | Set `actualCost` | DENY |

**DB verification:** `scripts/rc1-work-order-trigger-verify.sql`
