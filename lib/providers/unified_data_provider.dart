// Unified Data Provider - Single provider for all data across the app
// This ensures data consistency and synchronization across all screens
// NOW WITH REAL-TIME SUPABASE SYNC!

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/asset.dart';
import '../models/inventory_item.dart';
import '../models/pm_task.dart';
import '../models/user.dart';
import '../models/work_order.dart';
import '../models/workflow_models.dart';
import '../services/supabase_database_service.dart';
import '../services/supabase_storage_service.dart';
import '../services/unified_data_service.dart';

class UnifiedDataProvider with ChangeNotifier {
  // Constructor - Auto-initialize on creation
  UnifiedDataProvider() {
    debugPrint('🚀 UnifiedDataProvider: Constructor called, initializing...');
    initialize();
  }
  final UnifiedDataService _dataService = UnifiedDataService.instance;
  bool _isDisposed = false;

  // Stream subscriptions for real-time updates
  StreamSubscription<List<WorkOrder>>? _workOrdersSubscription;
  StreamSubscription<List<PMTask>>? _pmTasksSubscription;
  StreamSubscription<List<Asset>>? _assetsSubscription;
  StreamSubscription<List<User>>? _usersSubscription;
  StreamSubscription<List<InventoryItem>>? _inventorySubscription;
  StreamSubscription<List<Workflow>>? _workflowsSubscription;

  // Real-time data cache
  List<WorkOrder> _realtimeWorkOrders = [];
  List<PMTask> _realtimePMTasks = [];
  List<Asset> _realtimeAssets = [];
  List<User> _realtimeUsers = [];
  List<InventoryItem> _realtimeInventory = [];
  List<Workflow> _realtimeWorkflows = [];

  // =====================
  // De-duplication helpers
  // =====================
  List<WorkOrder> _dedupeWorkOrders(List<WorkOrder> list) {
    // Primary: by id (keep newest updatedAt)
    final byId = <String, WorkOrder>{};
    for (final wo in list) {
      final existing = byId[wo.id];
      final existingUpdatedAt = existing?.updatedAt ?? existing?.createdAt;
      final currentUpdatedAt = wo.updatedAt;
      if (existing == null ||
          (existingUpdatedAt == null) ||
          currentUpdatedAt.isAfter(existingUpdatedAt)) {
        byId[wo.id] = wo;
      }
    }

    // Secondary: by ticketNumber (guard against dual IDs for same ticket)
    final byTicket = <String, WorkOrder>{};
    for (final wo in byId.values) {
      final key = wo.ticketNumber;
      final existing = byTicket[key];
      final existingUpdatedAt = existing?.updatedAt ?? existing?.createdAt;
      final currentUpdatedAt = wo.updatedAt;
      if (existing == null ||
          (existingUpdatedAt == null) ||
          currentUpdatedAt.isAfter(existingUpdatedAt)) {
        byTicket[key] = wo;
      }
    }

    return byTicket.values.toList();
  }

  List<PMTask> _dedupePMTasks(List<PMTask> list) {
    // Primary: by id
    final byId = <String, PMTask>{};
    for (final pm in list) {
      final existing = byId[pm.id];
      var shouldReplace = existing == null;
      if (!shouldReplace) {
        final existingTime = existing.updatedAt ?? existing.createdAt;
        final currentTime = pm.updatedAt ?? pm.createdAt;
        shouldReplace = currentTime.isAfter(existingTime);
      }
      if (shouldReplace) {
        byId[pm.id] = pm;
      }
    }

    // Secondary composite key: taskName + assetId + nextDueDate
    final byComposite = <String, PMTask>{};
    for (final pm in byId.values) {
      final composite =
          '${pm.taskName.toLowerCase()}|${pm.assetId}|${pm.nextDueDate?.toIso8601String() ?? ''}';
      final existing = byComposite[composite];
      var shouldReplace = existing == null;
      if (!shouldReplace) {
        final existingTime = existing.updatedAt ?? existing.createdAt;
        final currentTime = pm.updatedAt ?? pm.createdAt;
        shouldReplace = currentTime.isAfter(existingTime);
      }
      if (shouldReplace) {
        byComposite[composite] = pm;
      }
    }

    return byComposite.values.toList();
  }

  List<User> _dedupeUsers(List<User> list) {
    // Use normalized email as key; keep most recently updated
    final byEmail = <String, User>{};
    for (final u in list) {
      final emailKey = (u.email.isNotEmpty ? u.email : u.workEmail ?? '')
          .toLowerCase()
          .trim();
      final key = emailKey.isNotEmpty ? emailKey : u.id;
      final existing = byEmail[key];
      if (existing == null ||
          ((u.updatedAt ?? u.createdAt)
              .isAfter(existing.updatedAt ?? existing.createdAt))) {
        byEmail[key] = u;
      }
    }
    return byEmail.values.toList();
  }

  // Getters for all data - Returns real-time data if available, falls back to cached
  List<WorkOrder> get workOrders => _realtimeWorkOrders.isNotEmpty
      ? _realtimeWorkOrders
      : _dataService.workOrders;
  List<PMTask> get pmTasks =>
      _realtimePMTasks.isNotEmpty ? _realtimePMTasks : _dataService.pmTasks;
  List<User> get users =>
      _realtimeUsers.isNotEmpty ? _realtimeUsers : _dataService.users;
  List<Asset> get assets =>
      _realtimeAssets.isNotEmpty ? _realtimeAssets : _dataService.assets;
  List<InventoryItem> get inventoryItems => _realtimeInventory.isNotEmpty
      ? _realtimeInventory
      : _dataService.inventoryItems;
  List<Workflow> get workflows => _realtimeWorkflows.isNotEmpty
      ? _realtimeWorkflows
      : _dataService.workflows;

  // Stream getters for direct Firestore access
  Stream<List<WorkOrder>> get workOrdersStream => _dataService.workOrdersStream;
  Stream<List<PMTask>> get pmTasksStream => _dataService.pmTasksStream;
  Stream<List<Asset>> get assetsStream => _dataService.assetsStream;
  Stream<List<User>> get usersStream => _dataService.usersStream;
  Stream<List<InventoryItem>> get inventoryItemsStream =>
      _dataService.inventoryItemsStream;
  Stream<List<Workflow>> get workflowsStream => _dataService.workflowsStream;

  // Loading states
  bool get isWorkOrdersLoading => _dataService.isWorkOrdersLoading;
  bool get isPMTasksLoading => _dataService.isPMTasksLoading;
  bool get isUsersLoading => _dataService.isUsersLoading;
  bool get isAssetsLoading => _dataService.isAssetsLoading;
  bool get isInventoryLoading => _dataService.isInventoryLoading;
  bool get isWorkflowsLoading => _dataService.isWorkflowsLoading;

  // Work order statistics - NOW USING REAL-TIME DATA!
  int get totalWorkOrders => workOrders.length;
  int get openWorkOrders => workOrders.where((wo) => wo.isOpen).length;
  int get inProgressWorkOrders =>
      workOrders.where((wo) => wo.isInProgress).length;
  int get completedWorkOrders =>
      workOrders.where((wo) => wo.isCompleted).length;
  
  // Completed work orders today
  int get completedWorkOrdersToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return workOrders.where((wo) {
      if (!wo.isCompleted || wo.completedAt == null) return false;
      final completedDate = DateTime(
        wo.completedAt!.year,
        wo.completedAt!.month,
        wo.completedAt!.day,
      );
      return completedDate.isAtSameMomentAs(today);
    }).length;
  }
  int get overdueWorkOrders => workOrders.where((wo) => wo.isOverdue).length;
  int get highPriorityWorkOrders =>
      workOrders.where((wo) => wo.isHighPriority).length;

  // PM task statistics - NOW USING REAL-TIME DATA!
  int get totalPMTasks => pmTasks.length;
  int get pendingPMTasks => pmTasks.where((task) => task.isPending).length;
  int get inProgressPMTasks => pmTasks.where((task) => task.isInProgress).length;
  int get completedPMTasks => pmTasks.where((task) => task.isCompleted).length;
  int get overduePMTasks => pmTasks.where((task) => task.isOverdue).length;
  
  // Due PM Tasks: tasks that are pending/overdue and due today or overdue
  int get duePMTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return pmTasks.where((task) {
      // Include tasks that are pending or overdue
      if (!task.isPending && !task.isOverdue) return false;
      // Include tasks that are due today or overdue
      if (task.nextDueDate == null) return false;
      final dueDate = DateTime(
        task.nextDueDate!.year,
        task.nextDueDate!.month,
        task.nextDueDate!.day,
      );
      return dueDate.isBefore(today) || dueDate.isAtSameMomentAs(today);
    }).length;
  }

  // User statistics - NOW USING REAL-TIME DATA!
  int get totalUsers => users.length;
  int get technicians =>
      users.where((user) => user.role == 'technician').length;
  int get managers => users.where((user) => user.role == 'manager').length;
  int get admins => users.where((user) => user.role == 'admin').length;
  int get requestors => users.where((user) => user.role == 'requestor').length;

  // Asset statistics - NOW USING REAL-TIME DATA!
  int get totalAssets => assets.length;

  // Inventory statistics - NOW USING REAL-TIME DATA!
  int get totalInventory => inventoryItems.length;
  int get lowStockItems =>
      inventoryItems.where((item) => item.quantity <= 10).length;

  // Workflow statistics - NOW USING REAL-TIME DATA!
  int get totalWorkflows => workflows.length;
  int get pendingApprovalWorkflows =>
      workflows.where((w) => w.isPendingApproval).length;
  int get approvedWorkflows => workflows.where((w) => w.isApproved).length;
  int get completedWorkflows => workflows.where((w) => w.isCompleted).length;
  int get overdueWorkflows => workflows.where((w) => w.isOverdue).length;

  /// Initialize all data and start real-time listeners
  Future<void> initialize() async {
    try {
      // Initialize local database first (for offline support)
      await _dataService.initialize();

      // Start listening to real-time Firestore streams
      _startRealtimeListeners();

      notifyListeners();
      debugPrint(
        '✅ UnifiedDataProvider: Initialized with real-time Firestore sync!',
      );
    } catch (e) {
      debugPrint('UnifiedDataProvider: Error initializing: $e');
    }
  }

  /// Start listening to real-time Firestore streams
  void _startRealtimeListeners() {
    debugPrint(
      '🔥 UnifiedDataProvider: Starting real-time Firestore listeners...',
    );

    // Work Orders Stream
    _workOrdersSubscription = _dataService.workOrdersStream.listen(
      (workOrders) {
        final missingUsers = <String>{};
        final missingAssets = <String>{};
        final deduped = _dedupeWorkOrders(workOrders);
        final populated = _populateWorkOrderReferences(
          deduped,
          missingUserIds: missingUsers,
          missingAssetIds: missingAssets,
        );
        
        // Merge with existing real-time work orders to preserve locally created ones
        // that might not be in Firestore yet
        final merged = <String, WorkOrder>{};
        for (final wo in _realtimeWorkOrders) {
          merged[wo.id] = wo;
        }
        for (final wo in populated) {
          // Keep the newer version if it exists
          final existing = merged[wo.id];
          if (existing == null ||
              wo.updatedAt.isAfter(existing.updatedAt) ||
              (wo.updatedAt == existing.updatedAt && wo.createdAt.isAfter(existing.createdAt))) {
            merged[wo.id] = wo;
          }
        }
        
        _realtimeWorkOrders = merged.values.toList();
        _dataService.syncRealtimeWorkOrders(_realtimeWorkOrders);
        if (!_isDisposed) {
          notifyListeners();
        }
        // Removed verbose real-time update logging

        if (missingUsers.isNotEmpty || missingAssets.isNotEmpty) {
          unawaited(
            _recoverMissingReferences(
              userIds: missingUsers,
              assetIds: missingAssets,
            ),
          );
        }
      },
      onError: (error) {
        debugPrint('❌ Work orders stream error: $error');
      },
    );

    // PM Tasks Stream
    _pmTasksSubscription = _dataService.pmTasksStream.listen(
      (pmTasks) {
        final missingUsers = <String>{};
        final missingAssets = <String>{};
        _realtimePMTasks = _populatePMTaskReferences(
          _dedupePMTasks(pmTasks),
          missingUserIds: missingUsers,
          missingAssetIds: missingAssets,
        );
        if (!_isDisposed) {
          notifyListeners();
        }
        // Removed verbose real-time update logging

        if (missingUsers.isNotEmpty || missingAssets.isNotEmpty) {
          unawaited(
            _recoverMissingReferences(
              userIds: missingUsers,
              assetIds: missingAssets,
            ),
          );
        }
      },
      onError: (error) {
        debugPrint('❌ PM tasks stream error: $error');
      },
    );

    // Assets Stream
    _assetsSubscription = _dataService.assetsStream.listen(
      (assets) {
        _realtimeAssets = assets;
        if (_realtimeWorkOrders.isNotEmpty) {
          _realtimeWorkOrders =
              _populateWorkOrderReferences(_realtimeWorkOrders);
        }
        if (_realtimePMTasks.isNotEmpty) {
          _realtimePMTasks = _populatePMTaskReferences(_realtimePMTasks);
        }
        if (!_isDisposed) {
          notifyListeners();
        }
        // Removed verbose real-time update logging
      },
      onError: (error) {
        debugPrint('❌ Assets stream error: $error');
        // Don't crash on stream errors, just log them
      },
    );

    // Users Stream
    _usersSubscription = _dataService.usersStream.listen(
      (users) {
        _realtimeUsers = _dedupeUsers(users);
        if (_realtimeWorkOrders.isNotEmpty) {
          _realtimeWorkOrders =
              _populateWorkOrderReferences(_realtimeWorkOrders);
        }
        if (_realtimePMTasks.isNotEmpty) {
          _realtimePMTasks = _populatePMTaskReferences(_realtimePMTasks);
        }
        if (!_isDisposed) {
          notifyListeners();
        }
        // Removed verbose real-time update logging
      },
      onError: (error) {
        debugPrint('❌ Users stream error: $error');
        // Don't crash on stream errors, just log them
      },
    );

    // Inventory Stream
    _inventorySubscription = _dataService.inventoryItemsStream.listen(
      (inventory) {
        _realtimeInventory = inventory;
        if (!_isDisposed) {
          notifyListeners();
        }
        // Removed verbose real-time update logging
      },
      onError: (error) {
        debugPrint('❌ Inventory stream error: $error');
        // Don't crash on stream errors, just log them
      },
    );

    // Workflows Stream
    _workflowsSubscription = _dataService.workflowsStream.listen(
      (workflows) {
        _realtimeWorkflows = workflows;
        if (!_isDisposed) {
          notifyListeners();
        }
        // Removed verbose real-time update logging
      },
      onError: (error) {
        // Suppress verbose permission denied errors - will be fixed after deploying Firestore rules
        if (!error.toString().contains('permission-denied')) {
          debugPrint('❌ Workflows stream error: $error');
        }
        // Don't crash on stream errors, just log them
      },
    );

    debugPrint('✅ UnifiedDataProvider: All real-time listeners started!');
  }

  /// Dispose all stream subscriptions
  @override
  void dispose() {
    _isDisposed = true;
    _workOrdersSubscription?.cancel();
    _pmTasksSubscription?.cancel();
    _assetsSubscription?.cancel();
    _usersSubscription?.cancel();
    _inventorySubscription?.cancel();
    _workflowsSubscription?.cancel();
    debugPrint('🔥 UnifiedDataProvider: All real-time listeners disposed');
    super.dispose();
  }

  /// Safe notifyListeners that checks if disposed
  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    try {
      await _dataService.refreshAll();
      notifyListeners();
    } catch (e) {
      debugPrint('UnifiedDataProvider: Error refreshing: $e');
    }
  }

  /// Refresh a specific work order (optimized - doesn't reload all data)
  Future<void> refreshWorkOrder(String workOrderId) async {
    try {
      // The real-time listener will automatically update the work order
      // Just wait a moment for the listener to pick up the change
      await Future.delayed(const Duration(milliseconds: 300));
      notifyListeners();
    } catch (e) {
      debugPrint('UnifiedDataProvider: Error refreshing work order: $e');
    }
  }

  /// Get work orders by technician - NOW USING REAL-TIME DATA!
  List<WorkOrder> getWorkOrdersByTechnician(String technicianId) {
    debugPrint('🔍 Getting work orders for technician: $technicianId');
    debugPrint('📊 Total work orders in system: ${workOrders.length}');

    final filtered =
        workOrders.where((wo) => wo.hasTechnician(technicianId)).toList();

    debugPrint(
      '✅ Found ${filtered.length} work orders for technician $technicianId',
    );

    // Debug: Show first few assigned IDs to help diagnose
    if (filtered.isEmpty && workOrders.isNotEmpty) {
      debugPrint('⚠️ No matches found. Sample assignedTechnicianIds:');
      for (final wo in workOrders.take(5)) {
        debugPrint(
          '  - WorkOrder ${wo.id}: assignedTechnicianIds = ${wo.assignedTechnicianIds.join(",")}',
        );
      }
    }

    return filtered;
  }

  /// Get PM tasks by technician - NOW USING REAL-TIME DATA!
  List<PMTask> getPMTasksByTechnician(String technicianId) {
    debugPrint('🔍 Getting PM tasks for technician: $technicianId');
    debugPrint('📊 Total PM tasks in system: ${pmTasks.length}');

    final filtered =
        pmTasks.where((task) => task.hasTechnician(technicianId)).toList();

    debugPrint(
      '✅ Found ${filtered.length} PM tasks for technician $technicianId',
    );

    // Debug: Show first few assigned IDs to help diagnose
    if (filtered.isEmpty && pmTasks.isNotEmpty) {
      debugPrint('⚠️ No matches found. Sample assignedTechnicianIds:');
      for (final task in pmTasks.take(5)) {
        debugPrint(
          '  - PMTask ${task.id}: assignedTechnicianIds = ${task.assignedTechnicianIds.join(",")}',
        );
      }
    }

    return filtered;
  }

  /// Get technicians only - NOW USING REAL-TIME DATA!
  List<User> getTechnicians() {
    debugPrint('🔍 Getting technicians...');
    debugPrint('📊 Total users in system: ${users.length}');

    // Debug: Show all user roles
    if (users.isNotEmpty) {
      debugPrint('👥 User roles in system:');
      final roleGroups = <String, int>{};
      for (final user in users) {
        final role = user.role.toLowerCase();
        roleGroups[role] = (roleGroups[role] ?? 0) + 1;
      }
      roleGroups.forEach((role, count) {
        debugPrint('  - $role: $count users');
      });
    }

    // Filter technicians (case-insensitive)
    final technicians =
        users.where((user) => user.role.toLowerCase() == 'technician').toList();

    debugPrint('✅ Found ${technicians.length} technicians');

    if (technicians.isEmpty && users.isNotEmpty) {
      debugPrint('⚠️ No technicians found! Sample user roles:');
      users.take(5).forEach((user) {
        debugPrint('  - User ${user.name}: role = "${user.role}"');
      });
    }

    return technicians;
  }

  /// Convenience filter for managers
  List<User> getManagers() =>
      users.where((user) => user.role.toLowerCase() == 'manager').toList();

  /// Convenience filter for admins
  List<User> getAdmins() =>
      users.where((user) => user.role.toLowerCase() == 'admin').toList();

  /// Filter work orders by status (supports enum or string)
  List<WorkOrder> getWorkOrdersByStatus(dynamic status) {
    final target = status is WorkOrderStatus
        ? status.name
        : status is String
            ? status.toLowerCase()
            : null;
    if (target == null) return const <WorkOrder>[];

    return workOrders
        .where((wo) => wo.status.name.toLowerCase() == target)
        .toList();
  }

  /// Filter work orders by priority (supports enum or string)
  List<WorkOrder> getWorkOrdersByPriority(dynamic priority) {
    final target = priority is WorkOrderPriority
        ? priority.name
        : priority is String
            ? priority.toLowerCase()
            : null;
    if (target == null) return const <WorkOrder>[];

    return workOrders
        .where((wo) => wo.priority.name.toLowerCase() == target)
        .toList();
  }

  /// Filter work orders by requestor id
  List<WorkOrder> getWorkOrdersByRequestor(String requestorId) =>
      workOrders.where((wo) => wo.requestorId == requestorId).toList();

  /// Return only overdue work orders
  List<WorkOrder> getOverdueWorkOrders() =>
      workOrders.where((wo) => wo.isOverdue).toList();

  /// Return only overdue PM tasks
  List<PMTask> getOverduePMTasks() => pmTasks
      .where(
        (task) => task.status == PMTaskStatus.overdue || (task.isOverdue),
      )
      .toList();

  /// Filter PM tasks by status
  List<PMTask> getPMTasksByStatus(PMTaskStatus status) =>
      pmTasks.where((task) => task.status == status).toList();

  /// Inventory helpers
  List<InventoryItem> getLowStockItems({double? threshold}) => inventoryItems.where((item) {
      final minThreshold = threshold ?? item.minimumStock ?? 0;
      return item.quantity < minThreshold;
    }).toList();

  List<InventoryItem> getInventoryByCategory(String category) {
    final target = category.toLowerCase();
    return inventoryItems
        .where((item) => item.category.toLowerCase() == target)
        .toList();
  }

  /// Aggregate performance data for a technician
  Map<String, dynamic> getTechnicianPerformance(String technicianId) {
    final technicianWorkOrders = getWorkOrdersByTechnician(technicianId);
    final technicianPMTasks = getPMTasksByTechnician(technicianId);

    final workOrderStats = {
      'total': technicianWorkOrders.length,
      'completed': technicianWorkOrders.where((wo) => wo.isCompleted).length,
      'inProgress': technicianWorkOrders.where((wo) => wo.isInProgress).length,
      'overdue': technicianWorkOrders.where((wo) => wo.isOverdue).length,
    };

    final pmTaskStats = {
      'total': technicianPMTasks.length,
      'completed': technicianPMTasks.where((task) => task.isCompleted).length,
      'inProgress': technicianPMTasks.where((task) => task.isInProgress).length,
      'overdue': technicianPMTasks.where((task) => task.isOverdue).length,
    };

    return {
      'workOrders': technicianWorkOrders,
      'pmTasks': technicianPMTasks,
      'workOrderStats': workOrderStats,
      'pmTaskStats': pmTaskStats,
    };
  }

  /// Create work order
  Future<String> createWorkOrder({
    required String problemDescription,
    required String requestorId,
    String? assetId, // Made optional for general facility maintenance
    Asset? asset, // Pass full asset object if available
    String? location, // Location for general maintenance without asset
    String? photoPath,
    WorkOrderPriority priority = WorkOrderPriority.medium,
    RepairCategory? category,
    List<String>? assignedTechnicianIds,
    String? requestorName,
    // Additional requestor details
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? notes,
  }) async {
    try {
      const uuid = Uuid();
      final now = DateTime.now();
      final workOrderId = uuid.v4();

      // Generate ticket number
      final ticketNumber =
          'WO-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${totalWorkOrders + 1}';

      // Upload photo to Firebase Storage if provided
      String? uploadedPhotoUrl;
      if (photoPath != null) {
        try {
          // Convert file path to XFile (web-compatible)
          final photoFile = XFile(photoPath);
          final storageService = SupabaseStorageService();
          uploadedPhotoUrl = await storageService.uploadWorkOrderPhoto(
            photoFile: photoFile,
            workOrderId: workOrderId,
          );
          debugPrint('📤 Uploaded work order photo: $uploadedPhotoUrl');
        } catch (e) {
          debugPrint('⚠️ Failed to upload photo to Supabase Storage: $e');
          // Continue with local path if upload fails
          uploadedPhotoUrl = photoPath;
        }
      }

      // Get the asset to populate the reference (if assetId is provided)
      // Use passed asset if available, otherwise look it up
      if (asset == null && assetId != null) {
        asset = assets.firstWhere(
          (a) => a.id == assetId,
          orElse: () => Asset(
            id: assetId,
            name: 'Unknown Asset',
            location: '',
            status: 'unknown',
            category: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      // Get the requestor to check their role and company
      final requestor = users.firstWhere(
        (u) => u.id == requestorId,
        orElse: () => User(
          id: requestorId,
          email: '',
          name: 'Unknown User',
          role: 'requestor',
          createdAt: DateTime.now(),
        ),
      );

      // Get companyId from requestor (required for multi-tenant isolation)
      final companyId = requestor.companyId;
      if (companyId == null && requestor.role == 'requestor') {
        debugPrint('⚠️ Requestor ${requestor.id} has no companyId assigned');
      }

      final requestorRole = requestor.role.toLowerCase();
      final assignedIds = <String>[];
      List<User>? assignedTechnicians;

      // Workflow: Requestors can only create OPEN work orders (unassigned)
      // Only admins, managers, or technicians can assign technicians during creation
      if (requestorRole == 'requestor') {
        // Requestors cannot assign technicians - work order stays OPEN
        // Ignore any assignedTechnicianIds passed (shouldn't happen, but safety check)
        debugPrint('📋 Requestor creating work order - will remain OPEN (unassigned)');
      } else if (requestorRole == 'admin' || requestorRole == 'manager') {
        // Admins and managers can assign technicians during creation
        void addTechnician(String? id) {
          if (id != null && id.isNotEmpty && !assignedIds.contains(id)) {
            assignedIds.add(id);
          }
        }
        if (assignedTechnicianIds != null) {
          for (final techId in assignedTechnicianIds) {
            addTechnician(techId);
          }
        }
        if (assignedIds.isNotEmpty) {
          assignedTechnicians = users
              .where((user) => assignedIds.contains(user.id))
              .toList();
        }
        debugPrint('👔 Admin/Manager creating work order - can assign technicians');
      } else if (requestorRole == 'technician') {
        // Technicians can auto-assign themselves when creating work orders
        void addTechnician(String? id) {
          if (id != null && id.isNotEmpty && !assignedIds.contains(id)) {
            assignedIds.add(id);
          }
        }
        if (assignedTechnicianIds != null) {
          for (final techId in assignedTechnicianIds) {
            addTechnician(techId);
          }
        }
        // Auto-assign technician to themselves
        addTechnician(requestorId);
        if (assignedIds.isNotEmpty) {
          assignedTechnicians = users
              .where((user) => assignedIds.contains(user.id))
              .toList();
        }
        debugPrint('🔧 Technician creating work order - auto-assigned to self');
      }

      final workOrder = WorkOrder(
        id: workOrderId,
        ticketNumber: ticketNumber,
        assetId: assetId,
        asset: asset, // Populate asset reference
        location: location, // For general maintenance
        companyId: companyId, // Set companyId from requestor
        problemDescription: problemDescription,
        photoPath: uploadedPhotoUrl ?? photoPath,
        requestorId: requestorId,
        requestor: requestor,
        requestorName: requestorName ?? customerName,
        primaryTechnicianId: assignedIds.isNotEmpty ? assignedIds.first : null,
        assignedTechnicianIds: assignedIds,
        assignedTechnicians: assignedTechnicians,
        assignedAt: assignedIds.isNotEmpty ? now : null,
        status: assignedIds.isNotEmpty
            ? WorkOrderStatus.assigned
            : WorkOrderStatus.open,
        priority: priority,
        category: category,
        notes: notes, // Store additional notes/details
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        createdAt: now,
        isOffline: uploadedPhotoUrl == null && photoPath != null,
        updatedAt: now,
      );

      final id = await _dataService.createWorkOrder(workOrder);
      
      // Get the created work order from the service and add to real-time cache
      final createdWorkOrder = _dataService.workOrders.firstWhere(
        (wo) => wo.id == id,
        orElse: () => workOrder,
      );
      
      // Populate references for the created work order
      final populatedWorkOrder = _populateWorkOrderReferences([createdWorkOrder]).first;
      
      // Add to real-time cache if not already present
      final existingIndex = _realtimeWorkOrders.indexWhere((wo) => wo.id == id);
      if (existingIndex != -1) {
        _realtimeWorkOrders[existingIndex] = populatedWorkOrder;
      } else {
        _realtimeWorkOrders.add(populatedWorkOrder);
      }
      
      notifyListeners();

      if (requestorRole == 'requestor') {
        debugPrint('✅ Work order created by requestor - Status: OPEN (awaiting assignment by admin/manager)');
      } else {
        debugPrint(
          assignedIds.isNotEmpty
              ? '✅ Work order assigned to ${assignedIds.length} technician(s)'
              : '✅ Work order created as unassigned',
        );
      }

      return id;
    } catch (e) {
      debugPrint('UnifiedDataProvider: Error creating work order: $e');
      rethrow;
    }
  }

  /// Update work order
  Future<WorkOrder> updateWorkOrder(WorkOrder workOrder) async {
    try {
      final updatedWorkOrder = await _dataService.updateWorkOrder(workOrder);
      // Update the real-time cache
      final index = _realtimeWorkOrders.indexWhere(
        (wo) => wo.id == updatedWorkOrder.id,
      );
      if (index != -1) {
        _realtimeWorkOrders[index] = updatedWorkOrder;
      } else {
        _realtimeWorkOrders.add(updatedWorkOrder);
      }
      notifyListeners();
      return updatedWorkOrder;
    } catch (e) {
      debugPrint('UnifiedDataProvider: Error updating work order: $e');
      rethrow;
    }
  }

  /// Delete work order
  Future<void> deleteWorkOrder(String workOrderId) async {
    try {
      await _dataService.deleteWorkOrder(workOrderId);
      notifyListeners();
    } catch (e) {
      debugPrint('UnifiedDataProvider: Error deleting work order: $e');
      rethrow;
    }
  }

  /// Create user
  Future<String> createUser(User user) async {
    try {
      final id = await _dataService.createUser(user);
      notifyListeners();
      return id;
    } catch (e) {
      debugPrint('UnifiedDataProvider: Error creating user: $e');
      rethrow;
    }
  }

  /// Update user
  Future<void> updateUser(User user) async {
    try {
      await _dataService.updateUser(user);
      notifyListeners();
    } catch (e) {
      debugPrint('UnifiedDataProvider: Error updating user: $e');
      rethrow;
    }
  }

  /// Delete user
  /// [currentUserRole] - Role of the user performing the deletion (for validation)
  /// [currentUserId] - ID of the user performing the deletion (for validation)
  Future<void> deleteUser(
    String userId, {
    String? currentUserRole,
    String? currentUserId,
  }) async {
    try {
      // Validate: Can't delete yourself
      if (currentUserId != null && currentUserId == userId) {
        throw Exception('You cannot delete your own account');
      }

      // Get user to check role - check both real-time cache and data service
      User user;
      try {
        user = users.firstWhere((u) => u.id == userId);
      } catch (e) {
        // If not in cache, try fetching from Firestore directly
        final fetchedUser = await SupabaseDatabaseService.instance.getUserById(userId);
        if (fetchedUser == null) {
          throw Exception('User not found');
        }
        user = fetchedUser;
      }

      // Validate: Can't delete admins or managers (unless you're an admin)
      if ((user.role == 'admin' || user.role == 'manager') &&
          currentUserRole != 'admin') {
        throw Exception(
          'Only administrators can delete ${user.role}s',
        );
      }

      await _dataService.deleteUser(userId);
      
      // Remove from real-time cache if exists
      _realtimeUsers.removeWhere((u) => u.id == userId);
      
      notifyListeners();
    } catch (e) {
      debugPrint('UnifiedDataProvider: Error deleting user: $e');
      rethrow;
    }
  }

  /// Assign technician to work order
  Future<void> assignTechnicianToWorkOrder(
    String workOrderId,
    String technicianId,
  ) async {
    try {
      await _dataService.assignTechnicianToWorkOrder(workOrderId, technicianId);
      notifyListeners();
    } catch (e) {
      debugPrint('UnifiedDataProvider: Error assigning technician: $e');
      rethrow;
    }
  }

  Future<void> updateWorkOrderTechnicians(
    String workOrderId,
    List<String> technicianIds,
  ) async {
    try {
      await _dataService.updateWorkOrderTechnicianAssignments(
        workOrderId,
        technicianIds,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('UnifiedDataProvider: Error updating technicians: $e');
      rethrow;
    }
  }

  /// Unassign technician from work order
  Future<void> unassignTechnicianFromWorkOrder(
    String workOrderId, {
    String? technicianId,
  }) async {
    try {
      await _dataService.unassignTechnicianFromWorkOrder(
        workOrderId,
        technicianId: technicianId,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('UnifiedDataProvider: Error unassigning technician: $e');
      rethrow;
    }
  }

  /// Create PM task
  Future<void> createPMTask({
    required String taskName,
    String assetId = '', // Optional - can be empty for general PM tasks
    required String description,
    required String checklistJson,
    required PMTaskFrequency frequency,
    required DateTime nextDue,
    Asset? asset, // Pass full asset object if available
    List<String>? assignedTechnicianIds,
    String? createdById, // Track who created this PM task
  }) async {
    try {
      final finalAssignedIds = <String>[];
      if (assignedTechnicianIds != null) {
        finalAssignedIds
            .addAll(assignedTechnicianIds.where((id) => id.isNotEmpty));
      }

      debugPrint(
        '🔍 Creating PM task - assignedTechnicianIds: $assignedTechnicianIds, createdById: $createdById',
      );
      debugPrint('🔍 Available users: ${users.length}');
      for (final user in users) {
        debugPrint(
          '   - User: ${user.name} (${user.email}), ID: ${user.id}, Role: ${user.role}',
        );
      }

      if (finalAssignedIds.isEmpty && createdById != null) {
        final creator = users.firstWhere(
          (u) => u.id == createdById,
          orElse: () => User(
            id: createdById,
            email: '',
            name: 'Unknown User',
            role: 'requestor',
            createdAt: DateTime.now(),
          ),
        );

        debugPrint(
          '🔍 Creator found: ${creator.name}, role: ${creator.role}, ID: ${creator.id}',
        );

        // Auto-assign to creator if they're a technician
        if (creator.role == 'technician') {
          finalAssignedIds.add(createdById);
          debugPrint(
            '✅ Auto-assigning PM task to creator: ${creator.name} (ID: $createdById)',
          );
        }
      }

      debugPrint('🔍 Final assigned technician IDs: $finalAssignedIds');

      await _dataService.createPMTask(
        taskName: taskName,
        assetId: assetId,
        asset: asset, // Pass full asset object
        description: description,
        checklistJson: checklistJson,
        frequency: frequency,
        nextDue: nextDue,
        assignedTechnicianIds: finalAssignedIds,
        createdById: createdById, // Pass creator ID to service
      );
      notifyListeners();

      debugPrint('✅ PM task created and listeners notified');
    } catch (e) {
      debugPrint('UnifiedDataProvider: Error creating PM task: $e');
      rethrow;
    }
  }

  /// Update PM task
  Future<PMTask> updatePMTask(PMTask pmTask) async {
    try {
      final updatedPMTask = await _dataService.updatePMTask(pmTask);
      // Update the real-time cache
      final index = _realtimePMTasks.indexWhere(
        (pm) => pm.id == updatedPMTask.id,
      );
      if (index != -1) {
        _realtimePMTasks[index] = updatedPMTask;
      } else {
        _realtimePMTasks.add(updatedPMTask);
      }
      notifyListeners();
      return updatedPMTask;
    } catch (e) {
      debugPrint('UnifiedDataProvider: Error updating PM task: $e');
      rethrow;
    }
  }

  /// Delete PM task
  Future<void> deletePMTask(String pmTaskId) async {
    try {
      await _dataService.deletePMTask(pmTaskId);
      notifyListeners();
    } catch (e) {
      debugPrint('UnifiedDataProvider: Error deleting PM task: $e');
      rethrow;
    }
  }

  /// Assign technician to PM task
  Future<void> assignPMTaskTechnician(
    String pmTaskId,
    String technicianId,
  ) async {
    try {
      await _dataService.assignTechnicianToPMTask(pmTaskId, technicianId);
      notifyListeners();
    } catch (e) {
      debugPrint(
        'UnifiedDataProvider: Error assigning technician to PM task: $e',
      );
      rethrow;
    }
  }

  Future<void> updatePMTaskTechnicians(
    String pmTaskId,
    List<String> technicianIds,
  ) async {
    try {
      await _dataService.updatePMTaskTechnicianAssignments(
        pmTaskId,
        technicianIds,
      );
      notifyListeners();
    } catch (e) {
      debugPrint(
        'UnifiedDataProvider: Error updating PM task technicians: $e',
      );
      rethrow;
    }
  }

  /// Unassign technician from PM task
  Future<void> unassignPMTaskTechnician(
    String pmTaskId, {
    String? technicianId,
  }) async {
    try {
      await _dataService.unassignTechnicianFromPMTask(
        pmTaskId,
        technicianId: technicianId,
      );
      notifyListeners();
    } catch (e) {
      debugPrint(
        'UnifiedDataProvider: Error unassigning technician from PM task: $e',
      );
      rethrow;
    }
  }

  /// Alias methods for work order technician assignment (shorter names)
  Future<void> assignTechnician(String workOrderId, String technicianId) =>
      assignTechnicianToWorkOrder(workOrderId, technicianId);

  Future<void> unassignTechnician(
    String workOrderId, {
    String? technicianId,
  }) =>
      unassignTechnicianFromWorkOrder(workOrderId, technicianId: technicianId);

  /// Get dashboard statistics - NOW USING REAL-TIME DATA!
  Map<String, dynamic> getDashboardStats() => {
        'totalWorkOrders': workOrders.length,
        'openWorkOrders': workOrders.where((wo) => wo.isOpen).length,
        'inProgressWorkOrders':
            workOrders.where((wo) => wo.isInProgress).length,
        'completedWorkOrders': workOrders.where((wo) => wo.isCompleted).length,
        'overdueWorkOrders': workOrders.where((wo) => wo.isOverdue).length,
        'highPriorityWorkOrders':
            workOrders.where((wo) => wo.isHighPriority).length,
        'totalPMTasks': pmTasks.length,
        'pendingPMTasks': pendingPMTasks,
        'duePMTasks': duePMTasks,
        'overduePMTasks': overduePMTasks,
        'completedPMTasks': completedPMTasks,
        'completedWorkOrdersToday': completedWorkOrdersToday,
        'totalUsers': users.length,
        'technicians': users.where((user) => user.role == 'technician').length,
        'totalAssets': assets.length,
        'totalInventory': inventoryItems.length,
        'lowStockItems':
            inventoryItems.where((item) => item.quantity <= 10).length,
        'totalWorkflows': workflows.length,
        'pendingApprovalWorkflows':
            workflows.where((w) => w.isPendingApproval).length,
        'approvedWorkflows': workflows.where((w) => w.isApproved).length,
        'completedWorkflows': workflows.where((w) => w.isCompleted).length,
        'overdueWorkflows': workflows.where((w) => w.isOverdue).length,
      };

  /// Get technician-specific dashboard data - NOW USING REAL-TIME DATA!
  Map<String, dynamic> getTechnicianDashboardData(String technicianId) {
    final technicianWorkOrders = getWorkOrdersByTechnician(technicianId);
    final technicianPMTasks = getPMTasksByTechnician(technicianId);

    return {
      'workOrders': technicianWorkOrders,
      'pmTasks': technicianPMTasks,
      'workOrderStats': {
        'total': technicianWorkOrders.length,
        'open': technicianWorkOrders.where((wo) => wo.isOpen).length,
        'inProgress':
            technicianWorkOrders.where((wo) => wo.isInProgress).length,
        'completed': technicianWorkOrders.where((wo) => wo.isCompleted).length,
        'overdue': technicianWorkOrders.where((wo) => wo.isOverdue).length,
      },
      'pmTaskStats': {
        'total': technicianPMTasks.length,
        'pending': technicianPMTasks
            .where((task) => task.status.toString().contains('pending'))
            .length,
        'inProgress': technicianPMTasks
            .where((task) => task.status.toString().contains('inProgress'))
            .length,
        'completed': technicianPMTasks
            .where((task) => task.status.toString().contains('completed'))
            .length,
      },
    };
  }

  /// Get work order by ID - NOW USING REAL-TIME DATA!
  WorkOrder? getWorkOrderById(String id) {
    try {
      return workOrders.firstWhere((wo) => wo.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get user by ID - NOW USING REAL-TIME DATA!
  User? getUserById(String id) {
    try {
      return users.firstWhere((user) => user.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get user by email - NOW USING REAL-TIME DATA!
  User? getUserByEmail(String email) {
    try {
      return users.firstWhere((user) => user.email == email);
    } catch (e) {
      return null;
    }
  }

  /// Pause a work order with reason
  Future<WorkOrder> pauseWorkOrder(String workOrderId, String reason) async {
    try {
      final updatedWorkOrder = await _dataService.pauseWorkOrder(workOrderId, reason);
      // Update real-time cache if it exists there
      final realtimeIndex = _realtimeWorkOrders.indexWhere(
        (wo) => wo.id == workOrderId,
      );
      if (realtimeIndex != -1) {
        _realtimeWorkOrders[realtimeIndex] = updatedWorkOrder;
      }
      notifyListeners();
      return updatedWorkOrder;
    } catch (e) {
      debugPrint('UnifiedDataProvider: Error pausing work order: $e');
      rethrow;
    }
  }

  /// Resume a paused work order
  Future<WorkOrder> resumeWorkOrder(String workOrderId) async {
    try {
      final updatedWorkOrder = await _dataService.resumeWorkOrder(workOrderId);
      // Update real-time cache if it exists there
      final realtimeIndex = _realtimeWorkOrders.indexWhere(
        (wo) => wo.id == workOrderId,
      );
      if (realtimeIndex != -1) {
        _realtimeWorkOrders[realtimeIndex] = updatedWorkOrder;
      }
      notifyListeners();
      return updatedWorkOrder;
    } catch (e) {
      debugPrint('UnifiedDataProvider: Error resuming work order: $e');
      rethrow;
    }
  }

  /// Pause a PM task with reason
  Future<PMTask> pausePMTask(String pmTaskId, String reason) async {
    try {
      final updatedPMTask = await _dataService.pausePMTask(pmTaskId, reason);
      // Update real-time cache if it exists there
      final realtimeIndex = _realtimePMTasks.indexWhere(
        (pm) => pm.id == pmTaskId,
      );
      if (realtimeIndex != -1) {
        _realtimePMTasks[realtimeIndex] = updatedPMTask;
      }
      notifyListeners();
      return updatedPMTask;
    } catch (e) {
      debugPrint('UnifiedDataProvider: Error pausing PM task: $e');
      rethrow;
    }
  }

  /// Resume a paused PM task
  Future<PMTask> resumePMTask(String pmTaskId) async {
    try {
      final updatedPMTask = await _dataService.resumePMTask(pmTaskId);
      // Update real-time cache if it exists there
      final realtimeIndex = _realtimePMTasks.indexWhere(
        (pm) => pm.id == pmTaskId,
      );
      if (realtimeIndex != -1) {
        _realtimePMTasks[realtimeIndex] = updatedPMTask;
      }
      notifyListeners();
      return updatedPMTask;
    } catch (e) {
      debugPrint('UnifiedDataProvider: Error resuming PM task: $e');
      rethrow;
    }
  }

  // ============================================================================
  // WORKFLOW OPERATIONS
  // ============================================================================

  /// Create workflow
  Future<String> createWorkflow(Workflow workflow) async {
    try {
      final workflowId = await _dataService.createWorkflow(workflow);
      notifyListeners();
      return workflowId;
    } catch (e) {
      debugPrint('UnifiedDataProvider: Error creating workflow: $e');
      rethrow;
    }
  }

  /// Update workflow
  Future<void> updateWorkflow(Workflow workflow) async {
    try {
      await _dataService.updateWorkflow(workflow);
      notifyListeners();
    } catch (e) {
      debugPrint('UnifiedDataProvider: Error updating workflow: $e');
      rethrow;
    }
  }

  /// Delete workflow
  Future<void> deleteWorkflow(String workflowId) async {
    try {
      await _dataService.deleteWorkflow(workflowId);
      notifyListeners();
    } catch (e) {
      debugPrint('UnifiedDataProvider: Error deleting workflow: $e');
      rethrow;
    }
  }

  /// Get workflow by ID
  Workflow? getWorkflowById(String workflowId) =>
      _dataService.getWorkflowById(workflowId);

  /// Get workflows by status
  List<Workflow> getWorkflowsByStatus(WorkflowStatus status) =>
      _dataService.getWorkflowsByStatus(status);

  /// Get workflows by type
  List<Workflow> getWorkflowsByType(WorkflowType type) =>
      _dataService.getWorkflowsByType(type);

  /// Get workflows created by user
  List<Workflow> getWorkflowsByCreator(String userId) =>
      _dataService.getWorkflowsByCreator(userId);

  /// Get workflows assigned to user
  List<Workflow> getWorkflowsByAssignee(String userId) =>
      _dataService.getWorkflowsByAssignee(userId);

  /// Get pending approvals for user
  List<Workflow> getPendingApprovalsForUser(String userId) =>
      _dataService.getPendingApprovalsForUser(userId);

  /// Get overdue workflows
  List<Workflow> getOverdueWorkflows() => _dataService.getOverdueWorkflows();

  /// Approve workflow
  Future<void> approveWorkflow({
    required String workflowId,
    required String approverId,
    required String approverName,
    required String approverRole,
    String? comments,
  }) async {
    try {
      await _dataService.approveWorkflow(
        workflowId: workflowId,
        approverId: approverId,
        approverName: approverName,
        approverRole: approverRole,
        comments: comments,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('UnifiedDataProvider: Error approving workflow: $e');
      rethrow;
    }
  }

  /// Reject workflow
  Future<void> rejectWorkflow({
    required String workflowId,
    required String rejectorId,
    required String rejectorName,
    required String rejectorRole,
    required String reason,
  }) async {
    try {
      await _dataService.rejectWorkflow(
        workflowId: workflowId,
        rejectorId: rejectorId,
        rejectorName: rejectorName,
        rejectorRole: rejectorRole,
        reason: reason,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('UnifiedDataProvider: Error rejecting workflow: $e');
      rethrow;
    }
  }

  /// Complete workflow
  Future<void> completeWorkflow({
    required String workflowId,
    required String completedBy,
    String? comments,
  }) async {
    try {
      await _dataService.completeWorkflow(
        workflowId: workflowId,
        completedBy: completedBy,
        comments: comments,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('UnifiedDataProvider: Error completing workflow: $e');
      rethrow;
    }
  }

  /// Cancel workflow
  Future<void> cancelWorkflow({
    required String workflowId,
    required String cancelledBy,
    required String reason,
  }) async {
    try {
      await _dataService.cancelWorkflow(
        workflowId: workflowId,
        cancelledBy: cancelledBy,
        reason: reason,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('UnifiedDataProvider: Error cancelling workflow: $e');
      rethrow;
    }
  }

  /// Escalate workflow
  Future<void> escalateWorkflow({
    required String workflowId,
    required String escalatedBy,
    String? reason,
  }) async {
    try {
      await _dataService.escalateWorkflow(
        workflowId: workflowId,
        escalatedBy: escalatedBy,
        reason: reason,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('UnifiedDataProvider: Error escalating workflow: $e');
      rethrow;
    }
  }

  /// Refresh workflows
  Future<void> refreshWorkflows() async {
    try {
      await _dataService.refreshWorkflows();
      notifyListeners();
    } catch (e) {
      debugPrint('UnifiedDataProvider: Error refreshing workflows: $e');
    }
  }

  // ============================================================================
  // REFERENCE POPULATION FOR REAL-TIME DATA
  // ============================================================================

  /// Populate user and asset references in work orders from real-time data
  List<WorkOrder> _populateWorkOrderReferences(
    List<WorkOrder> workOrders, {
    Set<String>? missingUserIds,
    Set<String>? missingAssetIds,
  }) {
    final populatedWorkOrders = <WorkOrder>[];

    for (final workOrder in workOrders) {
      var updatedWorkOrder = workOrder;

      // Populate asset reference
      if (updatedWorkOrder.asset == null &&
          (updatedWorkOrder.assetId?.isNotEmpty ?? false)) {
        try {
          final asset = _realtimeAssets.firstWhere(
            (a) => a.id == updatedWorkOrder.assetId,
          );
          updatedWorkOrder = updatedWorkOrder.copyWith(asset: asset);
        } catch (e) {
          // Asset not found - leave as null
          debugPrint('⚠️ Asset ${updatedWorkOrder.assetId} not found');
          final assetId = updatedWorkOrder.assetId;
          if (assetId != null && assetId.isNotEmpty) {
            missingAssetIds?.add(assetId);
          }
        }
      }

      // Populate assigned technician references
      if (updatedWorkOrder.assignedTechnicianIds.isNotEmpty) {
        final technicians = <User>[];
        for (final techId in updatedWorkOrder.assignedTechnicianIds) {
          try {
            final technician = _realtimeUsers.firstWhere(
              (u) => u.id == techId,
            );
            technicians.add(technician);
          } catch (e) {
            debugPrint('⚠️ Technician $techId not found for WO ${updatedWorkOrder.id}');
            missingUserIds?.add(techId);
          }
        }
        if (technicians.isNotEmpty) {
          updatedWorkOrder =
              updatedWorkOrder.copyWith(assignedTechnicians: technicians);
        }
      }

      // Populate requestor reference
      if (updatedWorkOrder.requestor == null &&
          updatedWorkOrder.requestorId.isNotEmpty) {
        try {
          final requestor = _realtimeUsers.firstWhere(
            (u) => u.id == updatedWorkOrder.requestorId,
          );
          updatedWorkOrder = updatedWorkOrder.copyWith(requestor: requestor);
        } catch (e) {
          // User not found - leave as null
          debugPrint('⚠️ Requestor ${updatedWorkOrder.requestorId} not found');
          if (updatedWorkOrder.requestorId.isNotEmpty) {
            missingUserIds?.add(updatedWorkOrder.requestorId);
          }
        }
      }

      populatedWorkOrders.add(updatedWorkOrder);
    }

    return populatedWorkOrders;
  }

  /// Populate user and asset references in PM tasks from real-time data
  List<PMTask> _populatePMTaskReferences(
    List<PMTask> pmTasks, {
    Set<String>? missingUserIds,
    Set<String>? missingAssetIds,
  }) {
    final populatedPMTasks = <PMTask>[];

    for (final pmTask in pmTasks) {
      var updatedPMTask = pmTask;

      // Populate asset reference
      if (updatedPMTask.asset == null && updatedPMTask.assetId.isNotEmpty) {
        try {
          final asset = _realtimeAssets.firstWhere(
            (a) => a.id == updatedPMTask.assetId,
          );
          updatedPMTask = updatedPMTask.copyWith(asset: asset);
        } catch (e) {
          // Asset not found - leave as null
          debugPrint('⚠️ Asset ${updatedPMTask.assetId} not found');
          if (updatedPMTask.assetId.isNotEmpty) {
            missingAssetIds?.add(updatedPMTask.assetId);
          }
        }
      }

      // Populate creator reference
      if (updatedPMTask.createdBy == null && updatedPMTask.createdById != null && updatedPMTask.createdById!.isNotEmpty) {
        try {
          final creator = _realtimeUsers.firstWhere(
            (u) => u.id == updatedPMTask.createdById,
          );
          updatedPMTask = updatedPMTask.copyWith(createdBy: creator);
        } catch (e) {
          // Creator not found - leave as null
          debugPrint('⚠️ Creator ${updatedPMTask.createdById} not found');
        }
      }

      // Populate assigned technician references
      if (updatedPMTask.assignedTechnicianIds.isNotEmpty) {
        final technicians = <User>[];
        for (final techId in updatedPMTask.assignedTechnicianIds) {
          try {
            final technician = _realtimeUsers.firstWhere(
              (u) => u.id == techId,
            );
            technicians.add(technician);
          } catch (e) {
            debugPrint('⚠️ Technician $techId not found for PM ${updatedPMTask.id}');
            missingUserIds?.add(techId);
          }
        }
        if (technicians.isNotEmpty) {
          updatedPMTask =
              updatedPMTask.copyWith(assignedTechnicians: technicians);
        }
      }

      populatedPMTasks.add(updatedPMTask);
    }

    return populatedPMTasks;
  }

  Future<void> _recoverMissingReferences({
    Set<String>? userIds,
    Set<String>? assetIds,
  }) async {
    final futures = <Future<void>>[];
    if (userIds != null && userIds.isNotEmpty) {
      futures.add(_dataService.ensureUsersLoaded(userIds));
    }
    if (assetIds != null && assetIds.isNotEmpty) {
      futures.add(_dataService.ensureAssetsLoaded(assetIds));
    }
    if (futures.isEmpty) return;

    try {
      await Future.wait(futures);
      if (_realtimeWorkOrders.isNotEmpty) {
        _realtimeWorkOrders = _populateWorkOrderReferences(
          _realtimeWorkOrders,
        );
      }
      if (_realtimePMTasks.isNotEmpty) {
        _realtimePMTasks = _populatePMTaskReferences(_realtimePMTasks);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('UnifiedDataProvider: Error recovering references: $e');
    }
  }
}
