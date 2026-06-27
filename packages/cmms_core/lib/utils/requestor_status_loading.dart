/// Whether the requestor status screen should show the initial loading state.
///
/// Shows loading only while work orders are loading and none are available yet.
/// When cached/realtime data exists, the list stays visible during refresh.
bool shouldShowRequestorStatusInitialLoading({
  required bool isWorkOrdersLoading,
  required int requestCount,
}) {
  return isWorkOrdersLoading && requestCount == 0;
}
