// Pagination Helper for Large Lists
//
// Provides efficient pagination for work orders, PM tasks, and other large datasets.
// Improves performance and user experience when dealing with hundreds or thousands of items.
//
// Usage:
// ```dart
// final paginator = PaginationHelper<WorkOrder>(
//   items: allWorkOrders,
//   itemsPerPage: 20,
// );
//
// // Get current page
// final currentPage = paginator.getCurrentPage();
//
// // Navigate
// paginator.nextPage();
// paginator.previousPage();
// paginator.goToPage(5);
// ```

import 'package:flutter/foundation.dart';

/// Generic pagination helper for any list type
class PaginationHelper<T> extends ChangeNotifier {
  PaginationHelper({
    required List<T> items,
    this.itemsPerPage = 20,
    bool Function(T item, String query)? filterFunction,
  })  : _allItems = items,
        _filterFunction = filterFunction;

  /// All items to paginate
  List<T> _allItems;

  /// Number of items per page
  final int itemsPerPage;

  /// Current page number (0-indexed)
  int _currentPage = 0;

  /// Search/filter function
  final bool Function(T item, String query)? _filterFunction;

  /// Current search query
  String _searchQuery = '';

  /// Update the items list
  void updateItems(List<T> items) {
    _allItems = items;
    _currentPage = 0; // Reset to first page
    notifyListeners();
  }

  /// Get filtered items based on search query
  List<T> get _filteredItems {
    if (_searchQuery.isEmpty || _filterFunction == null) {
      return _allItems;
    }
    return _allItems
        .where((item) => _filterFunction!(item, _searchQuery))
        .toList();
  }

  /// Get total number of pages
  int get totalPages {
    final filtered = _filteredItems;
    if (filtered.isEmpty) return 1;
    return (filtered.length / itemsPerPage).ceil();
  }

  /// Get current page number (1-indexed for display)
  int get currentPageNumber => _currentPage + 1;

  /// Get current page items
  List<T> getCurrentPage() {
    final filtered = _filteredItems;
    if (filtered.isEmpty) return [];

    final startIndex = _currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, filtered.length);

    if (startIndex >= filtered.length) {
      _currentPage = 0; // Reset if out of bounds
      return getCurrentPage();
    }

    return filtered.sublist(startIndex, endIndex);
  }

  /// Go to next page
  bool nextPage() {
    if (_currentPage < totalPages - 1) {
      _currentPage++;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Go to previous page
  bool previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Go to first page
  void firstPage() {
    if (_currentPage != 0) {
      _currentPage = 0;
      notifyListeners();
    }
  }

  /// Go to last page
  void lastPage() {
    final lastPage = totalPages - 1;
    if (_currentPage != lastPage) {
      _currentPage = lastPage;
      notifyListeners();
    }
  }

  /// Go to specific page (1-indexed)
  bool goToPage(int page) {
    final zeroIndexedPage = page - 1;
    if (zeroIndexedPage >= 0 && zeroIndexedPage < totalPages) {
      _currentPage = zeroIndexedPage;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Check if has next page
  bool get hasNext => _currentPage < totalPages - 1;

  /// Check if has previous page
  bool get hasPrevious => _currentPage > 0;

  /// Get total number of items
  int get totalItems => _filteredItems.length;

  /// Get start index of current page (1-indexed for display)
  int get startIndex => (_currentPage * itemsPerPage) + 1;

  /// Get end index of current page (1-indexed for display)
  int get endIndex {
    final filtered = _filteredItems;
    final calculated = (_currentPage + 1) * itemsPerPage;
    return calculated.clamp(0, filtered.length);
  }

  /// Set search query and filter items
  void search(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _currentPage = 0; // Reset to first page on new search
      notifyListeners();
    }
  }

  /// Clear search
  void clearSearch() {
    if (_searchQuery.isNotEmpty) {
      _searchQuery = '';
      _currentPage = 0;
      notifyListeners();
    }
  }

  /// Get current search query
  String get searchQuery => _searchQuery;

  /// Check if currently searching
  bool get isSearching => _searchQuery.isNotEmpty;

  /// Get page info string (e.g., "1-20 of 150")
  String getPageInfo() {
    if (totalItems == 0) return '0 items';
    return '$startIndex-$endIndex of $totalItems';
  }

  /// Reset pagination
  void reset() {
    _currentPage = 0;
    _searchQuery = '';
    notifyListeners();
  }
}

/// Pagination display helper
class PaginationDisplayHelper {
  PaginationDisplayHelper._();

  /// Get page numbers to display (with ellipsis for large page counts)
  ///
  /// Example: [1, 2, 3, ..., 10] or [1, ..., 5, 6, 7, ..., 10]
  static List<dynamic> getPageNumbers(
    int currentPage,
    int totalPages, {
    int maxVisible = 7,
  }) {
    if (totalPages <= maxVisible) {
      return List.generate(totalPages, (i) => i + 1);
    }

    final pages = <dynamic>[];

    // Always show first page
    pages.add(1);

    // Calculate range around current page
    final start = (currentPage - 1).clamp(2, totalPages - maxVisible + 2);
    final end = (currentPage + 1).clamp(maxVisible - 1, totalPages - 1);

    // Add ellipsis if needed
    if (start > 2) {
      pages.add('...');
    }

    // Add middle pages
    for (var i = start; i <= end; i++) {
      pages.add(i);
    }

    // Add ellipsis if needed
    if (end < totalPages - 1) {
      pages.add('...');
    }

    // Always show last page
    if (totalPages > 1) {
      pages.add(totalPages);
    }

    return pages;
  }
}

/// Infinite scroll helper
class InfiniteScrollHelper<T> {
  InfiniteScrollHelper({
    required List<T> items,
    this.itemsPerLoad = 20,
    int initialLoad = 20,
  })  : _allItems = items,
        _loadedCount = initialLoad;

  /// All items
  final List<T> _allItems;

  /// Items per load
  final int itemsPerLoad;

  /// Currently loaded items count
  int _loadedCount;

  /// Get currently loaded items
  List<T> getLoadedItems() {
    final endIndex = _loadedCount.clamp(0, _allItems.length);
    return _allItems.sublist(0, endIndex);
  }

  /// Load more items
  bool loadMore() {
    if (hasMore) {
      _loadedCount += itemsPerLoad;
      return true;
    }
    return false;
  }

  /// Check if has more items to load
  bool get hasMore => _loadedCount < _allItems.length;

  /// Get total items count
  int get totalItems => _allItems.length;

  /// Get loaded items count
  int get loadedCount => _loadedCount.clamp(0, _allItems.length);

  /// Get remaining items count
  int get remainingCount => (totalItems - loadedCount).clamp(0, totalItems);

  /// Reset to initial load
  void reset({int? initialLoad}) {
    _loadedCount = initialLoad ?? itemsPerLoad;
  }
}
