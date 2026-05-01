import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../services/supabase_service.dart';

class GoldShop {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  final String phone;
  final String hours;
  final List<String> services;
  final double distance;

  GoldShop({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.phone,
    required this.hours,
    required this.services,
    required this.distance,
  });

  factory GoldShop.fromJson(Map<String, dynamic> json, double userLat, double userLng) {
    final shopLat = (json['latitude'] as num).toDouble();
    final shopLng = (json['longitude'] as num).toDouble();
    final distance = _calculateDistance(userLat, userLng, shopLat, shopLng);

    return GoldShop(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: shopLat,
      longitude: shopLng,
      rating: (json['rating'] as num).toDouble(),
      phone: json['phone'] as String,
      hours: json['hours'] as String,
      services: List<String>.from(json['services'] as List),
      distance: distance,
    );
  }

  static double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371;
    final double dLat = _toRadians(lat2 - lat1);
    final double dLng = _toRadians(lng2 - lng1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    final double c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  static double _toRadians(double degree) => degree * (math.pi / 180);
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  List<GoldShop> _goldShops = [];
  LatLng? _userLocation;
  bool _isLoading = true;
  String _errorMessage = '';
  GoldShop? _selectedShop;
  String _searchQuery = '';
  double _searchRadius = AppConstants.searchRadius;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Default to a major city (can be replaced with actual location services)
      _userLocation = const LatLng(40.7128, -74.0060); // New York City
      
      await _loadNearbyShops();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize map: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNearbyShops() async {
    if (_userLocation == null) return;

    try {
      final shopsData = await SupabaseService.getNearbyGoldShops(
        latitude: _userLocation!.latitude,
        longitude: _userLocation!.longitude,
        radius: _searchRadius,
      );

      final shops = shopsData.map((shop) => 
        GoldShop.fromJson(shop, _userLocation!.latitude, _userLocation!.longitude)
      ).toList();

      // Sort by distance
      shops.sort((a, b) => a.distance.compareTo(b.distance));

      setState(() {
        _goldShops = shops;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load nearby shops: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _onShopTap(GoldShop shop) {
    setState(() {
      _selectedShop = shop;
    });
    
    // Center map on selected shop
    _mapController.move(LatLng(shop.latitude, shop.longitude), 15.0);
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedShop = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gold Shops Map',
          style: TextStyle(
            color: AppTheme.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.filter),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(LucideIcons.crosshair),
            onPressed: _centerOnUser,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search gold shops...',
                      prefixIcon: const Icon(LucideIcons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_goldShops.length} shops',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Map and List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _errorMessage.isNotEmpty
                    ? _buildErrorState()
                    : _buildMapContent(),
          ),
        ],
      ),
      floatingActionButton: _selectedShop != null
          ? FloatingActionButton.extended(
              onPressed: _showShopDetails,
              icon: const Icon(LucideIcons.info),
              label: const Text('Shop Details'),
              backgroundColor: AppTheme.gold,
              foregroundColor: AppTheme.black,
            )
          : null,
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              LucideIcons.mapPinOff,
              size: 48,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Map Error',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _initializeMap,
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.gold,
              foregroundColor: AppTheme.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapContent() {
    final filteredShops = _goldShops.where((shop) {
      if (_searchQuery.isEmpty) return true;
      return shop.name.toLowerCase().contains(_searchQuery) ||
             shop.address.toLowerCase().contains(_searchQuery);
    }).toList();

    return Stack(
      children: [
        // Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _userLocation ?? const LatLng(40.7128, -74.0060),
            initialZoom: AppConstants.defaultZoom,
            onTap: _onMapTap,
            minZoom: 10.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.goldtrade',
            ),
            
            // User Location Marker
            if (_userLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _userLocation!,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        LucideIcons.user,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            
            // Gold Shop Markers
            MarkerLayer(
              markers: filteredShops.map((shop) {
                final isSelected = _selectedShop?.id == shop.id;
                return Marker(
                  point: LatLng(shop.latitude, shop.longitude),
                  child: GestureDetector(
                    onTap: () => _onShopTap(shop),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.gold : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        LucideIcons.store,
                        color: Colors.white,
                        size: isSelected ? 20 : 16,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        
        // Shop List Overlay
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filteredShops.length,
              itemBuilder: (context, index) {
                final shop = filteredShops[index];
                final isSelected = _selectedShop?.id == shop.id;
                
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.gold.withOpacity(0.2) : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.gold : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () => _onShopTap(shop),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.gold.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                LucideIcons.store,
                                size: 16,
                                color: AppTheme.gold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                shop.name,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.mapPin,
                              size: 12,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${shop.distance.toStringAsFixed(1)} km away',
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.star,
                              size: 12,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              shop.rating.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                shop.hours,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showShopDetails() {
    if (_selectedShop == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Shop Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.premiumGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.store,
                      color: AppTheme.black,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedShop!.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.star,
                              size: 16,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _selectedShop!.rating.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_selectedShop!.distance.toStringAsFixed(1)} km away',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Shop Details
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Address
                      _buildDetailSection(
                        'Address',
                        _selectedShop!.address,
                        LucideIcons.mapPin,
                      ),
                      const SizedBox(height: 16),
                      
                      // Phone
                      _buildDetailSection(
                        'Phone',
                        _selectedShop!.phone,
                        LucideIcons.phone,
                        isActionable: true,
                      ),
                      const SizedBox(height: 16),
                      
                      // Hours
                      _buildDetailSection(
                        'Business Hours',
                        _selectedShop!.hours,
                        LucideIcons.clock,
                      ),
                      const SizedBox(height: 16),
                      
                      // Services
                      Text(
                        'Services',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedShop!.services.map((service) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.gold.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.gold.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              service,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.gold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Navigate to shop
                              },
                              icon: const Icon(LucideIcons.navigation),
                              label: const Text('Directions'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.gold,
                                foregroundColor: AppTheme.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // Call shop
                              },
                              icon: const Icon(LucideIcons.phone),
                              label: const Text('Call'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.gold),
                                foregroundColor: AppTheme.gold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    String title,
    String value,
    IconData icon, {
    bool isActionable = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: isActionable ? () {
            // Handle action (e.g., make phone call)
          } : null,
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isActionable ? AppTheme.gold : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isActionable ? AppTheme.gold : null,
                    decoration: isActionable ? TextDecoration.underline : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Search Radius: ${_searchRadius.toStringAsFixed(1)} km',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Slider(
              value: _searchRadius,
              min: 1.0,
              max: 50.0,
              divisions: 49,
              onChanged: (value) {
                setState(() {
                  _searchRadius = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadNearbyShops();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.gold,
              foregroundColor: AppTheme.black,
            ),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _centerOnUser() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 15.0);
    }
  }
}

  
