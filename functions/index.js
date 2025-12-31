// Firebase Cloud Functions for Q-AUTO CMMS
const functions = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");

// Initialize Firebase Admin SDK
admin.initializeApp();

const db = admin.firestore();

// ============================================================================
// WORK ORDER FUNCTIONS
// ============================================================================

/**
 * Triggered when a work order is created
 * Sends notifications to relevant users
 */
exports.onWorkOrderCreated = functions.firestore
  .document("work_orders/{workOrderId}")
  .onCreate(async (snap, context) => {
    const workOrder = snap.data();
    const workOrderId = context.params.workOrderId;

    console.log(`Work order created: ${workOrderId}`);

    try {
      // Server-side dedupe: If idempotencyKey exists, ensure only one doc with same key
      if (workOrder.idempotencyKey) {
        const dupSnap = await db
          .collection("work_orders")
          .where("idempotencyKey", "==", workOrder.idempotencyKey)
          .get();
        if (dupSnap.size > 1) {
          // Keep the newest and remove older duplicates
          const docs = dupSnap.docs.sort(
            (a, b) => b.createTime.seconds - a.createTime.seconds
          );
          const toDelete = docs.slice(1);
          const batch = db.batch();
          toDelete.forEach((d) => batch.delete(d.ref));
          await batch.commit();
          console.log(
            `Deduped work_orders for key ${workOrder.idempotencyKey}: removed ${toDelete.length}`
          );
        }
      }
      // Send notification to managers
      await sendNotificationToManagers({
        title: "New Work Order Created",
        body: `Work Order ${workOrder.ticketNumber} has been created`,
        data: {
          type: "work_order_created",
          workOrderId: workOrderId,
          ticketNumber: workOrder.ticketNumber,
        },
      });

      // If assigned to technician, notify them
      if (workOrder.assignedTechnicianId) {
        await sendNotificationToUser(workOrder.assignedTechnicianId, {
          title: "Work Order Assigned",
          body: `You have been assigned Work Order ${workOrder.ticketNumber}`,
          data: {
            type: "work_order_assigned",
            workOrderId: workOrderId,
            ticketNumber: workOrder.ticketNumber,
          },
        });
      }

      // Log audit event
      await logAuditEvent("work_order_created", workOrderId, {
        ticketNumber: workOrder.ticketNumber,
        assetId: workOrder.assetId,
        requestorId: workOrder.requestorId,
      });
    } catch (error) {
      console.error("Error in onWorkOrderCreated:", error);
    }
  });

/**
 * Triggered when a work order is updated
 * Sends notifications for status changes
 */
exports.onWorkOrderUpdated = functions.firestore
  .document("work_orders/{workOrderId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const workOrderId = context.params.workOrderId;

    // Check if status changed
    if (before.status !== after.status) {
      console.log(
        `Work order status changed: ${before.status} -> ${after.status}`
      );

      try {
        // Notify relevant users based on status change
        await handleWorkOrderStatusChange(workOrderId, before, after);

        // Log audit event
        await logAuditEvent("work_order_status_changed", workOrderId, {
          ticketNumber: after.ticketNumber,
          oldStatus: before.status,
          newStatus: after.status,
          changedBy: after.updatedBy || "system",
        });
      } catch (error) {
        console.error("Error in onWorkOrderUpdated:", error);
      }
    }
  });

// ============================================================================
// PM TASK FUNCTIONS
// ============================================================================

/**
 * Triggered when a PM task is created
 */
exports.onPMTaskCreated = functions.firestore
  .document("pm_tasks/{pmTaskId}")
  .onCreate(async (snap, context) => {
    const pmTask = snap.data();
    const pmTaskId = context.params.pmTaskId;

    console.log(`PM task created: ${pmTaskId}`);

    try {
      // Server-side dedupe by idempotencyKey if present
      if (pmTask.idempotencyKey) {
        const dupSnap = await db
          .collection("pm_tasks")
          .where("idempotencyKey", "==", pmTask.idempotencyKey)
          .get();
        if (dupSnap.size > 1) {
          const docs = dupSnap.docs.sort(
            (a, b) => b.createTime.seconds - a.createTime.seconds
          );
          const toDelete = docs.slice(1);
          const batch = db.batch();
          toDelete.forEach((d) => batch.delete(d.ref));
          await batch.commit();
          console.log(
            `Deduped pm_tasks for key ${pmTask.idempotencyKey}: removed ${toDelete.length}`
          );
        }
      }
      // Send notification to assigned technician
      if (pmTask.assignedTechnicianId) {
        await sendNotificationToUser(pmTask.assignedTechnicianId, {
          title: "PM Task Assigned",
          body: `You have been assigned PM Task: ${pmTask.title}`,
          data: {
            type: "pm_task_assigned",
            pmTaskId: pmTaskId,
            title: pmTask.title,
          },
        });
      }

      // Log audit event
      await logAuditEvent("pm_task_created", pmTaskId, {
        title: pmTask.title,
        assetId: pmTask.assetId,
        assignedTechnicianId: pmTask.assignedTechnicianId,
      });
    } catch (error) {
      console.error("Error in onPMTaskCreated:", error);
    }
  });

// ============================================================================
// INVENTORY FUNCTIONS
// ============================================================================

/**
 * Triggered when inventory item stock is updated
 * Checks for low stock alerts
 */
exports.onInventoryUpdated = functions.firestore
  .document("inventory_items/{itemId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const itemId = context.params.itemId;

    // Check if stock level changed and is now low
    if (
      before.currentStock !== after.currentStock &&
      after.currentStock <= after.lowStockThreshold
    ) {
      console.log(`Low stock alert for item: ${after.name}`);

      try {
        // Send low stock notification to managers
        await sendNotificationToManagers({
          title: "Low Stock Alert",
          body: `${after.name} is running low (${after.currentStock} remaining)`,
          data: {
            type: "low_stock_alert",
            itemId: itemId,
            itemName: after.name,
            currentStock: after.currentStock,
            threshold: after.lowStockThreshold,
          },
        });

        // Log audit event
        await logAuditEvent("low_stock_alert", itemId, {
          itemName: after.name,
          currentStock: after.currentStock,
          threshold: after.lowStockThreshold,
        });
      } catch (error) {
        console.error("Error in onInventoryUpdated:", error);
      }
    }
  });

// ============================================================================
// ANALYTICS FUNCTIONS
// ============================================================================

/**
 * Scheduled function to calculate daily analytics
 * Runs every day at midnight
 */
exports.calculateDailyAnalytics = functions.pubsub
  .schedule("0 0 * * *")
  .timeZone("Asia/Qatar")
  .onRun(async (context) => {
    console.log("Calculating daily analytics...");

    try {
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);

      // Get work orders from yesterday
      const workOrdersSnapshot = await db
        .collection("work_orders")
        .where("createdAt", ">=", yesterday)
        .where("createdAt", "<", new Date())
        .get();

      const workOrders = workOrdersSnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      // Calculate analytics
      const analytics = await calculateAnalytics(workOrders);

      // Store analytics
      await db
        .collection("analytics")
        .doc(yesterday.toISOString().split("T")[0])
        .set({
          date: yesterday,
          type: "daily",
          data: analytics,
          calculatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      console.log("Daily analytics calculated and stored");
    } catch (error) {
      console.error("Error calculating daily analytics:", error);
    }
  });

/**
 * Callable: Create or update user document with strict validation
 */
exports.createOrUpsertUser = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Authentication is required."
    );
  }

  const email = (data.email || "").toLowerCase().trim();
  const name = (data.name || "").trim();
  const role = (data.role || "technician").toLowerCase().trim();
  const allowedRoles = ["admin", "manager", "technician", "requestor"];

  if (!email) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Email is required."
    );
  }
  if (!name) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Name is required."
    );
  }
  if (!allowedRoles.includes(role)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      `Invalid role "${role}".`
    );
  }

  const userId =
    (typeof data.id === "string" && data.id.trim().length > 0
      ? data.id.trim()
      : generateDeterministicUserId(email));

  try {
    // Ensure email uniqueness (excluding this user)
    const dupSnap = await db.collection("users").where("email", "==", email).get();
    if (!dupSnap.empty) {
      const conflict = dupSnap.docs.find((doc) => doc.id !== userId);
      if (conflict) {
        throw new functions.https.HttpsError(
          "already-exists",
          `Email ${email} already exists for another user.`
        );
      }
    }

    const userRef = db.collection("users").doc(userId);
    const existing = await userRef.get();
    const timestamp = admin.firestore.FieldValue.serverTimestamp();

    const payload = {
      id: userId,
      email,
      name,
      role,
      department: data.department || null,
      workEmail: data.workEmail || null,
      isActive:
        typeof data.isActive === "boolean" ? data.isActive : true,
      updatedAt: timestamp,
      updatedBy: context.auth.uid,
    };

    if (!existing.exists) {
      payload.createdAt = timestamp;
      payload.createdBy = context.auth.uid;
    }

    await userRef.set(payload, {merge: true});

    await logAuditEvent("user_upserted", userId, {
      name,
      email,
      role,
      performedBy: context.auth.uid,
    });

    return {
      id: userId,
      created: !existing.exists,
      message: !existing.exists
        ? "User created"
        : "User updated",
    };
  } catch (error) {
    console.error("Error in createOrUpsertUser:", error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      "internal",
      typeof error.message === "string"
        ? error.message
        : "Failed to create or update user"
    );
  }
});

function generateDeterministicUserId(email) {
  const normalized = email.toLowerCase().trim();
  // Extract email prefix (before @) and sanitize
  const emailPrefix = normalized.split("@")[0];
  const sanitized = emailPrefix
    .replace(/[^a-z0-9_-]/g, "_")
    .substring(0, Math.min(emailPrefix.length, 20));
  
  // Add hash suffix for uniqueness if email is too short
  if (sanitized.length < 5) {
    const hash = crypto.createHash("sha256").update(normalized).digest("hex");
    return `USER-${sanitized}-${hash.substring(0, 6)}`;
  }
  return `USER-${sanitized}`;
}

// ============================================================================
// NOTIFICATION FUNCTIONS
// ============================================================================

/**
 * Send notification to all managers
 */
async function sendNotificationToManagers(notification) {
  try {
    const managersSnapshot = await db
      .collection("users")
      .where("role", "==", "manager")
      .get();

    const batch = db.batch();

    managersSnapshot.docs.forEach((doc) => {
      const notificationRef = db.collection("notifications").doc();
      batch.set(notificationRef, {
        ...notification,
        userId: doc.id,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        read: false,
      });
    });

    await batch.commit();
    console.log(
      `Notification sent to ${managersSnapshot.docs.length} managers`
    );
  } catch (error) {
    console.error("Error sending notification to managers:", error);
  }
}

/**
 * Send notification to specific user
 */
async function sendNotificationToUser(userId, notification) {
  try {
    await db.collection("notifications").add({
      ...notification,
      userId: userId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      read: false,
    });

    console.log(`Notification sent to user: ${userId}`);
  } catch (error) {
    console.error("Error sending notification to user:", error);
  }
}

// ============================================================================
// AUDIT LOGGING
// ============================================================================

/**
 * Log audit event
 */
async function logAuditEvent(eventType, resourceId, data) {
  try {
    await db.collection("audit_logs").add({
      eventType: eventType,
      resourceId: resourceId,
      data: data,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      userId: "system", // In real implementation, get from auth context
    });

    console.log(`Audit event logged: ${eventType} for ${resourceId}`);
  } catch (error) {
    console.error("Error logging audit event:", error);
  }
}

// ============================================================================
// ANALYTICS CALCULATION
// ============================================================================

/**
 * Calculate analytics for given work orders
 */
async function calculateAnalytics(workOrders) {
  try {
    const totalWorkOrders = workOrders.length;
    const completedWorkOrders = workOrders.filter(
      (wo) => wo.status === "completed"
    ).length;
    const criticalWorkOrders = workOrders.filter(
      (wo) => wo.priority === "critical"
    ).length;

    // Calculate MTTR
    const completedWithTimes = workOrders.filter(
      (wo) => wo.status === "completed" && wo.startedAt && wo.completedAt
    );

    let totalRepairTime = 0;
    completedWithTimes.forEach((wo) => {
      const repairTime = wo.completedAt.toDate() - wo.startedAt.toDate();
      totalRepairTime += repairTime;
    });

    const mttr =
      completedWithTimes.length > 0
        ? totalRepairTime / completedWithTimes.length / (1000 * 60 * 60)
        : 0; // Convert to hours

    // Calculate completion rate
    const completionRate =
      totalWorkOrders > 0 ? (completedWorkOrders / totalWorkOrders) * 100 : 0;

    return {
      totalWorkOrders,
      completedWorkOrders,
      criticalWorkOrders,
      mttr: Math.round(mttr * 100) / 100, // Round to 2 decimal places
      completionRate: Math.round(completionRate * 100) / 100,
    };
  } catch (error) {
    console.error("Error calculating analytics:", error);
    return {};
  }
}

// ============================================================================
// WORK ORDER STATUS CHANGE HANDLER
// ============================================================================

/**
 * Handle work order status changes and send appropriate notifications
 */
async function handleWorkOrderStatusChange(workOrderId, before, after) {
  try {
    const statusChangeMessages = {
      open: "Work order is open",
      assigned: "Work order has been assigned",
      inProgress: "Work order is in progress",
      completed: "Work order has been completed",
      closed: "Work order has been closed",
      cancelled: "Work order has been cancelled",
    };

    const message = statusChangeMessages[after.status];
    if (!message) return;

    // Notify requestor
    if (after.requestorId) {
      await sendNotificationToUser(after.requestorId, {
        title: "Work Order Status Update",
        body: `Work Order ${after.ticketNumber}: ${message}`,
        data: {
          type: "work_order_status_update",
          workOrderId: workOrderId,
          ticketNumber: after.ticketNumber,
          status: after.status,
        },
      });
    }

    // Notify assigned technician if status is completed/closed
    if (
      after.assignedTechnicianId &&
      (after.status === "completed" || after.status === "closed")
    ) {
      await sendNotificationToUser(after.assignedTechnicianId, {
        title: "Work Order Completed",
        body: `Work Order ${after.ticketNumber} has been ${after.status}`,
        data: {
          type: "work_order_completed",
          workOrderId: workOrderId,
          ticketNumber: after.ticketNumber,
          status: after.status,
        },
      });
    }

    // Notify managers for critical work orders
    if (
      after.priority === "critical" &&
      (after.status === "completed" || after.status === "closed")
    ) {
      await sendNotificationToManagers({
        title: "Critical Work Order Completed",
        body: `Critical Work Order ${after.ticketNumber} has been ${after.status}`,
        data: {
          type: "critical_work_order_completed",
          workOrderId: workOrderId,
          ticketNumber: after.ticketNumber,
          status: after.status,
        },
      });
    }
  } catch (error) {
    console.error("Error handling work order status change:", error);
  }
}

// All functions are exported individually above using exports.functionName
// No need for module.exports since each function is already exported
