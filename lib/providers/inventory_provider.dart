import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/inventory_item.dart';
import '../services/supabase_database_service.dart';
import 'unified_data_provider.dart';

class InventoryProvider with ChangeNotifier {
  List<InventoryItem> _inventoryItems = [];
  List<InventoryItem> _filteredInventoryItems = [];
  bool _isLoading = false;
  String _selectedFilter = 'all';
  UnifiedDataProvider? _unifiedDataProvider;

  List<InventoryItem> get inventoryItems => _filteredInventoryItems;
  bool get isLoading => _isLoading;
  String get selectedFilter => _selectedFilter;

  // Set the UnifiedDataProvider reference
  void setUnifiedDataProvider(UnifiedDataProvider provider) {
    _unifiedDataProvider = provider;
  }

  // Statistics
  int get totalItems => _inventoryItems.length;
  int get lowStockItems =>
      _inventoryItems.where((item) => item.isLowStock).length;
  int get outOfStockItems =>
      _inventoryItems.where((item) => item.isOutOfStock).length;
  int get overstockedItems =>
      _inventoryItems.where((item) => item.isOverstocked).length;
  int get activeItems => _inventoryItems.where((item) => item.isActive).length;
  int get inactiveItems =>
      _inventoryItems.where((item) => item.isInactive).length;

  double get totalValue => _inventoryItems.fold(
        0,
        (sum, item) => sum + (item.quantity * (item.cost ?? 0)),
      );

  Future<void> loadInventory() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Use UnifiedDataProvider if available (real-time Firestore data!)
      if (_unifiedDataProvider != null) {
        debugPrint(
            '📦 InventoryProvider: Loading from UnifiedDataProvider (Supabase)',);
        _inventoryItems = _unifiedDataProvider!.inventoryItems;
        debugPrint(
            'ðŸ"¦ InventoryProvider: Loaded ${_inventoryItems.length} items from Firestore',);
      } else {
        // Fallback to Firestore directly
        debugPrint(
            'ðŸ"¦ InventoryProvider: Loading from Firestore directly',);
        _inventoryItems =
            await SupabaseDatabaseService.instance.getAllInventoryItems();
      }
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading inventory: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> createInventoryItem({
    required String name,
    required String category,
    required double quantity,
    required String unit,
    String? description,
    String? sku,
    String? partNumber,
    String? manufacturer,
    String? supplier,
    double? cost,
    double? minimumStock,
    double? maximumStock,
    String? location,
    String? shelf,
    String? bin,
    String? imageUrl,
    String? warranty,
    String? notes,
  }) async {
    try {
      const uuid = Uuid();
      final now = DateTime.now();

      final item = InventoryItem(
        id: uuid.v4(),
        name: name,
        category: category,
        quantity: quantity,
        unit: unit,
        description: description,
        sku: sku,
        partNumber: partNumber,
        manufacturer: manufacturer,
        supplier: supplier,
        cost: cost,
        minimumStock: minimumStock,
        maximumStock: maximumStock,
        location: location,
        shelf: shelf,
        bin: bin,
        imageUrl: imageUrl,
        warranty: warranty,
        notes: notes,
        createdAt: now,
        updatedAt: now,
      );

      await SupabaseDatabaseService.instance.createInventoryItem(item);
      _inventoryItems.add(item);
      _applyFilters();
      notifyListeners();

      return item.id;
    } catch (e) {
      debugPrint('Error creating inventory item: $e');
      rethrow;
    }
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    try {
      final updatedItem = item.copyWith(
        updatedAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      await SupabaseDatabaseService.instance.updateInventoryItem(updatedItem.id, updatedItem);

      final index = _inventoryItems.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _inventoryItems[index] = updatedItem;
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating inventory item: $e');
      rethrow;
    }
  }

  Future<void> deleteInventoryItem(String itemId) async {
    try {
      await SupabaseDatabaseService.instance.deleteInventoryItem(itemId);
      _inventoryItems.removeWhere((item) => item.id == itemId);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting inventory item: $e');
      rethrow;
    }
  }

  Future<void> adjustInventory({
    required String itemId,
    required double quantity,
    required String type,
    String? notes,
    String? reference,
  }) async {
    try {
      final item = _inventoryItems.firstWhere((i) => i.id == itemId);
      var newQuantity = item.quantity;

      switch (type) {
        case 'in':
          newQuantity += quantity;
          break;
        case 'out':
          newQuantity -= quantity;
          break;
        case 'adjustment':
          newQuantity = quantity;
          break;
      }

      final updatedItem = item.copyWith(
        quantity: newQuantity,
        updatedAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      await SupabaseDatabaseService.instance.updateInventoryItem(updatedItem.id, updatedItem);

      // Note: InventoryTransaction methods can be added to Firestore if needed in the future
      // This functionality needs to be implemented if required
      // Transaction records can be added to Firestore if needed in the future

      final index = _inventoryItems.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        _inventoryItems[index] = updatedItem;
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error adjusting inventory: $e');
      rethrow;
    }
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    switch (_selectedFilter) {
      case 'lowStock':
        _filteredInventoryItems =
            _inventoryItems.where((item) => item.isLowStock).toList();
        break;
      case 'outOfStock':
        _filteredInventoryItems =
            _inventoryItems.where((item) => item.isOutOfStock).toList();
        break;
      case 'overstocked':
        _filteredInventoryItems =
            _inventoryItems.where((item) => item.isOverstocked).toList();
        break;
      case 'active':
        _filteredInventoryItems =
            _inventoryItems.where((item) => item.isActive).toList();
        break;
      case 'inactive':
        _filteredInventoryItems =
            _inventoryItems.where((item) => item.isInactive).toList();
        break;
      default:
        _filteredInventoryItems = List.from(_inventoryItems);
    }
  }

  List<InventoryItem> searchInventory(String query) {
    if (query.isEmpty) return _inventoryItems;

    final lowerQuery = query.toLowerCase();
    return _inventoryItems
        .where(
          (item) =>
              item.name.toLowerCase().contains(lowerQuery) ||
              item.category.toLowerCase().contains(lowerQuery) ||
              (item.sku?.toLowerCase().contains(lowerQuery) ?? false) ||
              (item.partNumber?.toLowerCase().contains(lowerQuery) ?? false) ||
              (item.manufacturer?.toLowerCase().contains(lowerQuery) ??
                  false) ||
              (item.supplier?.toLowerCase().contains(lowerQuery) ?? false),
        )
        .toList();
  }

  List<InventoryItem> getLowStockItems() =>
      _inventoryItems.where((item) => item.isLowStock).toList();

  List<InventoryItem> getOutOfStockItems() =>
      _inventoryItems.where((item) => item.isOutOfStock).toList();

  List<InventoryItem> getItemsByCategory(String category) =>
      _inventoryItems.where((item) => item.category == category).toList();

  Map<String, int> getCategoryStats() {
    final stats = <String, int>{};
    for (final item in _inventoryItems) {
      stats[item.category] = (stats[item.category] ?? 0) + 1;
    }
    return stats;
  }
}
