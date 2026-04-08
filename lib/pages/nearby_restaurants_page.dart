import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'package:ku_wongnai/widgets/restaurant_detail_sheet.dart';
import 'package:ku_wongnai/widgets/storage_image_widget.dart';
import 'package:ku_wongnai/utils/restaurant_utils.dart';

class NearbyRestaurantsPage extends StatefulWidget {
  const NearbyRestaurantsPage({super.key});

  @override
  State<NearbyRestaurantsPage> createState() => _NearbyRestaurantsPageState();
}

class _NearbyRestaurantsPageState extends State<NearbyRestaurantsPage>
    with SingleTickerProviderStateMixin {
  bool isLoading = true;
  String locationNote = '';
  geo.Position? currentPosition;
  String selectedFoodType = 'all';
  String _userRole = 'user';

  // Tab
  late TabController _tabController;
  // int _tabIndex is removed — using _tabController.index directly

  // Map
  MapboxMap? _mapboxMap;
  bool _mapStyleReady = false;
  bool _mapInitDone = false;
  List<Map<String, dynamic>> _allRestaurants = [];
  bool _restaurantsLoaded = false;

  static const String _clusterSourceId = 'restaurants-cluster-source';
  static const String _clusterCircleLayerId = 'cluster-circle-layer';
  static const String _clusterCountLayerId = 'cluster-count-layer';
  static const String _unclusteredLayerId = 'unclustered-point-layer';

  static const List<String> _allFoodTypes = [
    'ก๋วยเตี๋ยว', 'ข้าวราดแกง', 'อาหารตามสั่ง', 'ส้มตำ', 'ยำ',
    'เนื้อย่าง', 'ปิ้งย่าง', 'ผัดไทย', 'อาหารญี่ปุ่น',
    'กาแฟ', 'ชา', 'เบเกอรี่', 'ชาไข่มุก', 'น้ำผลไม้',
    'สมูทตี้', 'โยเกิร์ต', 'เครื่องดื่ม',
  ];

  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  static const double _kuLat = 13.8476;
  static const double _kuLng = 100.5693;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadCurrentLocation();
    _loadRole();
    _fetchRestaurants();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && mounted) {
        setState(() => _userRole = (doc.data()?['role'] ?? 'user').toString());
      }
    } catch (_) {}
  }

  Future<void> _loadCurrentLocation() async {
    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _useFallback('Location Service ปิดอยู่ — แสดงร้านบริเวณ มก. แทน');
        return;
      }
      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }
      if (permission == geo.LocationPermission.denied ||
          permission == geo.LocationPermission.deniedForever) {
        _useFallback('ไม่ได้รับสิทธิ์ตำแหน่ง — แสดงร้านบริเวณ มก. แทน');
        return;
      }
      final pos = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 8), onTimeout: () => throw Exception('timeout'));
      if (!mounted) return;
      setState(() {
        currentPosition = pos;
        isLoading = false;
        locationNote = '';
      });
    } catch (_) {
      _useFallback('ไม่พบตำแหน่ง — แสดงร้านบริเวณ มก. แทน');
    }
  }

  void _useFallback(String note) {
    if (!mounted) return;
    setState(() {
      currentPosition = geo.Position(
        latitude: _kuLat,
        longitude: _kuLng,
        timestamp: DateTime.now(),
        accuracy: 0, altitude: 0, altitudeAccuracy: 0,
        heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0,
      );
      locationNote = note;
      isLoading = false;
    });
  }

  Future<void> _fetchRestaurants() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('restaurants').get();
      if (!mounted) return;
      setState(() {
        _allRestaurants = snap.docs.map((doc) {
          final d = doc.data();
          d['id'] = doc.id;
          return d;
        }).toList();
        _restaurantsLoaded = true;
      });
      // ถ้าแผนที่โหลดเสร็จแล้ว ให้ add source ทันที
      if (_mapStyleReady) _setupClusterOnMap();
    } catch (_) {}
  }

  // ========== MAP CLUSTER ==========

  String _buildGeoJson() {
    final features = _allRestaurants.where((r) {
      final lat = (r['latitude'] as num?)?.toDouble();
      final lng = (r['longitude'] as num?)?.toDouble();
      return lat != null && lng != null;
    }).map((r) {
      return {
        'type': 'Feature',
        'properties': {
          'id': r['id'] ?? '',
          'name': r['name'] ?? '',
          'desc': r['desc'] ?? '',
          'imagePath': r['imagePath'],
          'avgRating': r['avgRating'] ?? 0,
          'openTime': r['openTime'] ?? '',
          'closeTime': r['closeTime'] ?? '',
          'category': r['category'] ?? '',
          'foodTypes': r['foodTypes'] ?? [],
          'latitude': (r['latitude'] as num?)?.toDouble(),
          'longitude': (r['longitude'] as num?)?.toDouble(),
        },
        'geometry': {
          'type': 'Point',
          'coordinates': [
            (r['longitude'] as num).toDouble(),
            (r['latitude'] as num).toDouble(),
          ],
        }
      };
    }).toList();

    return jsonEncode({'type': 'FeatureCollection', 'features': features});
  }

  Future<void> _setupClusterOnMap() async {
    if (_mapboxMap == null || !_mapStyleReady || !_restaurantsLoaded) return;
    if (_mapInitDone) return;
    _mapInitDone = true;

    final geoJson = _buildGeoJson();

    // ---- Source ----
    final hasSource = await _mapboxMap!.style.styleSourceExists(_clusterSourceId);
    if (!hasSource) {
      await _mapboxMap!.style.addStyleSource(
        _clusterSourceId,
        jsonEncode({
          'type': 'geojson',
          'data': jsonDecode(geoJson),
          'cluster': true,
          'clusterMaxZoom': 14,
          'clusterRadius': 55,
        }),
      );
    }

    // ---- Cluster Circle Layer ----
    final hasCluster = await _mapboxMap!.style.styleLayerExists(_clusterCircleLayerId);
    if (!hasCluster) {
      await _mapboxMap!.style.addStyleLayer(
        jsonEncode({
          'id': _clusterCircleLayerId,
          'type': 'circle',
          'source': _clusterSourceId,
          'filter': ['has', 'point_count'],
          'paint': {
            'circle-color': [
              'step', ['get', 'point_count'],
              '#F97316', 5,
              '#E85B2A', 15,
              '#CC3D0E'
            ],
            'circle-radius': [
              'step', ['get', 'point_count'],
              22, 5,
              30, 15,
              38
            ],
            'circle-stroke-width': 3,
            'circle-stroke-color': '#FFFFFF',
            'circle-opacity': 0.92,
          },
        }),
        null,
      );
    }

    // ---- Cluster Count Label Layer ----
    final hasCount = await _mapboxMap!.style.styleLayerExists(_clusterCountLayerId);
    if (!hasCount) {
      await _mapboxMap!.style.addStyleLayer(
        jsonEncode({
          'id': _clusterCountLayerId,
          'type': 'symbol',
          'source': _clusterSourceId,
          'filter': ['has', 'point_count'],
          'layout': {
            'text-field': ['get', 'point_count_abbreviated'],
            'text-size': 14,
            'text-font': ['DIN Offc Pro Medium', 'Arial Unicode MS Bold'],
          },
          'paint': {
            'text-color': '#FFFFFF',
          },
        }),
        null,
      );
    }

    // ---- Unclustered Point Layer ----
    final hasUncluster = await _mapboxMap!.style.styleLayerExists(_unclusteredLayerId);
    if (!hasUncluster) {
      await _mapboxMap!.style.addStyleLayer(
        jsonEncode({
          'id': _unclusteredLayerId,
          'type': 'circle',
          'source': _clusterSourceId,
          'filter': ['!', ['has', 'point_count']],
          'paint': {
            'circle-color': '#E85B2A',
            'circle-radius': 10,
            'circle-stroke-width': 2,
            'circle-stroke-color': '#FFFFFF',
          },
        }),
        null,
      );
    }
  }

  Future<void> _onMapTap(MapContentGestureContext ctx) async {
    if (_mapboxMap == null) return;
    final screenPoint = ctx.touchPosition;

    // helper: query features ในรัศมี
    Future<List<QueriedRenderedFeature?>> query(String layerId) =>
        _mapboxMap!.queryRenderedFeatures(
          RenderedQueryGeometry.fromScreenBox(ScreenBox(
            min: ScreenCoordinate(x: screenPoint.x - 22, y: screenPoint.y - 22),
            max: ScreenCoordinate(x: screenPoint.x + 22, y: screenPoint.y + 22),
          )),
          RenderedQueryOptions(layerIds: [layerId]),
        );

    // เช็ค cluster ก่อน → zoom in
    final clusterHits = await query(_clusterCircleLayerId);
    if (clusterHits.isNotEmpty) {
      final rawFeature = clusterHits.first?.queriedFeature.feature;
      if (rawFeature != null) {
        final geomMap = rawFeature['geometry'] as Map?;
        if (geomMap != null && geomMap['type'] == 'Point') {
          final coords = geomMap['coordinates'] as List?;
          if (coords != null && coords.length >= 2) {
            final lng = (coords[0] as num).toDouble();
            final lat = (coords[1] as num).toDouble();
            final currentZoom = (await _mapboxMap!.getCameraState()).zoom;
            await _mapboxMap!.flyTo(
              CameraOptions(
                center: Point(coordinates: Position(lng, lat)),
                zoom: currentZoom + 2.5,
              ),
              MapAnimationOptions(duration: 500),
            );
          }
        }
      }
      return;
    }

    // เช็ค unclustered pin → เปิด detail sheet
    final pinHits = await query(_unclusteredLayerId);
    if (pinHits.isNotEmpty && mounted) {
      final rawFeature = pinHits.first?.queriedFeature.feature;
      if (rawFeature != null) {
        final props = rawFeature['properties'] as Map?;
        if (props != null) {
          final id = props['id']?.toString() ?? '';
          // foodTypes อาจถูก encode เป็น String โดย Mapbox
          dynamic foodTypes = props['foodTypes'];
          if (foodTypes is String) {
            try { foodTypes = jsonDecode(foodTypes); } catch (_) { foodTypes = []; }
          }
          final data = <String, dynamic>{
            'name': props['name'],
            'desc': props['desc'],
            'imagePath': props['imagePath'],
            'avgRating': props['avgRating'],
            'openTime': props['openTime'],
            'closeTime': props['closeTime'],
            'category': props['category'],
            'foodTypes': foodTypes ?? [],
            'latitude': props['latitude'],
            'longitude': props['longitude'],
          };
          showRestaurantDetailSheet(
            context: context,
            data: data,
            restaurantId: id,
            currentUserId: currentUserId,
            userRole: _userRole,
          );
        }
      }
    }
  }

  // ========== BUILD ==========

  @override
  Widget build(BuildContext context) {
    final centerLat = currentPosition?.latitude ?? _kuLat;
    final centerLng = currentPosition?.longitude ?? _kuLng;

    return Scaffold(
      backgroundColor: const Color(0xFFFFD54F),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD54F),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'ร้านใกล้ฉัน',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE85B2A),
          labelColor: const Color(0xFFE85B2A),
          unselectedLabelColor: Colors.black54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.list_alt_rounded), text: 'รายการ'),
            Tab(icon: Icon(Icons.map_rounded), text: 'แผนที่'),
          ],
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildListView(),
                  _buildMapView(centerLat, centerLng),
                ],
              ),
      ),
    );
  }

  // ========== LIST VIEW ==========

  Widget _buildListView() {
    return Column(
      children: [
        // foodType Chip Filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('ทั้งหมด'),
                    selected: selectedFoodType == 'all',
                    onSelected: (_) => setState(() => selectedFoodType = 'all'),
                    selectedColor: Colors.orange,
                    labelStyle: TextStyle(
                      color: selectedFoodType == 'all' ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600, fontSize: 13,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Colors.white),
                    ),
                  ),
                ),
                ..._allFoodTypes.map((ft) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(ft),
                    selected: selectedFoodType == ft,
                    onSelected: (_) => setState(() => selectedFoodType = ft),
                    selectedColor: Colors.orange,
                    labelStyle: TextStyle(
                      color: selectedFoodType == ft ? Colors.white : Colors.black87,
                      fontSize: 13,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Colors.white),
                    ),
                  ),
                )),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(35),
                topRight: Radius.circular(35),
              ),
            ),
            child: Column(
              children: [
                if (locationNote.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.orange.shade50,
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            locationNote,
                            style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('restaurants').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('ไม่มีข้อมูลร้านอาหาร'));
                      }

                      final docs = snapshot.data!.docs;
                      final List<Map<String, dynamic>> nearbyRestaurants = [];

                      for (final doc in docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final lat = (data['latitude'] as num?)?.toDouble();
                        final lng = (data['longitude'] as num?)?.toDouble();
                        if (lat == null || lng == null || currentPosition == null) continue;

                        final distanceInMeters = geo.Geolocator.distanceBetween(
                          currentPosition!.latitude, currentPosition!.longitude, lat, lng,
                        );
                        if (distanceInMeters <= 1500) {
                          nearbyRestaurants.add({
                            'id': doc.id, 'data': data,
                            'distanceKm': distanceInMeters / 1000,
                          });
                        }
                      }

                      nearbyRestaurants.sort(
                        (a, b) => (a['distanceKm'] as double).compareTo(b['distanceKm'] as double),
                      );

                      final filtered = selectedFoodType == 'all'
                          ? nearbyRestaurants
                          : nearbyRestaurants.where((item) {
                              final d = item['data'] as Map<String, dynamic>;
                              final ft = List<String>.from(d['foodTypes'] ?? []);
                              return ft.contains(selectedFoodType);
                            }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              selectedFoodType == 'all'
                                  ? 'ไม่พบร้านอาหารในระยะ 1.5 กม.'
                                  : 'ไม่พบร้าน "$selectedFoodType" ในระยะ 1.5 กม.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: filtered.length,
                        separatorBuilder: (context, idx) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final data = item['data'] as Map<String, dynamic>;
                          final distanceKm = item['distanceKm'] as double;
                          final id = item['id'] as String;

                          final String name = data['name'] ?? 'ไม่มีชื่อร้าน';
                          final String desc = data['desc'] ?? '';
                          final String? imagePath = data['imagePath'] as String?;
                          final String rating = data['avgRating']?.toString() ?? '0.0';
                          final List<dynamic> foodTypes = data['foodTypes'] ?? [];

                          return InkWell(
                            onTap: () => showRestaurantDetailSheet(
                              context: context,
                              data: data,
                              restaurantId: id,
                              currentUserId: currentUserId,
                              userRole: _userRole,
                              distanceKm: distanceKm,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.orange.shade100),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 10, offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 82, height: 82,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: StorageImageWidget(
                                      storagePath: imagePath, fit: BoxFit.cover,
                                      width: 82, height: 82,
                                      placeholder: const Icon(Icons.restaurant, color: Colors.grey),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name,
                                          maxLines: 1, overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(desc,
                                          maxLines: 1, overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                        if (foodTypes.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 5),
                                            child: Wrap(
                                              spacing: 4,
                                              children: foodTypes.take(3).map((t) => Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.shade50,
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: Colors.orange.shade200),
                                                ),
                                                child: Text(t.toString(),
                                                  style: TextStyle(fontSize: 10, color: Colors.orange.shade700),
                                                ),
                                              )).toList(),
                                            ),
                                          ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on_outlined, size: 14, color: Colors.orange),
                                            const SizedBox(width: 2),
                                            Text('${distanceKm.toStringAsFixed(2)} กม.',
                                              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 12),
                                            ),
                                            const SizedBox(width: 10),
                                            const Icon(Icons.star, size: 14, color: Colors.orange),
                                            const SizedBox(width: 2),
                                            Text(rating, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.grey),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ========== MAP VIEW ==========

  Widget _buildMapView(double centerLat, double centerLng) {
    return Stack(
      children: [
        MapWidget(
          key: const ValueKey('nearbyClusterMap'),
          styleUri: MapboxStyles.MAPBOX_STREETS,
          cameraOptions: CameraOptions(
            center: Point(coordinates: Position(centerLng, centerLat)),
            zoom: 14.5,
          ),
          onMapCreated: (map) async {
            _mapboxMap = map;
            await _mapboxMap!.gestures.updateSettings(
              GesturesSettings(rotateEnabled: false),
            );
          },
          onStyleLoadedListener: (StyleLoadedEventData _) async {
            _mapStyleReady = true;
            if (_restaurantsLoaded) {
              await _setupClusterOnMap();
            }
            // วาง dot ตำแหน่งปัจจุบัน
            if (currentPosition != null) {
              final myDot = await generateLocationMarkerPng(size: 80);
              final annotMgr = await _mapboxMap!.annotations.createPointAnnotationManager();
              await annotMgr.create(PointAnnotationOptions(
                geometry: Point(coordinates: Position(currentPosition!.longitude, currentPosition!.latitude)),
                image: myDot,
                iconSize: 0.48,
                iconAnchor: IconAnchor.CENTER,
              ));
            }
          },
          onTapListener: _onMapTap,
        ),

        // Legend
        Positioned(
          bottom: 20,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  Container(width: 18, height: 18, decoration: const BoxDecoration(color: Color(0xFFE85B2A), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  const Text('กลุ่มร้านอาหาร', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  Container(width: 14, height: 14, decoration: const BoxDecoration(color: Color(0xFFE85B2A), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  const Text('ร้านอาหาร', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(color: Colors.blue.shade400, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  const Text('ตำแหน่งของคุณ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ],
            ),
          ),
        ),

        // Hint
        Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'กดวงกลมเพื่อซูมเข้า • กดหมุดเพื่อดูรายละเอียด',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
