import '../models/asset.dart';

/// Brand shortcut assets created in [RequestorMainScreen] — not in [public.assets].
bool isRequestorPlaceholderChargerAsset(Asset asset) {
  final id = asset.id.toLowerCase().trim();
  return id == 'siemens' || id == 'kostad';
}

/// Validates that the requestor can proceed to review/submit with a real asset.
///
/// Returns a user-facing error message, or `null` when the asset is acceptable.
String? validateRequestorReviewAsset({
  required Asset asset,
  required bool isChargerTypeFlow,
  required bool isLoadingChargers,
  required bool chargersLoadAttempted,
  required int companyChargerCount,
}) {
  if (!isRequestorPlaceholderChargerAsset(asset) && asset.id.trim().isNotEmpty) {
    return null;
  }

  if (isChargerTypeFlow) {
    if (isLoadingChargers) {
      return 'Still loading chargers. Please wait a moment and try again.';
    }
    if (chargersLoadAttempted && companyChargerCount == 0) {
      return 'No chargers are registered for your company. Ask your administrator '
          'to add chargers before submitting a request.';
    }
    return 'Please select a registered charger before continuing.';
  }

  return 'This request must be linked to a registered asset. '
      'Please go back and select a valid charger.';
}

class RequestorWorkOrderAssetSubmission {
  const RequestorWorkOrderAssetSubmission({
    required this.assetId,
    required this.asset,
  });

  final String assetId;
  final Asset asset;
}

/// Resolves work-order asset fields for submit. Returns `null` when only a
/// placeholder asset is available (Scenario B — asset linkage required).
RequestorWorkOrderAssetSubmission? resolveRequestorWorkOrderAssetSubmission(
  Asset asset,
) {
  if (isRequestorPlaceholderChargerAsset(asset) || asset.id.trim().isEmpty) {
    return null;
  }
  return RequestorWorkOrderAssetSubmission(
    assetId: asset.id,
    asset: asset,
  );
}
