# 📄 Pagination Guide - Q-AUTO CMMS

## Overview

Efficient pagination system for handling large lists of work orders, PM tasks, inventory items, and other data.

---

## ✅ **What's Implemented**

### **Pagination Helper (`lib/utils/pagination_helper.dart`)**

- ✅ Generic pagination for any list type
- ✅ Configurable items per page
- ✅ Search/filter integration
- ✅ Navigation controls (next, previous, first, last, goto)
- ✅ Page information (1-20 of 150)
- ✅ Infinite scroll support

### **Pagination Widgets (`lib/widgets/pagination_widget.dart`)**

- ✅ `PaginationControls` - Full navigation UI
- ✅ `PaginationInfo` - Compact page info display
- ✅ `PaginationBar` - Complete pagination bar
- ✅ `LoadMoreButton` - Infinite scroll button

---

## 🎯 **Usage Examples**

### **1. Basic Pagination**

```dart
import 'package:qauto_cmms/utils/pagination_helper.dart';
import 'package:qauto_cmms/widgets/pagination_widget.dart';

class WorkOrderListScreen extends StatefulWidget {
  @override
  State<WorkOrderListScreen> createState() => _WorkOrderListScreenState();
}

class _WorkOrderListScreenState extends State<WorkOrderListScreen> {
  late PaginationHelper<WorkOrder> _paginator;

  @override
  void initState() {
    super.initState();
    _paginator = PaginationHelper<WorkOrder>(
      items: allWorkOrders,
      itemsPerPage: 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // List of current page items
        Expanded(
          child: ListenableBuilder(
            listenable: _paginator,
            builder: (context, _) {
              final currentPage = _paginator.getCurrentPage();
              return ListView.builder(
                itemCount: currentPage.length,
                itemBuilder: (context, index) {
                  return WorkOrderCard(workOrder: currentPage[index]);
                },
              );
            },
          ),
        ),

        // Pagination controls
        PaginationBar(paginationHelper: _paginator),
      ],
    );
  }

  @override
  void dispose() {
    _paginator.dispose();
    super.dispose();
  }
}
```

### **2. Pagination with Search**

```dart
_paginator = PaginationHelper<WorkOrder>(
  items: allWorkOrders,
  itemsPerPage: 20,
  filterFunction: (workOrder, query) {
    return workOrder.title.toLowerCase().contains(query.toLowerCase()) ||
           workOrder.id.toLowerCase().contains(query.toLowerCase());
  },
);

// In your search bar
TextField(
  onChanged: (query) => _paginator.search(query),
  decoration: InputDecoration(
    hintText: 'Search work orders...',
    suffixIcon: IconButton(
      icon: Icon(Icons.clear),
      onPressed: () => _paginator.clearSearch(),
    ),
  ),
);
```

### **3. Infinite Scroll**

```dart
import 'package:qauto_cmms/utils/pagination_helper.dart';

class InfiniteScrollListScreen extends StatefulWidget {
  @override
  State<InfiniteScrollListScreen> createState() => _InfiniteScrollListScreenState();
}

class _InfiniteScrollListScreenState extends State<InfiniteScrollListScreen> {
  late InfiniteScrollHelper<WorkOrder> _scrollHelper;

  @override
  void initState() {
    super.initState();
    _scrollHelper = InfiniteScrollHelper<WorkOrder>(
      items: allWorkOrders,
      itemsPerLoad: 20,
      initialLoad: 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loadedItems = _scrollHelper.getLoadedItems();

    return ListView.builder(
      itemCount: loadedItems.length + 1, // +1 for load more button
      itemBuilder: (context, index) {
        if (index == loadedItems.length) {
          return LoadMoreButton(
            infiniteScrollHelper: _scrollHelper,
            onLoadMore: () {
              setState(() {
                _scrollHelper.loadMore();
              });
            },
          );
        }

        return WorkOrderCard(workOrder: loadedItems[index]);
      },
    );
  }
}
```

### **4. Custom Pagination Controls**

```dart
// Just the page info
PaginationInfo(paginationHelper: _paginator);

// Just the controls
PaginationControls(
  paginationHelper: _paginator,
  activeColor: Colors.blue,
  inactiveColor: Colors.grey,
);

// Complete bar with both
PaginationBar(
  paginationHelper: _paginator,
  showInfo: true,
  showControls: true,
  activeColor: Theme.of(context).primaryColor,
);
```

---

## 📋 **PaginationHelper API**

### **Properties**

```dart
// Getters
int get totalPages              // Total number of pages
int get currentPageNumber       // Current page (1-indexed)
int get totalItems              // Total items count
int get startIndex              // Start index of current page (1-indexed)
int get endIndex                // End index of current page (1-indexed)
bool get hasNext                // Has next page
bool get hasPrevious            // Has previous page
String get searchQuery          // Current search query
bool get isSearching            // Is currently searching

// Methods
List<T> getCurrentPage()        // Get current page items
String getPageInfo()            // Get "1-20 of 150" format
```

### **Navigation Methods**

```dart
bool nextPage()                 // Go to next page
bool previousPage()             // Go to previous page
void firstPage()                // Go to first page
void lastPage()                 // Go to last page
bool goToPage(int page)         // Go to specific page (1-indexed)
```

### **Search Methods**

```dart
void search(String query)       // Search and filter items
void clearSearch()              // Clear search query
void reset()                    // Reset to first page and clear search
```

### **Update Methods**

```dart
void updateItems(List<T> items) // Update the items list
```

---

## 🎨 **Customization**

### **Change Items Per Page**

```dart
// Create new paginator with different items per page
_paginator = PaginationHelper<WorkOrder>(
  items: allWorkOrders,
  itemsPerPage: 50, // Change from default 20
);

// With dropdown selector
ItemsPerPageSelector(
  paginationHelper: _paginator,
  options: [10, 20, 50, 100],
  onChanged: (newCount) {
    setState(() {
      _paginator = PaginationHelper<WorkOrder>(
        items: allWorkOrders,
        itemsPerPage: newCount,
      );
    });
  },
);
```

### **Custom Colors**

```dart
PaginationControls(
  paginationHelper: _paginator,
  activeColor: Colors.deepPurple,
  inactiveColor: Colors.grey.shade400,
  buttonSize: 48,
);
```

### **Mobile-Friendly Controls**

```dart
// Simplified controls for mobile
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    IconButton(
      icon: Icon(Icons.chevron_left),
      onPressed: _paginator.hasPrevious
          ? () => _paginator.previousPage()
          : null,
    ),
    Text(_paginator.getPageInfo()),
    IconButton(
      icon: Icon(Icons.chevron_right),
      onPressed: _paginator.hasNext
          ? () => _paginator.nextPage()
          : null,
    ),
  ],
);
```

---

## 🚀 **Implementation Examples**

### **Work Orders List with Pagination**

```dart
class PaginatedWorkOrderList extends StatefulWidget {
  final List<WorkOrder> workOrders;

  const PaginatedWorkOrderList({
    Key? key,
    required this.workOrders,
  }) : super(key: key);

  @override
  State<PaginatedWorkOrderList> createState() => _PaginatedWorkOrderListState();
}

class _PaginatedWorkOrderListState extends State<PaginatedWorkOrderList> {
  late PaginationHelper<WorkOrder> _paginator;

  @override
  void initState() {
    super.initState();
    _paginator = PaginationHelper<WorkOrder>(
      items: widget.workOrders,
      itemsPerPage: 20,
      filterFunction: (workOrder, query) {
        return workOrder.title.toLowerCase().contains(query.toLowerCase()) ||
               workOrder.id.toLowerCase().contains(query.toLowerCase()) ||
               workOrder.asset?.name.toLowerCase().contains(query.toLowerCase()) == true;
      },
    );
  }

  @override
  void didUpdateWidget(PaginatedWorkOrderList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.workOrders != oldWidget.workOrders) {
      _paginator.updateItems(widget.workOrders);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search work orders...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: _paginator.isSearching
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () => _paginator.clearSearch(),
                    )
                  : null,
            ),
            onChanged: (query) => _paginator.search(query),
          ),
        ),

        // List
        Expanded(
          child: ListenableBuilder(
            listenable: _paginator,
            builder: (context, _) {
              final currentPage = _paginator.getCurrentPage();

              if (currentPage.isEmpty) {
                return Center(
                  child: Text('No work orders found'),
                );
              }

              return ListView.builder(
                itemCount: currentPage.length,
                itemBuilder: (context, index) {
                  return WorkOrderCard(
                    workOrder: currentPage[index],
                  );
                },
              );
            },
          ),
        ),

        // Pagination bar
        PaginationBar(paginationHelper: _paginator),
      ],
    );
  }

  @override
  void dispose() {
    _paginator.dispose();
    super.dispose();
  }
}
```

### **PM Tasks with Infinite Scroll**

```dart
class InfiniteScrollPMTasks extends StatefulWidget {
  final List<PMTask> pmTasks;

  const InfiniteScrollPMTasks({
    Key? key,
    required this.pmTasks,
  }) : super(key: key);

  @override
  State<InfiniteScrollPMTasks> createState() => _InfiniteScrollPMTasksState();
}

class _InfiniteScrollPMTasksState extends State<InfiniteScrollPMTasks> {
  late InfiniteScrollHelper<PMTask> _scrollHelper;

  @override
  void initState() {
    super.initState();
    _scrollHelper = InfiniteScrollHelper<PMTask>(
      items: widget.pmTasks,
      itemsPerLoad: 15,
      initialLoad: 15,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loadedItems = _scrollHelper.getLoadedItems();

    return ListView.builder(
      itemCount: loadedItems.length + (_scrollHelper.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == loadedItems.length) {
          return LoadMoreButton(
            infiniteScrollHelper: _scrollHelper,
            onLoadMore: () {
              setState(() {
                _scrollHelper.loadMore();
              });
            },
          );
        }

        return PMTaskCard(pmTask: loadedItems[index]);
      },
    );
  }
}
```

---

## 📱 **Mobile Optimization**

### **Responsive Pagination**

```dart
// Desktop: Full controls
// Mobile: Simplified controls

final isMobile = MediaQuery.of(context).size.width < 600;

if (isMobile) {
  // Mobile: Simple prev/next
  Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      TextButton.icon(
        icon: Icon(Icons.chevron_left),
        label: Text('Previous'),
        onPressed: _paginator.hasPrevious
            ? () => _paginator.previousPage()
            : null,
      ),
      Text(_paginator.getPageInfo()),
      TextButton.icon(
        icon: Icon(Icons.chevron_right),
        label: Text('Next'),
        onPressed: _paginator.hasNext
            ? () => _paginator.nextPage()
            : null,
      ),
    ],
  );
} else {
  // Desktop: Full pagination controls
  PaginationBar(paginationHelper: _paginator);
}
```

---

## 🧪 **Testing**

```dart
test('Pagination navigation', () {
  final items = List.generate(100, (i) => i);
  final paginator = PaginationHelper<int>(
    items: items,
    itemsPerPage: 10,
  );

  // Initial state
  expect(paginator.currentPageNumber, 1);
  expect(paginator.totalPages, 10);
  expect(paginator.getCurrentPage().length, 10);

  // Next page
  expect(paginator.nextPage(), true);
  expect(paginator.currentPageNumber, 2);

  // Last page
  paginator.lastPage();
  expect(paginator.currentPageNumber, 10);
  expect(paginator.hasNext, false);

  // First page
  paginator.firstPage();
  expect(paginator.currentPageNumber, 1);
  expect(paginator.hasPrevious, false);
});

test('Pagination with search', () {
  final items = ['Apple', 'Banana', 'Cherry', 'Date'];
  final paginator = PaginationHelper<String>(
    items: items,
    itemsPerPage: 2,
    filterFunction: (item, query) =>
        item.toLowerCase().contains(query.toLowerCase()),
  );

  // Search
  paginator.search('a');
  expect(paginator.totalItems, 3); // Apple, Banana, Date
  expect(paginator.totalPages, 2);

  // Clear search
  paginator.clearSearch();
  expect(paginator.totalItems, 4);
});
```

---

## ✅ **Best Practices**

1. **Choose appropriate page size:**

   - Mobile: 10-20 items
   - Tablet: 20-30 items
   - Desktop: 20-50 items

2. **Use search for large lists:**

   - Always provide search/filter for 100+ items
   - Reset to first page on new search

3. **Show page info:**

   - Always display "1-20 of 150" info
   - Helps users understand data size

4. **Mobile considerations:**

   - Use infinite scroll for mobile
   - Simplified controls for small screens
   - Load more button instead of page numbers

5. **Performance:**
   - Paginate lists with 50+ items
   - Use virtual scrolling for very large lists (1000+)
   - Implement search/filter for better UX

---

## 📊 **When to Use**

### **Use Pagination When:**

- ✅ List has 50+ items
- ✅ Desktop/tablet interface
- ✅ User needs to jump to specific pages
- ✅ Need precise navigation

### **Use Infinite Scroll When:**

- ✅ Mobile interface
- ✅ Social media-style feeds
- ✅ Chronological data
- ✅ Linear browsing pattern

---

## ✅ **Status**

- ✅ Pagination helper implemented
- ✅ Pagination widgets ready
- ✅ Search/filter integration
- ✅ Infinite scroll support
- ✅ Mobile responsive
- ✅ Production-ready

---

**Date:** 2025-01-28  
**Status:** ✅ **COMPLETE**  
**Impact:** **HIGH** (Performance for large lists)  
**Risk:** **ZERO** (Opt-in feature)

---

**📄 Your lists can now handle thousands of items efficiently!**



## Overview

Efficient pagination system for handling large lists of work orders, PM tasks, inventory items, and other data.

---

## ✅ **What's Implemented**

### **Pagination Helper (`lib/utils/pagination_helper.dart`)**

- ✅ Generic pagination for any list type
- ✅ Configurable items per page
- ✅ Search/filter integration
- ✅ Navigation controls (next, previous, first, last, goto)
- ✅ Page information (1-20 of 150)
- ✅ Infinite scroll support

### **Pagination Widgets (`lib/widgets/pagination_widget.dart`)**

- ✅ `PaginationControls` - Full navigation UI
- ✅ `PaginationInfo` - Compact page info display
- ✅ `PaginationBar` - Complete pagination bar
- ✅ `LoadMoreButton` - Infinite scroll button

---

## 🎯 **Usage Examples**

### **1. Basic Pagination**

```dart
import 'package:qauto_cmms/utils/pagination_helper.dart';
import 'package:qauto_cmms/widgets/pagination_widget.dart';

class WorkOrderListScreen extends StatefulWidget {
  @override
  State<WorkOrderListScreen> createState() => _WorkOrderListScreenState();
}

class _WorkOrderListScreenState extends State<WorkOrderListScreen> {
  late PaginationHelper<WorkOrder> _paginator;

  @override
  void initState() {
    super.initState();
    _paginator = PaginationHelper<WorkOrder>(
      items: allWorkOrders,
      itemsPerPage: 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // List of current page items
        Expanded(
          child: ListenableBuilder(
            listenable: _paginator,
            builder: (context, _) {
              final currentPage = _paginator.getCurrentPage();
              return ListView.builder(
                itemCount: currentPage.length,
                itemBuilder: (context, index) {
                  return WorkOrderCard(workOrder: currentPage[index]);
                },
              );
            },
          ),
        ),

        // Pagination controls
        PaginationBar(paginationHelper: _paginator),
      ],
    );
  }

  @override
  void dispose() {
    _paginator.dispose();
    super.dispose();
  }
}
```

### **2. Pagination with Search**

```dart
_paginator = PaginationHelper<WorkOrder>(
  items: allWorkOrders,
  itemsPerPage: 20,
  filterFunction: (workOrder, query) {
    return workOrder.title.toLowerCase().contains(query.toLowerCase()) ||
           workOrder.id.toLowerCase().contains(query.toLowerCase());
  },
);

// In your search bar
TextField(
  onChanged: (query) => _paginator.search(query),
  decoration: InputDecoration(
    hintText: 'Search work orders...',
    suffixIcon: IconButton(
      icon: Icon(Icons.clear),
      onPressed: () => _paginator.clearSearch(),
    ),
  ),
);
```

### **3. Infinite Scroll**

```dart
import 'package:qauto_cmms/utils/pagination_helper.dart';

class InfiniteScrollListScreen extends StatefulWidget {
  @override
  State<InfiniteScrollListScreen> createState() => _InfiniteScrollListScreenState();
}

class _InfiniteScrollListScreenState extends State<InfiniteScrollListScreen> {
  late InfiniteScrollHelper<WorkOrder> _scrollHelper;

  @override
  void initState() {
    super.initState();
    _scrollHelper = InfiniteScrollHelper<WorkOrder>(
      items: allWorkOrders,
      itemsPerLoad: 20,
      initialLoad: 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loadedItems = _scrollHelper.getLoadedItems();

    return ListView.builder(
      itemCount: loadedItems.length + 1, // +1 for load more button
      itemBuilder: (context, index) {
        if (index == loadedItems.length) {
          return LoadMoreButton(
            infiniteScrollHelper: _scrollHelper,
            onLoadMore: () {
              setState(() {
                _scrollHelper.loadMore();
              });
            },
          );
        }

        return WorkOrderCard(workOrder: loadedItems[index]);
      },
    );
  }
}
```

### **4. Custom Pagination Controls**

```dart
// Just the page info
PaginationInfo(paginationHelper: _paginator);

// Just the controls
PaginationControls(
  paginationHelper: _paginator,
  activeColor: Colors.blue,
  inactiveColor: Colors.grey,
);

// Complete bar with both
PaginationBar(
  paginationHelper: _paginator,
  showInfo: true,
  showControls: true,
  activeColor: Theme.of(context).primaryColor,
);
```

---

## 📋 **PaginationHelper API**

### **Properties**

```dart
// Getters
int get totalPages              // Total number of pages
int get currentPageNumber       // Current page (1-indexed)
int get totalItems              // Total items count
int get startIndex              // Start index of current page (1-indexed)
int get endIndex                // End index of current page (1-indexed)
bool get hasNext                // Has next page
bool get hasPrevious            // Has previous page
String get searchQuery          // Current search query
bool get isSearching            // Is currently searching

// Methods
List<T> getCurrentPage()        // Get current page items
String getPageInfo()            // Get "1-20 of 150" format
```

### **Navigation Methods**

```dart
bool nextPage()                 // Go to next page
bool previousPage()             // Go to previous page
void firstPage()                // Go to first page
void lastPage()                 // Go to last page
bool goToPage(int page)         // Go to specific page (1-indexed)
```

### **Search Methods**

```dart
void search(String query)       // Search and filter items
void clearSearch()              // Clear search query
void reset()                    // Reset to first page and clear search
```

### **Update Methods**

```dart
void updateItems(List<T> items) // Update the items list
```

---

## 🎨 **Customization**

### **Change Items Per Page**

```dart
// Create new paginator with different items per page
_paginator = PaginationHelper<WorkOrder>(
  items: allWorkOrders,
  itemsPerPage: 50, // Change from default 20
);

// With dropdown selector
ItemsPerPageSelector(
  paginationHelper: _paginator,
  options: [10, 20, 50, 100],
  onChanged: (newCount) {
    setState(() {
      _paginator = PaginationHelper<WorkOrder>(
        items: allWorkOrders,
        itemsPerPage: newCount,
      );
    });
  },
);
```

### **Custom Colors**

```dart
PaginationControls(
  paginationHelper: _paginator,
  activeColor: Colors.deepPurple,
  inactiveColor: Colors.grey.shade400,
  buttonSize: 48,
);
```

### **Mobile-Friendly Controls**

```dart
// Simplified controls for mobile
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    IconButton(
      icon: Icon(Icons.chevron_left),
      onPressed: _paginator.hasPrevious
          ? () => _paginator.previousPage()
          : null,
    ),
    Text(_paginator.getPageInfo()),
    IconButton(
      icon: Icon(Icons.chevron_right),
      onPressed: _paginator.hasNext
          ? () => _paginator.nextPage()
          : null,
    ),
  ],
);
```

---

## 🚀 **Implementation Examples**

### **Work Orders List with Pagination**

```dart
class PaginatedWorkOrderList extends StatefulWidget {
  final List<WorkOrder> workOrders;

  const PaginatedWorkOrderList({
    Key? key,
    required this.workOrders,
  }) : super(key: key);

  @override
  State<PaginatedWorkOrderList> createState() => _PaginatedWorkOrderListState();
}

class _PaginatedWorkOrderListState extends State<PaginatedWorkOrderList> {
  late PaginationHelper<WorkOrder> _paginator;

  @override
  void initState() {
    super.initState();
    _paginator = PaginationHelper<WorkOrder>(
      items: widget.workOrders,
      itemsPerPage: 20,
      filterFunction: (workOrder, query) {
        return workOrder.title.toLowerCase().contains(query.toLowerCase()) ||
               workOrder.id.toLowerCase().contains(query.toLowerCase()) ||
               workOrder.asset?.name.toLowerCase().contains(query.toLowerCase()) == true;
      },
    );
  }

  @override
  void didUpdateWidget(PaginatedWorkOrderList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.workOrders != oldWidget.workOrders) {
      _paginator.updateItems(widget.workOrders);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search work orders...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: _paginator.isSearching
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () => _paginator.clearSearch(),
                    )
                  : null,
            ),
            onChanged: (query) => _paginator.search(query),
          ),
        ),

        // List
        Expanded(
          child: ListenableBuilder(
            listenable: _paginator,
            builder: (context, _) {
              final currentPage = _paginator.getCurrentPage();

              if (currentPage.isEmpty) {
                return Center(
                  child: Text('No work orders found'),
                );
              }

              return ListView.builder(
                itemCount: currentPage.length,
                itemBuilder: (context, index) {
                  return WorkOrderCard(
                    workOrder: currentPage[index],
                  );
                },
              );
            },
          ),
        ),

        // Pagination bar
        PaginationBar(paginationHelper: _paginator),
      ],
    );
  }

  @override
  void dispose() {
    _paginator.dispose();
    super.dispose();
  }
}
```

### **PM Tasks with Infinite Scroll**

```dart
class InfiniteScrollPMTasks extends StatefulWidget {
  final List<PMTask> pmTasks;

  const InfiniteScrollPMTasks({
    Key? key,
    required this.pmTasks,
  }) : super(key: key);

  @override
  State<InfiniteScrollPMTasks> createState() => _InfiniteScrollPMTasksState();
}

class _InfiniteScrollPMTasksState extends State<InfiniteScrollPMTasks> {
  late InfiniteScrollHelper<PMTask> _scrollHelper;

  @override
  void initState() {
    super.initState();
    _scrollHelper = InfiniteScrollHelper<PMTask>(
      items: widget.pmTasks,
      itemsPerLoad: 15,
      initialLoad: 15,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loadedItems = _scrollHelper.getLoadedItems();

    return ListView.builder(
      itemCount: loadedItems.length + (_scrollHelper.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == loadedItems.length) {
          return LoadMoreButton(
            infiniteScrollHelper: _scrollHelper,
            onLoadMore: () {
              setState(() {
                _scrollHelper.loadMore();
              });
            },
          );
        }

        return PMTaskCard(pmTask: loadedItems[index]);
      },
    );
  }
}
```

---

## 📱 **Mobile Optimization**

### **Responsive Pagination**

```dart
// Desktop: Full controls
// Mobile: Simplified controls

final isMobile = MediaQuery.of(context).size.width < 600;

if (isMobile) {
  // Mobile: Simple prev/next
  Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      TextButton.icon(
        icon: Icon(Icons.chevron_left),
        label: Text('Previous'),
        onPressed: _paginator.hasPrevious
            ? () => _paginator.previousPage()
            : null,
      ),
      Text(_paginator.getPageInfo()),
      TextButton.icon(
        icon: Icon(Icons.chevron_right),
        label: Text('Next'),
        onPressed: _paginator.hasNext
            ? () => _paginator.nextPage()
            : null,
      ),
    ],
  );
} else {
  // Desktop: Full pagination controls
  PaginationBar(paginationHelper: _paginator);
}
```

---

## 🧪 **Testing**

```dart
test('Pagination navigation', () {
  final items = List.generate(100, (i) => i);
  final paginator = PaginationHelper<int>(
    items: items,
    itemsPerPage: 10,
  );

  // Initial state
  expect(paginator.currentPageNumber, 1);
  expect(paginator.totalPages, 10);
  expect(paginator.getCurrentPage().length, 10);

  // Next page
  expect(paginator.nextPage(), true);
  expect(paginator.currentPageNumber, 2);

  // Last page
  paginator.lastPage();
  expect(paginator.currentPageNumber, 10);
  expect(paginator.hasNext, false);

  // First page
  paginator.firstPage();
  expect(paginator.currentPageNumber, 1);
  expect(paginator.hasPrevious, false);
});

test('Pagination with search', () {
  final items = ['Apple', 'Banana', 'Cherry', 'Date'];
  final paginator = PaginationHelper<String>(
    items: items,
    itemsPerPage: 2,
    filterFunction: (item, query) =>
        item.toLowerCase().contains(query.toLowerCase()),
  );

  // Search
  paginator.search('a');
  expect(paginator.totalItems, 3); // Apple, Banana, Date
  expect(paginator.totalPages, 2);

  // Clear search
  paginator.clearSearch();
  expect(paginator.totalItems, 4);
});
```

---

## ✅ **Best Practices**

1. **Choose appropriate page size:**

   - Mobile: 10-20 items
   - Tablet: 20-30 items
   - Desktop: 20-50 items

2. **Use search for large lists:**

   - Always provide search/filter for 100+ items
   - Reset to first page on new search

3. **Show page info:**

   - Always display "1-20 of 150" info
   - Helps users understand data size

4. **Mobile considerations:**

   - Use infinite scroll for mobile
   - Simplified controls for small screens
   - Load more button instead of page numbers

5. **Performance:**
   - Paginate lists with 50+ items
   - Use virtual scrolling for very large lists (1000+)
   - Implement search/filter for better UX

---

## 📊 **When to Use**

### **Use Pagination When:**

- ✅ List has 50+ items
- ✅ Desktop/tablet interface
- ✅ User needs to jump to specific pages
- ✅ Need precise navigation

### **Use Infinite Scroll When:**

- ✅ Mobile interface
- ✅ Social media-style feeds
- ✅ Chronological data
- ✅ Linear browsing pattern

---

## ✅ **Status**

- ✅ Pagination helper implemented
- ✅ Pagination widgets ready
- ✅ Search/filter integration
- ✅ Infinite scroll support
- ✅ Mobile responsive
- ✅ Production-ready

---

**Date:** 2025-01-28  
**Status:** ✅ **COMPLETE**  
**Impact:** **HIGH** (Performance for large lists)  
**Risk:** **ZERO** (Opt-in feature)

---

**📄 Your lists can now handle thousands of items efficiently!**



## Overview

Efficient pagination system for handling large lists of work orders, PM tasks, inventory items, and other data.

---

## ✅ **What's Implemented**

### **Pagination Helper (`lib/utils/pagination_helper.dart`)**

- ✅ Generic pagination for any list type
- ✅ Configurable items per page
- ✅ Search/filter integration
- ✅ Navigation controls (next, previous, first, last, goto)
- ✅ Page information (1-20 of 150)
- ✅ Infinite scroll support

### **Pagination Widgets (`lib/widgets/pagination_widget.dart`)**

- ✅ `PaginationControls` - Full navigation UI
- ✅ `PaginationInfo` - Compact page info display
- ✅ `PaginationBar` - Complete pagination bar
- ✅ `LoadMoreButton` - Infinite scroll button

---

## 🎯 **Usage Examples**

### **1. Basic Pagination**

```dart
import 'package:qauto_cmms/utils/pagination_helper.dart';
import 'package:qauto_cmms/widgets/pagination_widget.dart';

class WorkOrderListScreen extends StatefulWidget {
  @override
  State<WorkOrderListScreen> createState() => _WorkOrderListScreenState();
}

class _WorkOrderListScreenState extends State<WorkOrderListScreen> {
  late PaginationHelper<WorkOrder> _paginator;

  @override
  void initState() {
    super.initState();
    _paginator = PaginationHelper<WorkOrder>(
      items: allWorkOrders,
      itemsPerPage: 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // List of current page items
        Expanded(
          child: ListenableBuilder(
            listenable: _paginator,
            builder: (context, _) {
              final currentPage = _paginator.getCurrentPage();
              return ListView.builder(
                itemCount: currentPage.length,
                itemBuilder: (context, index) {
                  return WorkOrderCard(workOrder: currentPage[index]);
                },
              );
            },
          ),
        ),

        // Pagination controls
        PaginationBar(paginationHelper: _paginator),
      ],
    );
  }

  @override
  void dispose() {
    _paginator.dispose();
    super.dispose();
  }
}
```

### **2. Pagination with Search**

```dart
_paginator = PaginationHelper<WorkOrder>(
  items: allWorkOrders,
  itemsPerPage: 20,
  filterFunction: (workOrder, query) {
    return workOrder.title.toLowerCase().contains(query.toLowerCase()) ||
           workOrder.id.toLowerCase().contains(query.toLowerCase());
  },
);

// In your search bar
TextField(
  onChanged: (query) => _paginator.search(query),
  decoration: InputDecoration(
    hintText: 'Search work orders...',
    suffixIcon: IconButton(
      icon: Icon(Icons.clear),
      onPressed: () => _paginator.clearSearch(),
    ),
  ),
);
```

### **3. Infinite Scroll**

```dart
import 'package:qauto_cmms/utils/pagination_helper.dart';

class InfiniteScrollListScreen extends StatefulWidget {
  @override
  State<InfiniteScrollListScreen> createState() => _InfiniteScrollListScreenState();
}

class _InfiniteScrollListScreenState extends State<InfiniteScrollListScreen> {
  late InfiniteScrollHelper<WorkOrder> _scrollHelper;

  @override
  void initState() {
    super.initState();
    _scrollHelper = InfiniteScrollHelper<WorkOrder>(
      items: allWorkOrders,
      itemsPerLoad: 20,
      initialLoad: 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loadedItems = _scrollHelper.getLoadedItems();

    return ListView.builder(
      itemCount: loadedItems.length + 1, // +1 for load more button
      itemBuilder: (context, index) {
        if (index == loadedItems.length) {
          return LoadMoreButton(
            infiniteScrollHelper: _scrollHelper,
            onLoadMore: () {
              setState(() {
                _scrollHelper.loadMore();
              });
            },
          );
        }

        return WorkOrderCard(workOrder: loadedItems[index]);
      },
    );
  }
}
```

### **4. Custom Pagination Controls**

```dart
// Just the page info
PaginationInfo(paginationHelper: _paginator);

// Just the controls
PaginationControls(
  paginationHelper: _paginator,
  activeColor: Colors.blue,
  inactiveColor: Colors.grey,
);

// Complete bar with both
PaginationBar(
  paginationHelper: _paginator,
  showInfo: true,
  showControls: true,
  activeColor: Theme.of(context).primaryColor,
);
```

---

## 📋 **PaginationHelper API**

### **Properties**

```dart
// Getters
int get totalPages              // Total number of pages
int get currentPageNumber       // Current page (1-indexed)
int get totalItems              // Total items count
int get startIndex              // Start index of current page (1-indexed)
int get endIndex                // End index of current page (1-indexed)
bool get hasNext                // Has next page
bool get hasPrevious            // Has previous page
String get searchQuery          // Current search query
bool get isSearching            // Is currently searching

// Methods
List<T> getCurrentPage()        // Get current page items
String getPageInfo()            // Get "1-20 of 150" format
```

### **Navigation Methods**

```dart
bool nextPage()                 // Go to next page
bool previousPage()             // Go to previous page
void firstPage()                // Go to first page
void lastPage()                 // Go to last page
bool goToPage(int page)         // Go to specific page (1-indexed)
```

### **Search Methods**

```dart
void search(String query)       // Search and filter items
void clearSearch()              // Clear search query
void reset()                    // Reset to first page and clear search
```

### **Update Methods**

```dart
void updateItems(List<T> items) // Update the items list
```

---

## 🎨 **Customization**

### **Change Items Per Page**

```dart
// Create new paginator with different items per page
_paginator = PaginationHelper<WorkOrder>(
  items: allWorkOrders,
  itemsPerPage: 50, // Change from default 20
);

// With dropdown selector
ItemsPerPageSelector(
  paginationHelper: _paginator,
  options: [10, 20, 50, 100],
  onChanged: (newCount) {
    setState(() {
      _paginator = PaginationHelper<WorkOrder>(
        items: allWorkOrders,
        itemsPerPage: newCount,
      );
    });
  },
);
```

### **Custom Colors**

```dart
PaginationControls(
  paginationHelper: _paginator,
  activeColor: Colors.deepPurple,
  inactiveColor: Colors.grey.shade400,
  buttonSize: 48,
);
```

### **Mobile-Friendly Controls**

```dart
// Simplified controls for mobile
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    IconButton(
      icon: Icon(Icons.chevron_left),
      onPressed: _paginator.hasPrevious
          ? () => _paginator.previousPage()
          : null,
    ),
    Text(_paginator.getPageInfo()),
    IconButton(
      icon: Icon(Icons.chevron_right),
      onPressed: _paginator.hasNext
          ? () => _paginator.nextPage()
          : null,
    ),
  ],
);
```

---

## 🚀 **Implementation Examples**

### **Work Orders List with Pagination**

```dart
class PaginatedWorkOrderList extends StatefulWidget {
  final List<WorkOrder> workOrders;

  const PaginatedWorkOrderList({
    Key? key,
    required this.workOrders,
  }) : super(key: key);

  @override
  State<PaginatedWorkOrderList> createState() => _PaginatedWorkOrderListState();
}

class _PaginatedWorkOrderListState extends State<PaginatedWorkOrderList> {
  late PaginationHelper<WorkOrder> _paginator;

  @override
  void initState() {
    super.initState();
    _paginator = PaginationHelper<WorkOrder>(
      items: widget.workOrders,
      itemsPerPage: 20,
      filterFunction: (workOrder, query) {
        return workOrder.title.toLowerCase().contains(query.toLowerCase()) ||
               workOrder.id.toLowerCase().contains(query.toLowerCase()) ||
               workOrder.asset?.name.toLowerCase().contains(query.toLowerCase()) == true;
      },
    );
  }

  @override
  void didUpdateWidget(PaginatedWorkOrderList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.workOrders != oldWidget.workOrders) {
      _paginator.updateItems(widget.workOrders);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search work orders...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: _paginator.isSearching
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () => _paginator.clearSearch(),
                    )
                  : null,
            ),
            onChanged: (query) => _paginator.search(query),
          ),
        ),

        // List
        Expanded(
          child: ListenableBuilder(
            listenable: _paginator,
            builder: (context, _) {
              final currentPage = _paginator.getCurrentPage();

              if (currentPage.isEmpty) {
                return Center(
                  child: Text('No work orders found'),
                );
              }

              return ListView.builder(
                itemCount: currentPage.length,
                itemBuilder: (context, index) {
                  return WorkOrderCard(
                    workOrder: currentPage[index],
                  );
                },
              );
            },
          ),
        ),

        // Pagination bar
        PaginationBar(paginationHelper: _paginator),
      ],
    );
  }

  @override
  void dispose() {
    _paginator.dispose();
    super.dispose();
  }
}
```

### **PM Tasks with Infinite Scroll**

```dart
class InfiniteScrollPMTasks extends StatefulWidget {
  final List<PMTask> pmTasks;

  const InfiniteScrollPMTasks({
    Key? key,
    required this.pmTasks,
  }) : super(key: key);

  @override
  State<InfiniteScrollPMTasks> createState() => _InfiniteScrollPMTasksState();
}

class _InfiniteScrollPMTasksState extends State<InfiniteScrollPMTasks> {
  late InfiniteScrollHelper<PMTask> _scrollHelper;

  @override
  void initState() {
    super.initState();
    _scrollHelper = InfiniteScrollHelper<PMTask>(
      items: widget.pmTasks,
      itemsPerLoad: 15,
      initialLoad: 15,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loadedItems = _scrollHelper.getLoadedItems();

    return ListView.builder(
      itemCount: loadedItems.length + (_scrollHelper.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == loadedItems.length) {
          return LoadMoreButton(
            infiniteScrollHelper: _scrollHelper,
            onLoadMore: () {
              setState(() {
                _scrollHelper.loadMore();
              });
            },
          );
        }

        return PMTaskCard(pmTask: loadedItems[index]);
      },
    );
  }
}
```

---

## 📱 **Mobile Optimization**

### **Responsive Pagination**

```dart
// Desktop: Full controls
// Mobile: Simplified controls

final isMobile = MediaQuery.of(context).size.width < 600;

if (isMobile) {
  // Mobile: Simple prev/next
  Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      TextButton.icon(
        icon: Icon(Icons.chevron_left),
        label: Text('Previous'),
        onPressed: _paginator.hasPrevious
            ? () => _paginator.previousPage()
            : null,
      ),
      Text(_paginator.getPageInfo()),
      TextButton.icon(
        icon: Icon(Icons.chevron_right),
        label: Text('Next'),
        onPressed: _paginator.hasNext
            ? () => _paginator.nextPage()
            : null,
      ),
    ],
  );
} else {
  // Desktop: Full pagination controls
  PaginationBar(paginationHelper: _paginator);
}
```

---

## 🧪 **Testing**

```dart
test('Pagination navigation', () {
  final items = List.generate(100, (i) => i);
  final paginator = PaginationHelper<int>(
    items: items,
    itemsPerPage: 10,
  );

  // Initial state
  expect(paginator.currentPageNumber, 1);
  expect(paginator.totalPages, 10);
  expect(paginator.getCurrentPage().length, 10);

  // Next page
  expect(paginator.nextPage(), true);
  expect(paginator.currentPageNumber, 2);

  // Last page
  paginator.lastPage();
  expect(paginator.currentPageNumber, 10);
  expect(paginator.hasNext, false);

  // First page
  paginator.firstPage();
  expect(paginator.currentPageNumber, 1);
  expect(paginator.hasPrevious, false);
});

test('Pagination with search', () {
  final items = ['Apple', 'Banana', 'Cherry', 'Date'];
  final paginator = PaginationHelper<String>(
    items: items,
    itemsPerPage: 2,
    filterFunction: (item, query) =>
        item.toLowerCase().contains(query.toLowerCase()),
  );

  // Search
  paginator.search('a');
  expect(paginator.totalItems, 3); // Apple, Banana, Date
  expect(paginator.totalPages, 2);

  // Clear search
  paginator.clearSearch();
  expect(paginator.totalItems, 4);
});
```

---

## ✅ **Best Practices**

1. **Choose appropriate page size:**

   - Mobile: 10-20 items
   - Tablet: 20-30 items
   - Desktop: 20-50 items

2. **Use search for large lists:**

   - Always provide search/filter for 100+ items
   - Reset to first page on new search

3. **Show page info:**

   - Always display "1-20 of 150" info
   - Helps users understand data size

4. **Mobile considerations:**

   - Use infinite scroll for mobile
   - Simplified controls for small screens
   - Load more button instead of page numbers

5. **Performance:**
   - Paginate lists with 50+ items
   - Use virtual scrolling for very large lists (1000+)
   - Implement search/filter for better UX

---

## 📊 **When to Use**

### **Use Pagination When:**

- ✅ List has 50+ items
- ✅ Desktop/tablet interface
- ✅ User needs to jump to specific pages
- ✅ Need precise navigation

### **Use Infinite Scroll When:**

- ✅ Mobile interface
- ✅ Social media-style feeds
- ✅ Chronological data
- ✅ Linear browsing pattern

---

## ✅ **Status**

- ✅ Pagination helper implemented
- ✅ Pagination widgets ready
- ✅ Search/filter integration
- ✅ Infinite scroll support
- ✅ Mobile responsive
- ✅ Production-ready

---

**Date:** 2025-01-28  
**Status:** ✅ **COMPLETE**  
**Impact:** **HIGH** (Performance for large lists)  
**Risk:** **ZERO** (Opt-in feature)

---

**📄 Your lists can now handle thousands of items efficiently!**


