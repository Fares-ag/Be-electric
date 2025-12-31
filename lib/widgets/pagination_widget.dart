// Pagination Widget Components
//
// Reusable UI components for pagination controls.
// Works with PaginationHelper for seamless integration.

import 'package:flutter/material.dart';
import '../utils/pagination_helper.dart';

/// Pagination controls widget
///
/// Displays page navigation controls with previous/next buttons and page numbers.
class PaginationControls extends StatelessWidget {
  const PaginationControls({
    required this.paginationHelper, super.key,
    this.activeColor,
    this.inactiveColor,
    this.buttonSize = 40,
  });
  final PaginationHelper paginationHelper;
  final Color? activeColor;
  final Color? inactiveColor;
  final double? buttonSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = activeColor ?? theme.primaryColor;
    final inactive = inactiveColor ?? Colors.grey;

    return ListenableBuilder(
      listenable: paginationHelper,
      builder: (context, _) {
        if (paginationHelper.totalPages <= 1) {
          return const SizedBox.shrink();
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // First page button
            IconButton(
              icon: const Icon(Icons.first_page),
              onPressed: paginationHelper.hasPrevious
                  ? paginationHelper.firstPage
                  : null,
              color: paginationHelper.hasPrevious ? active : inactive,
            ),

            // Previous button
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: paginationHelper.hasPrevious
                  ? paginationHelper.previousPage
                  : null,
              color: paginationHelper.hasPrevious ? active : inactive,
            ),

            // Page numbers
            ..._buildPageNumbers(context, active, inactive),

            // Next button
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed:
                  paginationHelper.hasNext ? paginationHelper.nextPage : null,
              color: paginationHelper.hasNext ? active : inactive,
            ),

            // Last page button
            IconButton(
              icon: const Icon(Icons.last_page),
              onPressed:
                  paginationHelper.hasNext ? paginationHelper.lastPage : null,
              color: paginationHelper.hasNext ? active : inactive,
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildPageNumbers(
    BuildContext context,
    Color active,
    Color inactive,
  ) {
    final pageNumbers = PaginationDisplayHelper.getPageNumbers(
      paginationHelper.currentPageNumber,
      paginationHelper.totalPages,
    );

    return pageNumbers.map((page) {
      if (page is String) {
        // Ellipsis
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(page, style: TextStyle(color: inactive)),
        );
      }

      final isActive = page == paginationHelper.currentPageNumber;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: Material(
            color: isActive ? active : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            child: InkWell(
              onTap: () => paginationHelper.goToPage(page),
              borderRadius: BorderRadius.circular(4),
              child: Center(
                child: Text(
                  '$page',
                  style: TextStyle(
                    color: isActive ? Colors.white : inactive,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}

/// Compact pagination info
///
/// Shows "1-20 of 150" style info
class PaginationInfo extends StatelessWidget {
  const PaginationInfo({
    required this.paginationHelper, super.key,
    this.textStyle,
  });
  final PaginationHelper paginationHelper;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: paginationHelper,
        builder: (context, _) => Text(
          paginationHelper.getPageInfo(),
          style: textStyle ?? Theme.of(context).textTheme.bodySmall,
        ),
      );
}

/// Items per page selector
class ItemsPerPageSelector extends StatelessWidget {
  const ItemsPerPageSelector({
    required this.paginationHelper, required this.onChanged, super.key,
    this.options = const [10, 20, 50, 100],
  });
  final PaginationHelper paginationHelper;
  final List<int> options;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Items per page:',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: paginationHelper.itemsPerPage,
            underline: const SizedBox.shrink(),
            items: options
                .map((count) => DropdownMenuItem(
                      value: count,
                      child: Text('$count'),
                    ),)
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onChanged(value);
              }
            },
          ),
        ],
      );
}

/// Complete pagination bar with all controls
class PaginationBar extends StatelessWidget {
  const PaginationBar({
    required this.paginationHelper, super.key,
    this.showInfo = true,
    this.showControls = true,
    this.activeColor,
  });
  final PaginationHelper paginationHelper;
  final bool showInfo;
  final bool showControls;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            top: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Info on the left
            if (showInfo)
              PaginationInfo(paginationHelper: paginationHelper)
            else
              const SizedBox.shrink(),

            // Controls in the center/right
            if (showControls)
              PaginationControls(
                paginationHelper: paginationHelper,
                activeColor: activeColor,
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      );
}

/// Load more button for infinite scroll
class LoadMoreButton extends StatelessWidget {
  const LoadMoreButton({
    required this.infiniteScrollHelper, required this.onLoadMore, super.key,
    this.loadingText,
    this.noMoreText,
  });
  final InfiniteScrollHelper infiniteScrollHelper;
  final VoidCallback onLoadMore;
  final String? loadingText;
  final String? noMoreText;

  @override
  Widget build(BuildContext context) {
    if (!infiniteScrollHelper.hasMore) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            noMoreText ?? 'No more items',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: onLoadMore,
          icon: const Icon(Icons.expand_more),
          label: Text(
            loadingText ??
                'Load More (${infiniteScrollHelper.remainingCount} remaining)',
          ),
        ),
      ),
    );
  }
}
