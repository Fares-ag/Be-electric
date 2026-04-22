import '../models/asset.dart';

/// Treat as charger if name/type/category contains "charger" or EV power pattern
/// (e.g. 60kW.DC). Same rules as the admin company chargers list.
bool isChargerLikeAsset(Asset asset) {
  const charger = 'charger';
  const evPower = 'kw';
  final name = asset.name.toLowerCase();
  final itemType = asset.itemType?.toLowerCase() ?? '';
  final category = asset.category?.toLowerCase() ?? '';
  if (name.contains(charger) ||
      itemType.contains(charger) ||
      category.contains(charger) ||
      name.contains(evPower) ||
      itemType.contains(evPower) ||
      category.contains(evPower)) {
    return true;
  }
  // Manufacturer / vendor often set even when name is only an asset code (e.g. "KEC00067")
  final m = '${asset.manufacturer ?? ''} ${asset.vendor ?? ''} ${asset.model ?? ''}'
      .toLowerCase();
  if (m.contains('charg') ||
      m.contains('siemens') ||
      m.contains('kostad') ||
      m.contains('evse') ||
      m.contains('wallbox') ||
      m.contains('cbox') ||
      m.contains('kec') ||
      m.contains('sicharge') ||
      m.contains('versicharge')) {
    return true;
  }
  final extra = '${asset.description ?? ''} ${asset.notes ?? ''}'.toLowerCase();
  if (extra.contains(charger) ||
      extra.contains(evPower) ||
      extra.contains('sicharge') ||
      extra.contains('evse')) {
    return true;
  }
  return false;
}

String? _nonEmptyTrim(String? s) {
  if (s == null) return null;
  final t = s.trim();
  return t.isEmpty ? null : t;
}

/// True if [text] is associated with [brand] (Siemens includes Sicharge, etc.)
bool _textImpliesChargerBrand(String brandLower, String text) {
  final t = text.toLowerCase();
  if (t.contains(brandLower)) {
    return true;
  }
  if (brandLower == 'siemens') {
    if (t.contains('sicharge') ||
        t.contains('sicharger') ||
        t.contains('versicharge')) {
      return true;
    }
  }
  return false;
}

/// Matches [brand] (e.g. `Siemens`, `Kostad`) using manufacturer, vendor, name,
/// model, description, category, item type, notes (admin data is often in text fields only).
bool matchesChargerBrand(Asset asset, String brand) {
  final b = brand.trim().toLowerCase();
  if (b.isEmpty) {
    return false;
  }

  final fromFields = _nonEmptyTrim(asset.manufacturer) ??
      _nonEmptyTrim(asset.vendor);
  if (fromFields != null) {
    final fl = fromFields.toLowerCase();
    if (fl == b || _textImpliesChargerBrand(b, fromFields)) {
      return true;
    }
    if (fl.length >= 3 && b.contains(fl)) {
      return true;
    }
  }

  final blob = [
    asset.name,
    asset.model,
    asset.description,
    asset.category,
    asset.itemType,
    asset.notes,
    asset.modelDesc,
  ].whereType<String>().join(' ');

  if (_textImpliesChargerBrand(b, blob)) {
    return true;
  }
  // Legacy simple substring in name / model
  return asset.name.toLowerCase().contains(b) ||
      (asset.model ?? '').toLowerCase().contains(b);
}

/// True if [asset] is in the same tenant as the signed-in user.
/// Handles camelCase and legacy rows where the FK is in [Asset.company] or
/// the company name is stored instead of the UUID.
bool assetBelongsToUserCompany(
  Asset asset,
  String userCompanyId, {
  String? resolvedCompanyName,
}) {
  final uid = userCompanyId.trim();
  if (uid.isEmpty) {
    return false;
  }
  final aid = _nonEmptyTrim(asset.companyId);
  if (aid != null && aid == uid) {
    return true;
  }
  final ac = _nonEmptyTrim(asset.company);
  if (ac != null) {
    if (ac == uid) {
      return true;
    }
    if (resolvedCompanyName != null &&
        resolvedCompanyName.isNotEmpty &&
        ac.toLowerCase() == resolvedCompanyName.toLowerCase()) {
      return true;
    }
  }
  return false;
}
