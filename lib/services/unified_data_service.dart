// Unified Data Service - Single source of truth for all data operations
// This service ensures data consistency across all screens and providers

import 'dart:async';

import 'package:uuid/uuid.dart';

import '../models/asset.dart';
import '../models/inventory_item.dart';
import '../models/pm_task.dart';
import '../models/user.dart';
import '../models/work_order.dart';
import '../models/workflow_models.dart';
import '../utils/deterministic_id_generator.dart';
import 'supabase_database_service.dart';
import 'hybrid_dam_service.dart';
import 'realtime_supabase_service.dart';

class UnifiedDataService {
  factory UnifiedDataService() => _instance;
  UnifiedDataService._internal();
  static final UnifiedDataService _instance = UnifiedDataService._internal();

  static UnifiedDataService get instance => _instance;

  // Cache for all data
  List<WorkOrder> _workOrders = [];
  List<PMTask> _pmTasks = [];
  List<User> _users = [];
  List<Asset> _assets = [];
  List<InventoryItem> _inventoryItems = [];
  List<Workflow> _workflows = [];

  // Loading states
  bool _isWorkOrdersLoading = false;
  bool _isPMTasksLoading = false;
  bool _isUsersLoading = false;
  bool _isAssetsLoading = false;
  bool _isInventoryLoading = false;
  bool _isWorkflowsLoading = false;
  bool _isHealingWorkOrders = false;
  final Set<String> _pendingUserFetches = <String>{};
  final Set<String> _pendingAssetFetches = <String>{};

  // Getters
  List<WorkOrder> get workOrders => _workOrders;
  List<PMTask> get pmTasks => _pmTasks;
  List<User> get users => _users;
  List<Asset> get assets => _assets;
  List<InventoryItem> get inventoryItems => _inventoryItems;
  List<Workflow> get workflows => _workflows;
  Future<WorkOrder> _loadWorkOrder(String workOrderId) async {
    try {
      return _workOrders.firstWhere((wo) => wo.id == workOrderId);
    } on StateError {
      // Load from Firestore
      final fetched = await SupabaseDatabaseService.instance.getWorkOrder(
        workOrderId,
      );
      if (fetched != null) {
        await _upsertWorkOrderInCache(fetched);
        return fetched;
      }

      await _healWorkOrdersFromFirestore(missingWorkOrderId: workOrderId);

      try {
        return _workOrders.firstWhere((wo) => wo.id == workOrderId);
      } on StateError {
        throw StateError('Work order $workOrderId not found');
      }
    }
  }

  Future<void> _upsertWorkOrderInCache(WorkOrder workOrder) async {
    final index = _workOrders.indexWhere((wo) => wo.id == workOrder.id);
    if (index == -1) {
      _workOrders.add(workOrder);
    } else {
      _workOrders[index] = workOrder;
    }
    // No local DB persistence - Firestore is the source of truth
  }

  Future<void> _healWorkOrdersFromFirestore({
    String? missingWorkOrderId,
  }) async {
    if (_isHealingWorkOrders) {
      print(
        '⏳ UnifiedDataService: Auto-heal already running; skipping duplicate request',
      );
      return;
    }

    _isHealingWorkOrders = true;
    try {
      final reason = missingWorkOrderId != null
          ? ' (missing $missingWorkOrderId)'
          : '';
      print('🩺 UnifiedDataService: Auto-healing work orders$reason...');

      final remoteOrders =
          await SupabaseDatabaseService.instance.getAllWorkOrders();
      if (remoteOrders.isEmpty) {
        print('⚠️ UnifiedDataService: Firestore returned 0 work orders');
        return;
      }

      final merged = <String, WorkOrder>{
        for (final wo in _workOrders) wo.id: wo,
      };
      for (final remote in remoteOrders) {
        merged[remote.id] = remote;
      }
      _workOrders = merged.values.toList();

      // No local DB persistence - Firestore is the source of truth

      _populateReferences();
      print(
        '✅ UnifiedDataService: Auto-heal refreshed ${remoteOrders.length} work orders from Firestore',
      );
    } catch (e) {
      print('❌ UnifiedDataService: Auto-heal failed: $e');
    } finally {
      _isHealingWorkOrders = false;
    }
  }


  bool get isWorkOrdersLoading => _isWorkOrdersLoading;
  bool get isPMTasksLoading => _isPMTasksLoading;
  bool get isUsersLoading => _isUsersLoading;
  bool get isAssetsLoading => _isAssetsLoading;
  bool get isInventoryLoading => _isInventoryLoading;
  bool get isWorkflowsLoading => _isWorkflowsLoading;

  // ============================================================================
  // REAL-TIME FIRESTORE STREAMS - Direct UI Connection
  // ============================================================================

  /// Get real-time stream of work orders from Supabase
  Stream<List<WorkOrder>> get workOrdersStream =>
      RealtimeSupabaseService.instance.getWorkOrdersStream();

  /// Get real-time stream of PM tasks from Supabase
  Stream<List<PMTask>> get pmTasksStream =>
      RealtimeSupabaseService.instance.getPMTasksStream();

  /// Get real-time stream of assets from Supabase
  Stream<List<Asset>> get assetsStream =>
      RealtimeSupabaseService.instance.getAssetsStream();

  /// Get real-time stream of users from Supabase
  Stream<List<User>> get usersStream =>
      RealtimeSupabaseService.instance.getUsersStream();

  /// Get real-time stream of inventory items from Supabase
  Stream<List<InventoryItem>> get inventoryItemsStream =>
      RealtimeSupabaseService.instance.getInventoryItemsStream();

  /// Get real-time stream of workflows from Supabase
  Stream<List<Workflow>> get workflowsStream =>
      RealtimeSupabaseService.instance.getWorkflowsStream();

  /// Get real-time stream of work orders for a specific technician
  Stream<List<WorkOrder>> getWorkOrdersByTechnicianStream(
    String technicianId,
  ) =>
      RealtimeSupabaseService.instance
          .getWorkOrdersByTechnicianStream(technicianId);

  /// Get real-time stream of PM tasks for a specific technician
  Stream<List<PMTask>> getPMTasksByTechnicianStream(String technicianId) =>
      RealtimeSupabaseService.instance
          .getPMTasksByTechnicianStream(technicianId);

  /// Get real-time stream of a single work order
  Stream<WorkOrder?> getWorkOrderStream(String workOrderId) =>
      RealtimeSupabaseService.instance.getWorkOrderStream(workOrderId);

  /// Get real-time stream of a single PM task
  Stream<PMTask?> getPMTaskStream(String pmTaskId) =>
      RealtimeSupabaseService.instance.getPMTaskStream(pmTaskId);

  /// Get real-time stream of a single asset
  Stream<Asset?> getAssetStream(String assetId) =>
      RealtimeSupabaseService.instance.getAssetStream(assetId);

  /// Get real-time stream of a single workflow
  Stream<Workflow?> getWorkflowStream(String workflowId) =>
      RealtimeSupabaseService.instance.getWorkflowStream(workflowId);

  /// Get real-time stream of workflows for a specific user
  Stream<List<Workflow>> getWorkflowsByUserStream(String userId) =>
      RealtimeSupabaseService.instance.getWorkflowsByUserStream(userId);

  /// Get real-time stream of pending approvals for a specific user
  Stream<List<Workflow>> getPendingApprovalsByUserStream(String userId) =>
      RealtimeSupabaseService.instance.getPendingApprovalsByUserStream(userId);

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialize all data services and load data
  Future<void> initialize() async {
    print('🔄 UnifiedDataService: Initializing all data services...');

    try {
      // Initialize Firestore (already done in main.dart, but ensure it's ready)
      await SupabaseDatabaseService.instance.initialize();

      // Load all data from Firestore in parallel
      await Future.wait([
        _loadWorkOrders(),
        _loadPMTasks(),
        _loadUsers(),
        _loadAssets(),
        _loadInventory(),
        _loadWorkflows(),
      ]);

      // Populate cross-references after all data is loaded
      _populateReferences();

      print('✅ UnifiedDataService: All data loaded successfully from Firestore');
    } catch (e) {
      print('❌ UnifiedDataService: Error initializing: $e');
      rethrow;
    }
  }

  /// Load work orders from Firestore
  Future<void> _loadWorkOrders() async {
    _isWorkOrdersLoading = true;
    try {
      _workOrders = await SupabaseDatabaseService.instance.getAllWorkOrders();
      print('📋 UnifiedDataService: Loaded ${_workOrders.length} work orders from Firestore');
    } catch (e) {
      print('❌ UnifiedDataService: Error loading work orders: $e');
      _workOrders = []; // Initialize empty list on error
    } finally {
      _isWorkOrdersLoading = false;
    }
  }

  /// Sync cached work orders with real-time updates
  void syncRealtimeWorkOrders(List<WorkOrder> realtimeOrders) {
    if (realtimeOrders.isEmpty) return;
    final merged = <String, WorkOrder>{
      for (final wo in _workOrders) wo.id: wo,
    };
    for (final realtime in realtimeOrders) {
      merged[realtime.id] = realtime;
    }
    _workOrders = merged.values.toList();
  }

  /// Load PM tasks from Firestore
  Future<void> _loadPMTasks() async {
    _isPMTasksLoading = true;
    try {
      _pmTasks = await SupabaseDatabaseService.instance.getAllPMTasks();
      print('📋 UnifiedDataService: Loaded ${_pmTasks.length} PM tasks from Firestore');
    } catch (e) {
      print('❌ UnifiedDataService: Error loading PM tasks: $e');
      _pmTasks = []; // Initialize empty list on error
    } finally {
      _isPMTasksLoading = false;
    }
  }

  /// Load users from Firestore
  Future<void> _loadUsers() async {
    _isUsersLoading = true;
    try {
      _users = await SupabaseDatabaseService.instance.getAllUsers();
      print('👥 UnifiedDataService: Loaded ${_users.length} users from Firestore');
    } catch (e) {
      print('❌ UnifiedDataService: Error loading users: $e');
      _users = []; // Initialize empty list on error
    } finally {
      _isUsersLoading = false;
    }
  }

  /// Load assets from Firestore
  Future<void> _loadAssets() async {
    _isAssetsLoading = true;
    try {
      _assets = await SupabaseDatabaseService.instance.getAllAssets();
      print('🏭 UnifiedDataService: Loaded ${_assets.length} assets from Firestore');
    } catch (e) {
      print('❌ UnifiedDataService: Error loading assets: $e');
      _assets = []; // Initialize empty list on error
    } finally {
      _isAssetsLoading = false;
    }
  }

  /// Load inventory from Firestore
  Future<void> _loadInventory() async {
    _isInventoryLoading = true;
    try {
      _inventoryItems =
          await SupabaseDatabaseService.instance.getAllInventoryItems();
      print(
        '📦 UnifiedDataService: Loaded ${_inventoryItems.length} inventory items from Firestore',
      );
    } catch (e) {
      print('❌ UnifiedDataService: Error loading inventory: $e');
      _inventoryItems = []; // Initialize empty list on error
    } finally {
      _isInventoryLoading = false;
    }
  }

  /// Ensure specific users are loaded into cache
  Future<void> ensureUsersLoaded(Set<String> userIds) async {
    final targets = userIds
        .where((id) => id.isNotEmpty)
        .where((id) => !_users.any((user) => user.id == id))
        .where((id) => !_pendingUserFetches.contains(id))
        .toList();
    if (targets.isEmpty) return;

    _pendingUserFetches.addAll(targets);
    try {
      print(
        '🔎 UnifiedDataService: Fetching ${targets.length} missing user(s)...',
      );
      for (final id in targets) {
        try {
          final fetchedUser =
              await SupabaseDatabaseService.instance.getUserById(id);
          if (fetchedUser != null) {
            final existingIndex = _users.indexWhere((user) => user.id == id);
            if (existingIndex != -1) {
              _users[existingIndex] = fetchedUser;
            } else {
              _users.add(fetchedUser);
            }
            // No local DB persistence - Firestore is the source of truth
            print(
              '✅ UnifiedDataService: Loaded user ${fetchedUser.name} ($id)',
            );
          } else {
            print('⚠️ UnifiedDataService: User $id not found in Firestore');
          }
        } catch (e) {
          print('❌ UnifiedDataService: Error fetching user $id: $e');
        }
      }
      _populateReferences();
    } finally {
      _pendingUserFetches.removeAll(targets);
    }
  }

  /// Ensure specific assets are loaded into cache
  Future<void> ensureAssetsLoaded(Set<String> assetIds) async {
    final targets = assetIds
        .where((id) => id.isNotEmpty)
        .where((id) => !_assets.any((asset) => asset.id == id))
        .where((id) => !_pendingAssetFetches.contains(id))
        .toList();
    if (targets.isEmpty) return;

    _pendingAssetFetches.addAll(targets);
    try {
      print(
        '🔎 UnifiedDataService: Fetching ${targets.length} missing asset(s)...',
      );
      for (final id in targets) {
        try {
          // First try the 'assets' collection
          var fetchedAsset = await SupabaseDatabaseService.instance.getAsset(
            id,
          );
          
          // If not found, try the 'items' collection (DAM system)
          if (fetchedAsset == null) {
            print(
              '⚠️ UnifiedDataService: Asset $id not found in assets collection, trying items collection...',
            );
            fetchedAsset = await _getAssetFromItemsCollection(id);
          }
          
          if (fetchedAsset != null) {
            final existingIndex = _assets.indexWhere((asset) => asset.id == id);
            if (existingIndex != -1) {
              _assets[existingIndex] = fetchedAsset;
            } else {
              _assets.add(fetchedAsset);
            }
            // No local DB persistence - Firestore is the source of truth
            print(
              '✅ UnifiedDataService: Loaded asset ${fetchedAsset.name} ($id)',
            );
          } else {
            print('⚠️ UnifiedDataService: Asset $id not found in Firestore (checked both assets and items collections)');
          }
        } catch (e) {
          print('❌ UnifiedDataService: Error fetching asset $id: $e');
        }
      }
      _populateReferences();
    } finally {
      _pendingAssetFetches.removeAll(targets);
    }
  }

  /// Get asset from the 'items' collection (DAM system)
  Future<Asset?> _getAssetFromItemsCollection(String assetId) async {
    try {
      // Use the HybridDamService which has access to the 'items' collection
      final hybridService = HybridDamService();
      await hybridService.initialize();
      final allAssets = await hybridService.getAllAssets();
      final asset = allAssets.firstWhere(
        (a) => a.id == assetId,
        orElse: () => throw StateError('Asset not found'),
      );
      return asset;
    } catch (e) {
      print('⚠️ UnifiedDataService: Error fetching asset $assetId from items collection: $e');
      return null;
    }
  }

  /// Validate that referenced users/assets exist (fetching them if possible)
  /// Assets are optional (for general maintenance), so missing assets only log a warning
  Future<void> validateReferences({
    Set<String>? userIds,
    Set<String>? assetIds,
  }) async {
    final missingUsers = <String>{};
    final missingAssets = <String>{};

    if (userIds != null && userIds.isNotEmpty) {
      await ensureUsersLoaded(userIds);
      for (final id in userIds) {
        if (id.isEmpty) continue;
        final exists = _users.any((user) => user.id == id);
        if (!exists) {
          missingUsers.add(id);
        }
      }
    }

    if (assetIds != null && assetIds.isNotEmpty) {
      await ensureAssetsLoaded(assetIds);
      for (final id in assetIds) {
        if (id.isEmpty) continue;
        final exists = _assets.any((asset) => asset.id == id);
        if (!exists) {
          missingAssets.add(id);
        }
      }
    }

    // Log warning for missing assets (they're optional for general maintenance)
    if (missingAssets.isNotEmpty) {
      print(
        '⚠️ UnifiedDataService: Asset(s) not found: ${missingAssets.join(', ')}. '
        'Work order will be created without asset reference (general maintenance).',
      );
    }

    // Only throw error for missing users (they're required)
    if (missingUsers.isNotEmpty) {
      final buffer = StringBuffer('Reference validation failed:');
      buffer.write(' missing users: ${missingUsers.join(', ')};');
      if (missingAssets.isNotEmpty) {
        buffer.write(' missing assets: ${missingAssets.join(', ')} (optional);');
      }
      throw Exception(buffer.toString());
    }
  }

  /// Populate cross-references between entities
  void _populateReferences() {
    print('🔗 UnifiedDataService: Populating cross-references...');

    // Populate asset references in work orders
    for (var i = 0; i < _workOrders.length; i++) {
      final workOrder = _workOrders[i];
      if (workOrder.asset == null && (workOrder.assetId?.isNotEmpty ?? false)) {
        final asset = _assets.firstWhere(
          (a) => a.id == workOrder.assetId,
          orElse: () => Asset(
            id: workOrder.assetId!,
            name: 'Unknown Asset',
            location: '',
            status: 'unknown',
            category: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        _workOrders[i] = workOrder.copyWith(asset: asset);
      }

      // Populate technician references
      if (workOrder.assignedTechnicianIds.isNotEmpty) {
        final technicians = <User>[];
        for (final techId in workOrder.assignedTechnicianIds) {
          try {
            final technician = _users.firstWhere(
              (u) => u.id == techId,
            );
            technicians.add(technician);
          } catch (e) {
            print('⚠️ Technician $techId not found for work order ${workOrder.id}');
          }
        }
        if (technicians.isNotEmpty) {
          _workOrders[i] =
              _workOrders[i].copyWith(assignedTechnicians: technicians);
        }
      }

      // Populate requestor references
      if (workOrder.requestor == null && workOrder.requestorId.isNotEmpty) {
        try {
          final requestor = _users.firstWhere(
            (u) => u.id == workOrder.requestorId,
          );
          _workOrders[i] = _workOrders[i].copyWith(requestor: requestor);
        } catch (e) {
          // User not found - leave as null instead of creating fake user
          print(
            '⚠️ Requestor ${workOrder.requestorId} not found for work order ${workOrder.id}',
          );
        }
      }
    }

    // Populate asset references in PM tasks
    for (var i = 0; i < _pmTasks.length; i++) {
      final pmTask = _pmTasks[i];
      if (pmTask.assetId.isNotEmpty) {
        final asset = _assets.firstWhere(
          (a) => a.id == pmTask.assetId,
          orElse: () => Asset(
            id: pmTask.assetId,
            name: 'Unknown Asset',
            location: '',
            status: 'unknown',
            category: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        // Update the PM task with asset name and location
        _pmTasks[i] = pmTask.copyWith(
          assetName: asset.name,
          assetLocation: asset.location,
        );
      }

      // Populate technician references (assignedTechnicians collection)
      if (pmTask.assignedTechnicianIds.isNotEmpty) {
        final technicians = <User>[];
        for (final techId in pmTask.assignedTechnicianIds) {
          try {
            final technician = _users.firstWhere(
              (u) => u.id == techId,
            );
            technicians.add(technician);
          } catch (e) {
            print(
              '⚠️ Technician $techId not found for PM task ${pmTask.id}',
            );
          }
        }
        if (technicians.isNotEmpty) {
          _pmTasks[i] = _pmTasks[i].copyWith(
            assignedTechnicians: technicians,
          );
        }
      }
    }

    print('✅ UnifiedDataService: Cross-references populated');
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    print('🔄 UnifiedDataService: Refreshing all data...');
    await initialize();
  }

  // ============================================================================
  // FILTERED QUERIES (Server-first with local fallback)
  // ============================================================================
  Future<List<WorkOrder>> queryWorkOrders({
    WorkOrderStatus? status,
    WorkOrderPriority? priority,
    String? assignedTechnicianId,
    String? assetId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Query directly from Firestore
    return await SupabaseDatabaseService.instance.queryWorkOrders(
      status: status,
      priority: priority,
      assignedTechnicianId: assignedTechnicianId,
      assetId: assetId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<List<PMTask>> queryPMTasks({
    PMTaskStatus? status,
    String? assignedTechnicianId,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextDueStart,
    DateTime? nextDueEnd,
  }) async {
    // Query directly from Firestore
    return await SupabaseDatabaseService.instance.queryPMTasks(
      status: status,
      assignedTechnicianId: assignedTechnicianId,
      startDate: startDate,
      endDate: endDate,
      nextDueStart: nextDueStart,
      nextDueEnd: nextDueEnd,
    );
  }

  /// Get work orders by technician
  List<WorkOrder> getWorkOrdersByTechnician(String technicianId) => _workOrders
      .where((wo) => wo.assignedTechnicianIds.contains(technicianId))
      .toList();

  /// Get PM tasks by technician
  List<PMTask> getPMTasksByTechnician(String technicianId) => _pmTasks
      .where((task) => task.assignedTechnicianIds.contains(technicianId))
      .toList();

  /// Get technicians only
  List<User> getTechnicians() =>
      _users.where((user) => user.role == 'technician').toList();

  /// Create work order and update cache (DUAL-WRITE: Local + Firestore)
  Future<String> createWorkOrder(WorkOrder workOrder) async {
    try {
      final userRefs = <String>{};
      if (workOrder.requestorId.isNotEmpty) {
        userRefs.add(workOrder.requestorId);
      }
      userRefs.addAll(workOrder.assignedTechnicianIds);
      if ((workOrder.primaryTechnicianId ?? '').isNotEmpty) {
        userRefs.add(workOrder.primaryTechnicianId!);
      }
      final assetRefs = <String>{};
      final assetId = workOrder.assetId;
      if (assetId != null && assetId.isNotEmpty) {
        assetRefs.add(assetId);
      }
      await validateReferences(
        userIds: userRefs,
        assetIds: assetRefs,
      );

      // Generate readable ID: WO-YYYY-NNNNN format
      // If ticket number is already in correct format, use it as ID
      String generatedId;
      if (workOrder.ticketNumber.isNotEmpty && 
          RegExp(r'^WO-\d{4}-\d{5}$').hasMatch(workOrder.ticketNumber)) {
        // Ticket number is in correct format, use it as ID
        generatedId = workOrder.ticketNumber;
      } else {
        // Generate readable ID from ticket number or create new one
        generatedId = DeterministicIdGenerator.generateWorkOrderId(
          idempotencyKey: workOrder.idempotencyKey,
          ticketNumber: workOrder.ticketNumber,
          requestorId: workOrder.requestorId,
          createdAt: workOrder.createdAt,
        );
        // If ticket number doesn't match format, update it to match the generated ID
        if (!RegExp(r'^WO-\d{4}-\d{5}$').hasMatch(workOrder.ticketNumber)) {
          // Update work order with the generated ticket number
          workOrder = workOrder.copyWith(ticketNumber: generatedId);
        }
      }
      final id = workOrder.id.isNotEmpty ? workOrder.id : generatedId;
      final woWithId =
          workOrder.id == id ? workOrder : workOrder.copyWith(id: id);

      // Check for existing work order with same ID (upsert logic)
      final existingIndex = _workOrders.indexWhere((wo) => wo.id == id);
      if (existingIndex != -1) {
        print('⚠️ Work order $id already exists - updating instead');
        _workOrders[existingIndex] = woWithId;
      } else {
        _workOrders.add(woWithId);
      }

      // Write directly to Supabase
      await SupabaseDatabaseService.instance.createWorkOrder(woWithId);
      print(
        '✅ UnifiedDataService: Created work order ${woWithId.ticketNumber} in Supabase',
      );

      return id;
    } catch (e) {
      print('❌ UnifiedDataService: Error creating work order: $e');
      rethrow;
    }
  }

  /// Update work order and update cache (DUAL-WRITE: Local + Supabase)
  /// Populate references for a single work order
  WorkOrder _populateWorkOrderReferences(WorkOrder workOrder) {
    var updatedWorkOrder = workOrder;

    // Populate asset reference
    if (updatedWorkOrder.asset == null &&
        (updatedWorkOrder.assetId?.isNotEmpty ?? false)) {
      try {
        final asset = _assets.firstWhere(
          (a) => a.id == updatedWorkOrder.assetId,
        );
        updatedWorkOrder = updatedWorkOrder.copyWith(asset: asset);
      } catch (e) {
        print('⚠️ Asset ${updatedWorkOrder.assetId} not found');
      }
    }

    // Populate assigned technician references
    if (updatedWorkOrder.assignedTechnicianIds.isNotEmpty) {
      final technicians = <User>[];
      for (final techId in updatedWorkOrder.assignedTechnicianIds) {
        try {
          final technician = _users.firstWhere(
            (u) => u.id == techId,
          );
          technicians.add(technician);
        } catch (e) {
          print('⚠️ Technician $techId not found for WO ${updatedWorkOrder.id}');
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
        final requestor = _users.firstWhere(
          (u) => u.id == updatedWorkOrder.requestorId,
        );
        updatedWorkOrder = updatedWorkOrder.copyWith(requestor: requestor);
      } catch (e) {
        print('⚠️ Requestor ${updatedWorkOrder.requestorId} not found');
      }
    }

    return updatedWorkOrder;
  }

  PMTask _populatePMTaskReferences(PMTask pmTask) {
    var updatedPMTask = pmTask;

    // Populate asset reference
    if (updatedPMTask.asset == null &&
        updatedPMTask.assetId.isNotEmpty) {
      try {
        final asset = _assets.firstWhere(
          (a) => a.id == updatedPMTask.assetId,
        );
        updatedPMTask = updatedPMTask.copyWith(asset: asset);
      } catch (e) {
        print('⚠️ Asset ${updatedPMTask.assetId} not found for PM task ${updatedPMTask.id}');
      }
    }

    // Populate assigned technician references
    if (updatedPMTask.assignedTechnicianIds.isNotEmpty) {
      final technicians = <User>[];
      for (final techId in updatedPMTask.assignedTechnicianIds) {
        try {
          final technician = _users.firstWhere(
            (u) => u.id == techId,
          );
          technicians.add(technician);
        } catch (e) {
          print('⚠️ Technician $techId not found for PM task ${updatedPMTask.id}');
        }
      }
      if (technicians.isNotEmpty) {
        updatedPMTask =
            updatedPMTask.copyWith(assignedTechnicians: technicians);
      }
    }

    return updatedPMTask;
  }

  Future<WorkOrder> updateWorkOrder(WorkOrder workOrder) async {
    try {
      final userRefs = <String>{};
      if (workOrder.requestorId.isNotEmpty) {
        userRefs.add(workOrder.requestorId);
      }
      userRefs.addAll(workOrder.assignedTechnicianIds);
      if ((workOrder.primaryTechnicianId ?? '').isNotEmpty) {
        userRefs.add(workOrder.primaryTechnicianId!);
      }
      final assetRefs = <String>{};
      final assetId = workOrder.assetId;
      if (assetId != null && assetId.isNotEmpty) {
        assetRefs.add(assetId);
      }
      await validateReferences(
        userIds: userRefs,
        assetIds: assetRefs,
      );

      // Populate references before updating
      final updatedWorkOrder = _populateWorkOrderReferences(workOrder);

      // Update Firestore directly
      await SupabaseDatabaseService.instance
          .updateWorkOrder(updatedWorkOrder.id, updatedWorkOrder);
      final index = _workOrders.indexWhere((wo) => wo.id == updatedWorkOrder.id);
      if (index != -1) {
        _workOrders[index] = updatedWorkOrder;
      }
      print(
        '✅ UnifiedDataService: Updated work order ${updatedWorkOrder.ticketNumber} in Firestore',
      );

      return updatedWorkOrder;
    } catch (e) {
      print('❌ UnifiedDataService: Error updating work order: $e');
      rethrow;
    }
  }

  /// Delete work order from Firestore
  Future<void> deleteWorkOrder(String workOrderId) async {
    try {
      // Delete from Firestore
      await SupabaseDatabaseService.instance.deleteWorkOrder(workOrderId);
      _workOrders.removeWhere((wo) => wo.id == workOrderId);
      print('✅ UnifiedDataService: Deleted work order $workOrderId from Firestore');
    } catch (e) {
      print('❌ UnifiedDataService: Error deleting work order: $e');
      rethrow;
    }
  }

  /// Create asset and update cache (DUAL-WRITE: Local + Firestore)
  Future<String> createAsset(Asset asset) async {
    try {
      // 1. Ensure stable ID
      final assetId = asset.id.isNotEmpty ? asset.id : const Uuid().v4();
      final assetWithId =
          asset.id == assetId ? asset : asset.copyWith(id: assetId);

      // Write directly to Firestore
      await SupabaseDatabaseService.instance.createAsset(assetWithId);
      _assets.add(assetWithId);
      print('✅ UnifiedDataService: Created asset ${asset.name} in Firestore');

      return assetId;
    } catch (e) {
      print('❌ UnifiedDataService: Error creating asset: $e');
      rethrow;
    }
  }

  /// Delete asset from Firestore
  Future<void> deleteAsset(String assetId) async {
    try {
      // Delete from Firestore
      await SupabaseDatabaseService.instance.deleteAsset(assetId);
      _assets.removeWhere((asset) => asset.id == assetId);
      print('✅ UnifiedDataService: Deleted asset $assetId from Firestore');
    } catch (e) {
      print('❌ UnifiedDataService: Error deleting asset: $e');
      rethrow;
    }
  }

  /// Create user and update cache
  Future<String> createUser(User user) async {
    try {
      // Create in Firestore
      final userId = await SupabaseDatabaseService.instance.createUser(user);
      _users.add(user);
      print('✅ UnifiedDataService: Created user ${user.name} in Firestore');

      return userId;
    } catch (e) {
      print('❌ UnifiedDataService: Error creating user: $e');
      rethrow;
    }
  }

  /// Delete user and update cache
  /// Deletes from Firestore
  Future<void> deleteUser(String userId) async {
    try {
      // Remove from cache first
      _users.removeWhere((u) => u.id == userId);
      
      // Delete from Firestore
      await SupabaseDatabaseService.instance.deleteUser(userId);
      print('✅ UnifiedDataService: Deleted user $userId from Firestore');
    } catch (e) {
      print('❌ UnifiedDataService: Error deleting user: $e');
      rethrow;
    }
  }

  /// Update user and update cache
  Future<void> updateUser(User user) async {
    try {
      await SupabaseDatabaseService.instance.updateUser(user.id, user);
      final index = _users.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        _users[index] = user;
      }
      print('✅ UnifiedDataService: Updated user ${user.name} in Firestore');
    } catch (e) {
      print('❌ UnifiedDataService: Error updating user: $e');
      rethrow;
    }
  }

  /// Assign technician to work order (adds to existing list)
  Future<void> assignTechnicianToWorkOrder(
    String workOrderId,
    String technicianId,
  ) async {
    try {
      final workOrder = await _loadWorkOrder(workOrderId);
      final updatedIds = <String>[
        ...workOrder.assignedTechnicianIds.where((id) => id != technicianId),
        technicianId,
      ];
      await updateWorkOrderTechnicianAssignments(workOrderId, updatedIds);
    } catch (e) {
      print('❌ UnifiedDataService: Error assigning technician: $e');
      rethrow;
    }
  }

  /// Replace the technician roster for a work order
  Future<void> updateWorkOrderTechnicianAssignments(
    String workOrderId,
    List<String> technicianIds,
  ) async {
    try {
      final workOrder = await _loadWorkOrder(workOrderId);
      final uniqueIds = <String>[];
      final seen = <String>{};
      for (final id in technicianIds) {
        if (id.isEmpty || seen.contains(id)) continue;
        seen.add(id);
        uniqueIds.add(id);
      }

      if (uniqueIds.isNotEmpty) {
        await validateReferences(userIds: uniqueIds.toSet());
      }

      final assignedUsers = _users
          .where((user) => uniqueIds.contains(user.id))
          .toList(growable: false);

      final effortMinutes =
          Map<String, int>.from(workOrder.technicianEffortMinutes ?? {});
      effortMinutes.removeWhere((key, _) => !uniqueIds.contains(key));
      for (final id in uniqueIds) {
        effortMinutes.putIfAbsent(id, () => 0);
      }

      var newStatus = workOrder.status;
      if (uniqueIds.isEmpty) {
        if (workOrder.status == WorkOrderStatus.assigned) {
          newStatus = WorkOrderStatus.open;
        }
      } else if (workOrder.status == WorkOrderStatus.open) {
        newStatus = WorkOrderStatus.assigned;
      }

      final updatedWorkOrder = workOrder.copyWith(
        primaryTechnicianId: uniqueIds.isNotEmpty ? uniqueIds.first : null,
        assignedTechnicianIds: uniqueIds,
        assignedTechnicians: assignedUsers,
        technicianEffortMinutes:
            effortMinutes.isEmpty ? null : Map<String, int>.from(effortMinutes),
        assignedAt:
            uniqueIds.isNotEmpty ? (workOrder.assignedAt ?? DateTime.now()) : null,
        status: newStatus,
        updatedAt: DateTime.now(),
      );

      await updateWorkOrder(updatedWorkOrder);
      print(
        '✅ UnifiedDataService: Updated technician roster (${uniqueIds.length}) for work order $workOrderId',
      );
    } catch (e) {
      print(
        '❌ UnifiedDataService: Error updating work order technicians: $e',
      );
      rethrow;
    }
  }

  /// Unassign technician from work order
  Future<void> unassignTechnicianFromWorkOrder(
    String workOrderId, {
    String? technicianId,
  }) async {
    try {
      final workOrder = await _loadWorkOrder(workOrderId);
      final updatedIds = technicianId == null
          ? <String>[]
          : workOrder.assignedTechnicianIds
              .where((id) => id != technicianId)
              .toList();
      await updateWorkOrderTechnicianAssignments(workOrderId, updatedIds);
    } catch (e) {
      print('❌ UnifiedDataService: Error unassigning technician: $e');
      rethrow;
    }
  }

  /// Assign technician to PM task
  Future<void> assignTechnicianToPMTask(
    String pmTaskId,
    String technicianId,
  ) async {
    try {
      final pmTask = _pmTasks.firstWhere((pm) => pm.id == pmTaskId);
      final updatedIds = <String>[
        ...pmTask.assignedTechnicianIds.where((id) => id != technicianId),
        technicianId,
      ];
      await updatePMTaskTechnicianAssignments(pmTaskId, updatedIds);
    } catch (e) {
      print('❌ UnifiedDataService: Error assigning technician to PM task: $e');
      rethrow;
    }
  }

  Future<void> updatePMTaskTechnicianAssignments(
    String pmTaskId,
    List<String> technicianIds,
  ) async {
    try {
      final pmTask = _pmTasks.firstWhere((pm) => pm.id == pmTaskId);
      final uniqueIds = <String>[];
      final seen = <String>{};
      for (final id in technicianIds) {
        if (id.isEmpty || seen.contains(id)) continue;
        seen.add(id);
        uniqueIds.add(id);
      }

      if (uniqueIds.isNotEmpty) {
        await validateReferences(userIds: uniqueIds.toSet());
      }

      final assignedUsers = _users
          .where((user) => uniqueIds.contains(user.id))
          .toList(growable: false);

      final effortMinutes =
          Map<String, int>.from(pmTask.technicianEffortMinutes ?? {});
      effortMinutes.removeWhere((key, _) => !uniqueIds.contains(key));
      for (final id in uniqueIds) {
        effortMinutes.putIfAbsent(id, () => 0);
      }

      var newStatus = pmTask.status;
      if (uniqueIds.isEmpty) {
        if (pmTask.status == PMTaskStatus.inProgress) {
          newStatus = PMTaskStatus.pending;
        }
      } else if (pmTask.status == PMTaskStatus.pending) {
        newStatus = PMTaskStatus.inProgress;
      }

      final updatedPMTask = pmTask.copyWith(
        primaryTechnicianId: uniqueIds.isNotEmpty ? uniqueIds.first : null,
        assignedTechnicianIds: uniqueIds,
        assignedTechnicians: assignedUsers,
        technicianEffortMinutes:
            effortMinutes.isEmpty ? null : Map<String, int>.from(effortMinutes),
        status: newStatus,
        startedAt: uniqueIds.isNotEmpty
            ? (pmTask.startedAt ?? DateTime.now())
            : null,
      );

      await updatePMTask(updatedPMTask);
      print(
        '✅ UnifiedDataService: Updated technician roster (${uniqueIds.length}) for PM task $pmTaskId',
      );
    } catch (e) {
      print(
        '❌ UnifiedDataService: Error updating PM task technicians: $e',
      );
      rethrow;
    }
  }

  /// Unassign technician from PM task
  Future<void> unassignTechnicianFromPMTask(
    String pmTaskId, {
    String? technicianId,
  }) async {
    try {
      final pmTask = _pmTasks.firstWhere((pm) => pm.id == pmTaskId);
      final updatedIds = technicianId == null
          ? <String>[]
          : pmTask.assignedTechnicianIds
              .where((id) => id != technicianId)
              .toList();
      await updatePMTaskTechnicianAssignments(pmTaskId, updatedIds);
    } catch (e) {
      print(
        '❌ UnifiedDataService: Error unassigning technician from PM task: $e',
      );
      rethrow;
    }
  }

  /// Create PM task
  Future<void> createPMTask({
    required String taskName,
    required String description,
    required String checklistJson,
    required PMTaskFrequency frequency,
    required DateTime nextDue,
    String assetId = '', // Optional - can be empty for general PM tasks
    Asset? asset, // Pass full asset object if available
    List<String>? assignedTechnicianIds,
    String? createdById, // Track who created this PM task
  }) async {
    try {
      // Get the asset to populate name and location
      // Use passed asset if available, otherwise look it up
      final assignedIds = (assignedTechnicianIds ?? <String>[])
          .where((id) => id.isNotEmpty)
          .toList();
      
      // Only validate asset reference if assetId is provided
      final assetRefs = assetId.isNotEmpty ? {assetId} : <String>{};
      await validateReferences(
        userIds: assignedIds.toSet(),
        assetIds: assetRefs,
      );

      // Only look up asset if assetId is provided
      if (assetId.isNotEmpty && asset == null) {
        asset = _assets.firstWhere(
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
      List<User>? assignedTechnicians;
      if (assignedIds.isNotEmpty) {
        assignedTechnicians = _users
            .where((user) => assignedIds.contains(user.id))
            .toList();
      }

      // Generate PM task ID - use assetId if provided, otherwise use 'GENERAL'
      final assetPrefix = assetId.isNotEmpty ? assetId : 'GENERAL';
      final pmIdBase =
          'PM-${assetPrefix}-${taskName}-${DateTime.now().millisecondsSinceEpoch}';
      final pmDocId =
          DeterministicIdGenerator.normalizeDocumentId(pmIdBase.toUpperCase());

      // Debug: Print checklist JSON to verify it's being passed
      print('📋 UnifiedDataService: Creating PM task with checklist: $checklistJson');
      
      final pmTask = PMTask(
        id: pmDocId.isNotEmpty ? pmDocId : const Uuid().v4(),
        taskName: taskName,
        assetId: assetId,
        assetName: asset?.name, // Populate asset name if asset exists
        assetLocation: asset?.location, // Populate asset location if asset exists
        description: description,
        checklist: checklistJson,
        frequency: frequency,
        intervalDays: _getIntervalDays(frequency),
        nextDueDate: nextDue,
        primaryTechnicianId: assignedIds.isNotEmpty ? assignedIds.first : null,
        assignedTechnicianIds: assignedIds,
        assignedTechnicians: assignedTechnicians,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdById: createdById, // Store who created this PM task
      );
      
      // Debug: Verify checklist was set on PMTask
      print('📋 UnifiedDataService: PMTask checklist after creation: ${pmTask.checklist}');

      // Write directly to Firestore
      await SupabaseDatabaseService.instance.createPMTask(pmTask);
      _pmTasks.add(pmTask);
      final primaryAssigned = assignedTechnicians?.isNotEmpty ?? false
          ? assignedTechnicians!.first.name
          : null;
      print(
        primaryAssigned != null
            ? '✅ UnifiedDataService: Created PM task $taskName assigned to $primaryAssigned in Firestore'
            : '✅ UnifiedDataService: Created PM task $taskName (unassigned) in Firestore',
      );
    } catch (e) {
      print('❌ UnifiedDataService: Error creating PM task: $e');
      rethrow;
    }
  }

  /// Update PM task (DUAL-WRITE: Local + Firestore)
  Future<PMTask> updatePMTask(PMTask pmTask) async {
    try {
      // Populate references before updating
      final populatedPMTask = _populatePMTaskReferences(pmTask);
      
      // Update Firestore directly
      await SupabaseDatabaseService.instance
          .updatePMTask(populatedPMTask.id, populatedPMTask);
      final index = _pmTasks.indexWhere((pt) => pt.id == populatedPMTask.id);
      if (index != -1) {
        _pmTasks[index] = populatedPMTask;
      } else {
        _pmTasks.add(populatedPMTask);
      }
      print('✅ UnifiedDataService: Updated PM task ${populatedPMTask.taskName} in Firestore');
      
      return populatedPMTask;
    } catch (e) {
      print('❌ UnifiedDataService: Error updating PM task: $e');
      rethrow;
    }
  }

  /// Delete PM task from Firestore
  Future<void> deletePMTask(String pmTaskId) async {
    try {
      // Delete from Firestore
      await SupabaseDatabaseService.instance.deletePMTask(pmTaskId);
      _pmTasks.removeWhere((pt) => pt.id == pmTaskId);
      print('✅ UnifiedDataService: Deleted PM task $pmTaskId from Firestore');
    } catch (e) {
      print('❌ UnifiedDataService: Error deleting PM task: $e');
      rethrow;
    }
  }

  /// Helper method to get interval days based on frequency
  int _getIntervalDays(PMTaskFrequency frequency) {
    switch (frequency) {
      case PMTaskFrequency.daily:
        return 1;
      case PMTaskFrequency.weekly:
        return 7;
      case PMTaskFrequency.monthly:
        return 30;
      case PMTaskFrequency.quarterly:
        return 90;
      case PMTaskFrequency.semiAnnually:
        return 180;
      case PMTaskFrequency.annually:
        return 365;
      case PMTaskFrequency.asNeeded:
        return 0;
    }
  }

  /// Get dashboard statistics
  Map<String, dynamic> getDashboardStats() {
    final now = DateTime.now();
    // Calculate 30 days ago for filtering
    now.subtract(const Duration(days: 30));

    return {
      'totalWorkOrders': _workOrders.length,
      'openWorkOrders': _workOrders.where((wo) => wo.isOpen).length,
      'inProgressWorkOrders': _workOrders.where((wo) => wo.isInProgress).length,
      'completedWorkOrders': _workOrders.where((wo) => wo.isCompleted).length,
      'overdueWorkOrders': _workOrders.where((wo) => wo.isOverdue).length,
      'highPriorityWorkOrders':
          _workOrders.where((wo) => wo.isHighPriority).length,
      'totalPMTasks': _pmTasks.length,
      'pendingPMTasks': _pmTasks
          .where((task) => task.status.toString().contains('pending'))
          .length,
      'completedPMTasks': _pmTasks
          .where((task) => task.status.toString().contains('completed'))
          .length,
      'totalUsers': _users.length,
      'technicians': _users.where((user) => user.role == 'technician').length,
      'totalAssets': _assets.length,
      'totalInventory': _inventoryItems.length,
      'lowStockItems':
          _inventoryItems.where((item) => item.quantity <= 10).length,
      'totalWorkflows': _workflows.length,
      'pendingApprovalWorkflows':
          _workflows.where((w) => w.isPendingApproval).length,
      'approvedWorkflows': _workflows.where((w) => w.isApproved).length,
      'completedWorkflows': _workflows.where((w) => w.isCompleted).length,
      'overdueWorkflows': _workflows.where((w) => w.isOverdue).length,
    };
  }

  /// Get technician-specific dashboard data
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

  /// Pause a work order with reason (DUAL-WRITE: Local + Firestore)
  Future<WorkOrder> pauseWorkOrder(String workOrderId, String reason) async {
    try {
      final workOrder = _workOrders.firstWhere((wo) => wo.id == workOrderId);
      final updatedWorkOrder = workOrder.copyWith(
        isPaused: true,
        pausedAt: DateTime.now(),
        pauseReason: reason,
        pauseHistory: [
          ...(workOrder.pauseHistory ?? []),
          {
            'pausedAt': DateTime.now().toIso8601String(),
            'reason': reason,
          },
        ],
        updatedAt: DateTime.now(),
      );

      // Update Firestore directly
      await SupabaseDatabaseService.instance
          .updateWorkOrder(workOrderId, updatedWorkOrder);
      final index = _workOrders.indexWhere((wo) => wo.id == workOrderId);
      if (index != -1) {
        _workOrders[index] = updatedWorkOrder;
      }
      print(
        '⏸️ UnifiedDataService: Paused work order ${workOrder.ticketNumber} with reason: $reason in Firestore',
      );
      
      return updatedWorkOrder;
    } catch (e) {
      print('❌ UnifiedDataService: Error pausing work order: $e');
      rethrow;
    }
  }

  /// Resume a paused work order (DUAL-WRITE: Local + Firestore)
  Future<WorkOrder> resumeWorkOrder(String workOrderId) async {
    try {
      final workOrder = _workOrders.firstWhere((wo) => wo.id == workOrderId);
      final updatedWorkOrder = workOrder.copyWith(
        isPaused: false,
        resumedAt: DateTime.now(),
        pauseHistory: [
          ...(workOrder.pauseHistory ?? []),
          {
            'resumedAt': DateTime.now().toIso8601String(),
          },
        ],
        updatedAt: DateTime.now(),
      );

      // Update Firestore directly
      await SupabaseDatabaseService.instance
          .updateWorkOrder(workOrderId, updatedWorkOrder);
      final index = _workOrders.indexWhere((wo) => wo.id == workOrderId);
      if (index != -1) {
        _workOrders[index] = updatedWorkOrder;
      }
      print(
        '▶️ UnifiedDataService: Resumed work order ${workOrder.ticketNumber} in Firestore',
      );
      
      return updatedWorkOrder;
    } catch (e) {
      print('❌ UnifiedDataService: Error resuming work order: $e');
      rethrow;
    }
  }

  /// Pause a PM task with reason (DUAL-WRITE: Local + Firestore)
  Future<PMTask> pausePMTask(String pmTaskId, String reason) async {
    try {
      final pmTask = _pmTasks.firstWhere((pt) => pt.id == pmTaskId);
      final updatedPMTask = pmTask.copyWith(
        isPaused: true,
        pausedAt: DateTime.now(),
        pauseReason: reason,
        pauseHistory: [
          ...(pmTask.pauseHistory ?? []),
          {
            'pausedAt': DateTime.now().toIso8601String(),
            'reason': reason,
          },
        ],
        updatedAt: DateTime.now(),
      );

      // Update Firestore directly
      await SupabaseDatabaseService.instance
          .updatePMTask(pmTaskId, updatedPMTask);
      final index = _pmTasks.indexWhere((pt) => pt.id == pmTaskId);
      if (index != -1) {
        _pmTasks[index] = updatedPMTask;
      }
      print(
        '⏸️ UnifiedDataService: Paused PM task ${pmTask.taskName} with reason: $reason in Firestore',
      );

      return updatedPMTask;
    } catch (e) {
      print('❌ UnifiedDataService: Error pausing PM task: $e');
      rethrow;
    }
  }

  /// Resume a paused PM task (DUAL-WRITE: Local + Firestore)
  Future<PMTask> resumePMTask(String pmTaskId) async {
    try {
      final pmTask = _pmTasks.firstWhere((pt) => pt.id == pmTaskId);
      final updatedPMTask = pmTask.copyWith(
        isPaused: false,
        resumedAt: DateTime.now(),
        pauseHistory: [
          ...(pmTask.pauseHistory ?? []),
          {
            'resumedAt': DateTime.now().toIso8601String(),
          },
        ],
        updatedAt: DateTime.now(),
      );

      // Update Firestore directly
      await SupabaseDatabaseService.instance
          .updatePMTask(pmTaskId, updatedPMTask);
      final index = _pmTasks.indexWhere((pt) => pt.id == pmTaskId);
      if (index != -1) {
        _pmTasks[index] = updatedPMTask;
      }
      print(
        '▶️ UnifiedDataService: Resumed PM task ${pmTask.taskName} in Firestore',
      );

      return updatedPMTask;
    } catch (e) {
      print('❌ UnifiedDataService: Error resuming PM task: $e');
      rethrow;
    }
  }

  // ============================================================================
  // WORKFLOW OPERATIONS (DUAL-WRITE: Local + Firestore)
  // ============================================================================

  /// Load workflows from database
  Future<void> _loadWorkflows() async {
    _isWorkflowsLoading = true;
    try {
      _workflows = await SupabaseDatabaseService.instance.getAllWorkflows();
      print('📋 UnifiedDataService: Loaded ${_workflows.length} workflows from Firestore');
    } catch (e) {
      print('❌ UnifiedDataService: Error loading workflows: $e');
      _workflows = []; // Initialize empty list on error
    } finally {
      _isWorkflowsLoading = false;
    }
  }

  /// Create workflow in Firestore
  Future<String> createWorkflow(Workflow workflow) async {
    try {
      // Create directly in Firestore
      final workflowId = await SupabaseDatabaseService.instance.createWorkflow(workflow);
      _workflows.add(workflow);
      print('✅ UnifiedDataService: Created workflow ${workflow.title} in Firestore');

      return workflowId;
    } catch (e) {
      print('❌ UnifiedDataService: Error creating workflow: $e');
      rethrow;
    }
  }

  /// Update workflow (DUAL-WRITE: Local + Firestore)
  Future<void> updateWorkflow(Workflow workflow) async {
    try {
      // Update Firestore directly
      await SupabaseDatabaseService.instance
          .updateWorkflow(workflow.id, workflow);
      final index = _workflows.indexWhere((w) => w.id == workflow.id);
      if (index != -1) {
        _workflows[index] = workflow;
      }
      print('✅ UnifiedDataService: Updated workflow ${workflow.title} in Firestore');
    } catch (e) {
      print('❌ UnifiedDataService: Error updating workflow: $e');
      rethrow;
    }
  }

  /// Delete workflow (DUAL-WRITE: Local + Firestore)
  Future<void> deleteWorkflow(String workflowId) async {
    try {
      // Delete from Firestore
      await SupabaseDatabaseService.instance.deleteWorkflow(workflowId);
      _workflows.removeWhere((w) => w.id == workflowId);
      print('✅ UnifiedDataService: Deleted workflow $workflowId from Firestore');
    } catch (e) {
      print('❌ UnifiedDataService: Error deleting workflow: $e');
      rethrow;
    }
  }

  /// Get workflow by ID
  Workflow? getWorkflowById(String workflowId) {
    try {
      return _workflows.firstWhere((w) => w.id == workflowId);
    } catch (e) {
      return null;
    }
  }

  /// Get workflows by status
  List<Workflow> getWorkflowsByStatus(WorkflowStatus status) =>
      _workflows.where((w) => w.status == status).toList();

  /// Get workflows by type
  List<Workflow> getWorkflowsByType(WorkflowType type) =>
      _workflows.where((w) => w.type == type).toList();

  /// Get workflows created by user
  List<Workflow> getWorkflowsByCreator(String userId) =>
      _workflows.where((w) => w.createdByUserId == userId).toList();

  /// Get workflows assigned to user
  List<Workflow> getWorkflowsByAssignee(String userId) =>
      _workflows.where((w) => w.assignedToUserId == userId).toList();

  /// Get pending approvals for user
  List<Workflow> getPendingApprovalsForUser(String userId) => _workflows
      .where((w) =>
          w.status == WorkflowStatus.pendingApproval &&
          (w.approvers.contains(userId) || w.currentApprover == userId),)
      .toList();

  /// Get overdue workflows
  List<Workflow> getOverdueWorkflows() =>
      _workflows.where((w) => w.isOverdue).toList();

  /// Approve workflow (DUAL-WRITE: Local + Firestore)
  Future<void> approveWorkflow({
    required String workflowId,
    required String approverId,
    required String approverName,
    required String approverRole,
    String? comments,
  }) async {
    try {
      final workflow = _workflows.firstWhere((w) => w.id == workflowId);

      // Add to approval history
      final approvalHistory = List<Map<String, dynamic>>.from(
        workflow.approvalHistory,
      );
      approvalHistory.add({
        'approverId': approverId,
        'approverName': approverName,
        'approverRole': approverRole,
        'action': 'approve',
        'comments': comments,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Update workflow
      final updatedWorkflow = workflow.copyWith(
        approvalHistory: approvalHistory,
        status: WorkflowStatus.approved,
        updatedAt: DateTime.now(),
      );

      await updateWorkflow(updatedWorkflow);
      print('✅ UnifiedDataService: Approved workflow ${workflow.title}');
    } catch (e) {
      print('❌ UnifiedDataService: Error approving workflow: $e');
      rethrow;
    }
  }

  /// Reject workflow (DUAL-WRITE: Local + Firestore)
  Future<void> rejectWorkflow({
    required String workflowId,
    required String rejectorId,
    required String rejectorName,
    required String rejectorRole,
    required String reason,
  }) async {
    try {
      final workflow = _workflows.firstWhere((w) => w.id == workflowId);

      // Add to approval history
      final approvalHistory = List<Map<String, dynamic>>.from(
        workflow.approvalHistory,
      );
      approvalHistory.add({
        'approverId': rejectorId,
        'approverName': rejectorName,
        'approverRole': rejectorRole,
        'action': 'reject',
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Update workflow
      final updatedWorkflow = workflow.copyWith(
        approvalHistory: approvalHistory,
        status: WorkflowStatus.rejected,
        rejectionReason: reason,
        updatedAt: DateTime.now(),
      );

      await updateWorkflow(updatedWorkflow);
      print('✅ UnifiedDataService: Rejected workflow ${workflow.title}');
    } catch (e) {
      print('❌ UnifiedDataService: Error rejecting workflow: $e');
      rethrow;
    }
  }

  /// Complete workflow (DUAL-WRITE: Local + Firestore)
  Future<void> completeWorkflow({
    required String workflowId,
    required String completedBy,
    String? comments,
  }) async {
    try {
      final workflow = _workflows.firstWhere((w) => w.id == workflowId);

      // Update workflow
      final updatedWorkflow = workflow.copyWith(
        status: WorkflowStatus.completed,
        completedAt: DateTime.now(),
        completedBy: completedBy,
        updatedAt: DateTime.now(),
        actualDuration:
            workflow.createdAt.difference(DateTime.now()).inMinutes.abs(),
      );

      await updateWorkflow(updatedWorkflow);
      print('✅ UnifiedDataService: Completed workflow ${workflow.title}');
    } catch (e) {
      print('❌ UnifiedDataService: Error completing workflow: $e');
      rethrow;
    }
  }

  /// Cancel workflow (DUAL-WRITE: Local + Firestore)
  Future<void> cancelWorkflow({
    required String workflowId,
    required String cancelledBy,
    required String reason,
  }) async {
    try {
      final workflow = _workflows.firstWhere((w) => w.id == workflowId);

      // Update workflow
      final updatedWorkflow = workflow.copyWith(
        status: WorkflowStatus.cancelled,
        cancellationReason: reason,
        completedAt: DateTime.now(),
        completedBy: cancelledBy,
        updatedAt: DateTime.now(),
      );

      await updateWorkflow(updatedWorkflow);
      print('✅ UnifiedDataService: Cancelled workflow ${workflow.title}');
    } catch (e) {
      print('❌ UnifiedDataService: Error cancelling workflow: $e');
      rethrow;
    }
  }

  /// Escalate workflow (DUAL-WRITE: Local + Firestore)
  Future<void> escalateWorkflow({
    required String workflowId,
    required String escalatedBy,
    String? reason,
  }) async {
    try {
      final workflow = _workflows.firstWhere((w) => w.id == workflowId);

      // Update escalation path
      final escalationPath = List<String>.from(workflow.escalationPath);
      escalationPath.add(
        'Escalated by $escalatedBy at ${DateTime.now().toIso8601String()}${reason != null ? ": $reason" : ""}',
      );

      // Update workflow
      final updatedWorkflow = workflow.copyWith(
        status: WorkflowStatus.escalated,
        escalationPath: escalationPath,
        updatedAt: DateTime.now(),
      );

      await updateWorkflow(updatedWorkflow);
      print('✅ UnifiedDataService: Escalated workflow ${workflow.title}');
    } catch (e) {
      print('❌ UnifiedDataService: Error escalating workflow: $e');
      rethrow;
    }
  }

  /// Refresh workflows from database
  Future<void> refreshWorkflows() async {
    await _loadWorkflows();
  }
}
