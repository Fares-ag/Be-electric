/// Helpers for PostgREST write responses that return success even when
/// zero rows match (e.g. RLS filtered UPDATE).
void ensureRowsUpdated(
  dynamic response, {
  required String entityLabel,
}) {
  final rows = response is List ? response : null;
  if (rows == null || rows.isEmpty) {
    throw Exception(
      '$entityLabel update failed: no row updated (not found or not permitted)',
    );
  }
}
