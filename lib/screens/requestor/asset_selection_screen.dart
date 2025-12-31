import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/asset.dart';
import '../../providers/auth_provider.dart';
import '../../services/hybrid_dam_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/mobile_qr_scanner_widget.dart';
import '../../widgets/custom_app_bar.dart';
import 'create_maintenance_request_screen.dart';

class AssetSelectionScreen extends StatefulWidget {
  const AssetSelectionScreen({
    this.initialTab = 0,
    super.key,
  });
  final int initialTab; // 0 = QR, 1 = Search, 2 = Manual

  @override
  State<AssetSelectionScreen> createState() => _AssetSelectionScreenState();
}

class _AssetSelectionScreenState extends State<AssetSelectionScreen>
    with SingleTickerProviderStateMixin {
  final HybridDamService _hybridService = HybridDamService();
  List<Asset> _assets = [];
  List<Asset> _filteredAssets = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _manualAssetId = '';
  late TabController _tabController;
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    if (widget.initialTab != 0) {
      _loadAssets();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAssets({bool forceReload = false}) async {
    // Don't reload if already loaded and not forcing
    if (!forceReload && _assets.isNotEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user's companyId for filtering
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      final companyId = user?.companyId;

      // Use HybridDamService to load all assets (same as enhanced asset selection)
      await _hybridService.initialize();
      var assets = await _hybridService.getAllAssets();
      
      // Filter assets by company if user has a companyId (multi-tenant isolation)
      if (companyId != null && user?.role == 'requestor') {
        assets = assets.where((asset) => asset.companyId == companyId).toList();
        debugPrint('📋 Filtered assets by companyId: $companyId (${assets.length} assets)');
      }
      
      if (mounted) {
        setState(() {
          _assets = assets;
          _filteredAssets = assets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading assets: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  void _filterAssets(String query) {
    // Debounce search input to avoid excessive filtering
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = query;
        if (query.isEmpty) {
          _filteredAssets = _assets;
        } else {
          final lowerQuery = query.toLowerCase();
          _filteredAssets = _assets
              .where(
                (asset) =>
                    asset.name.toLowerCase().contains(lowerQuery) ||
                    asset.location.toLowerCase().contains(lowerQuery) ||
                    asset.id.toLowerCase().contains(lowerQuery) ||
                    (asset.description
                            ?.toLowerCase()
                            .contains(lowerQuery) ??
                        false),
              )
              .toList();
        }
      });
    });
  }

  Future<void> _handleQRCodeScanned(String qrCode) async {
    try {
      // Extract asset ID from QR code (handle various formats)
      String? extractedId = _extractAssetIdFromQRCode(qrCode);
      final String assetId = extractedId ?? qrCode.trim(); // Use raw QR code as fallback

      // Load assets if not already loaded
      await _loadAssets();
      
      // Try to find asset by ID in loaded assets
      Asset? asset;
      try {
        asset = _assets.firstWhere(
          (a) => a.id.toLowerCase() == assetId.toLowerCase(),
          orElse: () => throw Exception('Asset not found'),
        );
      } catch (e) {
        // Asset not found
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Asset not found'),
              backgroundColor: AppTheme.accentRed,
            ),
          );
        }
        return;
      }

      if (asset != null && mounted) {
        try {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CreateMaintenanceRequestScreen(
                asset: asset!,
                qrCode: assetId,
              ),
            ),
          );
        } catch (e) {
          debugPrint('Navigation error: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Navigation error. Please try again.'),
                backgroundColor: AppTheme.accentRed,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  String? _extractAssetIdFromQRCode(String qrCode) {
    final cleanCode = qrCode.trim();
    
    // Pattern 1: Asset format (e.g., "2025_00001", "2024_12345")
    if (RegExp(r'^\d{4}_\d{5}$').hasMatch(cleanCode)) {
      return cleanCode;
    }
    
    // Pattern 2: Pure numeric ID
    if (RegExp(r'^\d+$').hasMatch(cleanCode)) {
      return cleanCode;
    }
    
    // Pattern 3: Extract asset format from anywhere in the text
    final assetFormatMatch = RegExp(r'\d{4}_\d{5}').firstMatch(cleanCode);
    if (assetFormatMatch != null) {
      return assetFormatMatch.group(0);
    }
    
    // Pattern 4: Extract any sequence of digits
    final digitMatch = RegExp(r'\d+').firstMatch(cleanCode);
    if (digitMatch != null) {
      return digitMatch.group(0);
    }
    
    return null;
  }

  Future<void> _handleManualAssetId() async {
    if (_manualAssetId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an asset ID'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Load assets if not already loaded
      await _loadAssets();
      
      // Try to find asset by ID in loaded assets
      Asset? asset;
      try {
        asset = _assets.firstWhere(
          (a) => a.id.toLowerCase() == _manualAssetId.trim().toLowerCase(),
          orElse: () => throw Exception('Asset not found'),
        );
      } catch (e) {
        // Asset not found
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Asset not found: ${_manualAssetId.trim()}'),
              backgroundColor: AppTheme.accentRed,
            ),
          );
        }
        return;
      }

      if (asset != null && mounted) {
        setState(() {
          _isLoading = false;
        });
        try {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CreateMaintenanceRequestScreen(
                asset: asset!,
                qrCode: _manualAssetId.trim(),
              ),
            ),
          );
        } catch (e) {
          debugPrint('Navigation error: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Navigation error. Please try again.'),
                backgroundColor: AppTheme.accentRed,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  void _onAssetSelected(Asset asset) {
    if (!mounted) return;
    try {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CreateMaintenanceRequestScreen(
            asset: asset,
            qrCode: '',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Navigation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Navigation error. Please try again.'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Widget _buildAssetLeading(Asset asset) {
    // Try to show image first, fallback to icon
    if (asset.imageUrl != null && asset.imageUrl!.isNotEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: asset.isActive
                ? AppTheme.accentGreen
                : AppTheme.accentOrange,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: asset.imageUrl != null && asset.imageUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: asset.imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => _buildFallbackIcon(asset),
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                )
              : _buildFallbackIcon(asset),
        ),
      );
    } else if (asset.imageUrls != null && asset.imageUrls!.isNotEmpty) {
      // Use first image from imageUrls if available
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: asset.isActive
                ? AppTheme.accentGreen
                : AppTheme.accentOrange,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: asset.imageUrls != null && 
                 asset.imageUrls!.isNotEmpty && 
                 asset.imageUrls!.first.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: asset.imageUrls!.first,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => _buildFallbackIcon(asset),
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                )
              : _buildFallbackIcon(asset),
        ),
      );
    } else {
      return _buildFallbackIcon(asset);
    }
  }

  Widget _buildFallbackIcon(Asset asset) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: asset.isActive
            ? AppTheme.accentGreen.withValues(alpha: 0.1)
            : AppTheme.accentOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: asset.isActive
              ? AppTheme.accentGreen
              : AppTheme.accentOrange,
          width: 2,
        ),
      ),
      child: Icon(
        asset.isActive ? Icons.check_circle : Icons.warning,
        color: asset.isActive
            ? AppTheme.accentGreen
            : AppTheme.accentOrange,
        size: 28,
      ),
    );
  }

  /// Build asset card with image and brand name (matching the charger selection design)
  Widget _buildAssetCard(Asset asset, {bool isSmallScreen = false}) {
    // Get the image URL (prefer imageUrl, fallback to first imageUrls)
    final imageUrl = asset.imageUrl ?? 
        (asset.imageUrls != null && asset.imageUrls!.isNotEmpty 
            ? asset.imageUrls!.first 
            : null);
    
    // Get manufacturer/brand name
    final brandName = asset.manufacturer ?? asset.name;
    final padding = isSmallScreen ? AppTheme.spacingS : AppTheme.spacingM;
    final fontSize = isSmallScreen ? 12.0 : 14.0;

    return Material(
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      color: Colors.white,
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        onTap: () => _onAssetSelected(asset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Asset image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusM),
                  topRight: Radius.circular(AppTheme.radiusM),
                ),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.image_not_supported,
                            size: isSmallScreen ? 32 : 48,
                            color: Colors.grey[400],
                          ),
                        ),
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image_not_supported,
                          size: isSmallScreen ? 32 : 48,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
            ),
            // Brand name
            Padding(
              padding: EdgeInsets.all(padding),
              child: Text(
                brandName,
                style: AppTheme.heading2.copyWith(
                  color: AppTheme.darkTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFE5E7EB),
        appBar: CustomAppBar(
          title: 'Select Asset',
          showMenu: false,
          actions: const [],
        ),
        body: Column(
          children: [
            TabBar(
              controller: _tabController,
              onTap: (index) {
                if (index == 1 || index == 2) {
                  _loadAssets();
                }
              },
              tabs: const [
                Tab(icon: Icon(Icons.qr_code_scanner), text: 'Scan QR'),
                Tab(icon: Icon(Icons.search), text: 'Search'),
                Tab(icon: Icon(Icons.keyboard), text: 'Enter ID'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildQRScanTab(),
                  _buildSearchTab(),
                  _buildManualEntryTab(),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildQRScanTab() => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            color: AppTheme.accentBlue.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppTheme.accentBlue,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: Text(
                    'Point your camera at the QR code on the asset',
                    style: AppTheme.smallText.copyWith(
                      color: AppTheme.accentBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: MobileQRScannerWidget(
              isRequestorMode: true,
              onQRCodeScanned: _handleQRCodeScanned,
            ),
          ),
        ],
      );

  Widget _buildSearchTab() {
    if (_assets.isEmpty && !_isLoading) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF002D17),
              const Color(0xFF004626),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off,
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                'No assets available',
                style: AppTheme.heading2.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              ElevatedButton.icon(
                onPressed: _loadAssets,
                icon: const Icon(Icons.refresh),
                label: const Text('Load Assets'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF002D17),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 400; // iPhone SE and similar small screens
        final padding = isSmallScreen ? AppTheme.spacingM : AppTheme.spacingL;
        final iconSize = isSmallScreen ? 24.0 : 28.0;
        final titleFontSize = isSmallScreen ? 18.0 : 24.0;
        final subtitleFontSize = isSmallScreen ? 12.0 : 14.0;
        
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF002D17),
                const Color(0xFF004626),
              ],
            ),
          ),
          child: Column(
            children: [
              // Header section with icon, title, and subtitle
              Padding(
                padding: EdgeInsets.all(padding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? AppTheme.spacingS : AppTheme.spacingM),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Icon(
                        Icons.build,
                        size: iconSize,
                        color: AppTheme.accentGreen,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? AppTheme.spacingM : AppTheme.spacingL),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Request Maintenance',
                            style: AppTheme.heading1.copyWith(
                              color: Colors.white,
                              fontSize: titleFontSize,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? AppTheme.spacingXS : AppTheme.spacingS),
                          Text(
                            'Select an asset to request maintenance work',
                            style: AppTheme.bodyText.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: subtitleFontSize,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Search field
              Padding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name, location, or ID...',
                    hintStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: isSmallScreen ? 12 : 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                  style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                  onChanged: _filterAssets,
                ),
              ),
              
              SizedBox(height: isSmallScreen ? AppTheme.spacingM : AppTheme.spacingL),
              
              // "Select your asset:" heading
              Padding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select your asset:',
                    style: AppTheme.heading2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 16 : 18,
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: isSmallScreen ? AppTheme.spacingS : AppTheme.spacingM),
              
              // Asset cards grid
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : _filteredAssets.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: isSmallScreen ? 48 : 64,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                SizedBox(height: AppTheme.spacingM),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: padding),
                                  child: Text(
                                    _searchQuery.isEmpty
                                        ? 'No assets found'
                                        : 'No assets match your search',
                                    style: AppTheme.bodyText.copyWith(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: subtitleFontSize,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: EdgeInsets.all(padding),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: isSmallScreen ? AppTheme.spacingS : AppTheme.spacingM,
                              mainAxisSpacing: isSmallScreen ? AppTheme.spacingS : AppTheme.spacingM,
                              childAspectRatio: isSmallScreen ? 0.7 : 0.75,
                            ),
                            itemCount: _filteredAssets.length,
                            itemBuilder: (context, index) {
                              final asset = _filteredAssets[index];
                              return _buildAssetCard(asset, isSmallScreen: isSmallScreen);
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildManualEntryTab() => Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(
                  color: AppTheme.accentBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppTheme.accentBlue,
                    size: 32,
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    'Enter Asset ID',
                    style: AppTheme.heading2.copyWith(
                      color: AppTheme.accentBlue,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    'If you know the asset ID, enter it below to quickly find the asset.',
                    style: AppTheme.bodyText.copyWith(
                      color: AppTheme.accentBlue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            TextField(
              decoration: InputDecoration(
                labelText: 'Asset ID',
                hintText: 'Enter the asset ID...',
                prefixIcon: const Icon(Icons.inventory_2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: const BorderSide(
                    color: AppTheme.accentBlue,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _manualAssetId = value;
                });
              },
              onSubmitted: (_) => _handleManualAssetId(),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleManualAssetId,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.search),
              label: Text(_isLoading ? 'Searching...' : 'Find Asset'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingL,
                  vertical: AppTheme.spacingM,
                ),
                minimumSize: const Size(0, 50),
              ),
            ),
          ],
        ),
      );
}
