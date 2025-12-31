class ApiConfig {
  // API Configuration constants
  static const String baseUrl = 'https://api.qauto.com';
  static const String apiVersion = 'v1';
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';

  // API Endpoints
  static const String assetsEndpoint = '/assets';
  static const String workOrdersEndpoint = '/work-orders';
  static const String usersEndpoint = '/users';
  static const String authEndpoint = '/auth';

  // Asset Management URLs
  static const String assetManagementBaseUrl = 'https://api.qauto.com/assets';

  // DAM (Digital Asset Management) Configuration
  static const String damApiKey = 'cmms-maintenance';
  static const String damGetAssetsEndpoint = '/getAssets';
  static const String damHealthEndpoint = '/health';

  // Request timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache settings
  static const Duration cacheExpiry = Duration(hours: 1);
  static const int maxCacheSize = 1000;
  static const String cacheKey = 'asset_cache';

  // Default headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // URL building methods
  static String buildUrl(String endpoint, {Map<String, String>? queryParams}) {
    final uri = Uri.parse('$baseUrl$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams).toString();
    }
    return uri.toString();
  }

  // Specific endpoint methods
  static String getAllAssets = assetsEndpoint;
  static String searchAssets = '$assetsEndpoint/search';
  static String getAssetsByDepartmentUrl(String department) =>
      '$assetsEndpoint/department/$department';
  static String getAssetByIdUrl(String id) => '$assetsEndpoint/$id';
  static String searchAssetsUrl(String query) =>
      '$assetsEndpoint/search?query=$query';
}
