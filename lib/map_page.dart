import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;

const String mapboxToken = String.fromEnvironment('ACCESS_TOKEN');

class RouteMapPage extends StatefulWidget {
  final String destName;
  final double destLat;
  final double destLng;

  const RouteMapPage({
    super.key,
    required this.destName,
    required this.destLat,
    required this.destLng,
  });

  @override
  State<RouteMapPage> createState() => _RouteMapPageState();
}

class _RouteMapPageState extends State<RouteMapPage> {
  MapboxMap? _map;
  PointAnnotationManager? _points;

  Uint8List? _markerBytes;
  StreamSubscription<geo.Position>? _posSub;
  PointAnnotation? _myMarker;

  // throttle การอัปเดตเส้นทาง
  DateTime _lastRouteUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  static const _routeUpdateMinSeconds = 15;

  static const String _routeSourceId = "route_source";
  static const String _routeLayerId = "route_layer";

  bool _styleReady = false;
  bool _didInitAfterStyle = false;
  bool _loadingRoute = true;

  double? _routeDistanceMeters;
  double? _routeDurationSeconds;

  @override
  void initState() {
    super.initState();
    _loadMarkerSafe();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _points?.deleteAll();
    super.dispose();
  }

  // ป้องกันแอปค้างถ้าหาไฟล์รูปไม่เจอ
  Future<void> _loadMarkerSafe() async {
    try {
      final byteData = await rootBundle.load('assets/images/marker.png');
      _markerBytes = byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint("ไม่พบรูป marker.png: จะใช้ Marker เริ่มต้นแทน");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Stack(
        children: [
          // ===== 1. Fullscreen Map =====
          MapWidget(
            key: const ValueKey("routeMap"),
            styleUri: MapboxStyles.MAPBOX_STREETS,
            cameraOptions: CameraOptions(
              center: Point(
                coordinates: Position(widget.destLng, widget.destLat),
              ),
              zoom: 14.5, // ซูมออกนิดนึงให้เห็นภาพรวม
            ),
            onMapCreated: (map) async {
              _map = map;
              _points = await _map!.annotations.createPointAnnotationManager();
            },
            onStyleLoadedListener: (StyleLoadedEventData data) async {
              if (_didInitAfterStyle) return;
              _didInitAfterStyle = true;
              _styleReady = true;

              await _ensureRouteLayer();
              await _initializeRouteAndLocation();
            },
          ),

          // ===== 2. Top Header (ปุ่ม Back & My Location) =====
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _FloatingIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                _FloatingIconButton(
                  icon: Icons.my_location_rounded,
                  onTap: () async {
                    final p = await _getCurrentPositionSafe();
                    if (p != null) {
                      _map?.flyTo(
                        CameraOptions(
                          center: Point(coordinates: Position(p.longitude, p.latitude)),
                          zoom: 16,
                        ),
                        MapAnimationOptions(duration: 600),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // ===== 3. Bottom Info Card (ข้อมูลเส้นทางแบบคลีนๆ) =====
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 16,
            right: 16,
            child: _InfoCard(
              title: widget.destName,
              loading: _loadingRoute,
              distanceMeters: _routeDistanceMeters,
              durationSeconds: _routeDurationSeconds,
            ),
          ),
        ],
      ),
    );
  }

  // รวบรวมคำสั่งหลังโหลด Map เสร็จไว้ด้วยกัน
  Future<void> _initializeRouteAndLocation() async {
    final myPos = await _getCurrentPositionSafe();
    if (myPos == null) {
      if (mounted) setState(() => _loadingRoute = false);
      return; // หาสถานที่ไม่ได้ (อาจจะเพราะไม่เปิด GPS)
    }

    await _placeMarkers(myPos);
    await _safeDrawRoute(fromLat: myPos.latitude, fromLng: myPos.longitude);

    // ซูมให้อยู่กึ่งกลางระหว่างเรากับร้าน
    final midLat = (myPos.latitude + widget.destLat) / 2;
    final midLng = (myPos.longitude + widget.destLng) / 2;
    await _map?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(midLng, midLat)),
        zoom: 13.0,
      ),
      MapAnimationOptions(duration: 800),
    );

    _startLocationUpdates();
  }

  // ป้องกันการค้างโดยใส่ Timeout 5 วินาที
  Future<geo.Position?> _getCurrentPositionSafe() async {
    bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    geo.LocationPermission perm = await geo.Geolocator.checkPermission();
    if (perm == geo.LocationPermission.denied) {
      perm = await geo.Geolocator.requestPermission();
    }
    if (perm == geo.LocationPermission.denied || perm == geo.LocationPermission.deniedForever) {
      return null;
    }

    try {
      // ใส่เวลาจำกัด (Timeout) ป้องกันแอปค้าง
      return await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      // ถ้าค้าง หรือหาสัญญาณไม่เจอ ให้ดึงค่าล่าสุดเท่าที่หาได้
      return await geo.Geolocator.getLastKnownPosition();
    }
  }

  Future<void> _placeMarkers(geo.Position myPos) async {
    if (_points == null) return;
    await _points!.deleteAll();

    // ดึงรูปรถ/พิน ถ้าไม่มีจะข้ามไปไม่พัง
    if (_markerBytes != null) {
      await _points!.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(widget.destLng, widget.destLat)),
          image: _markerBytes!,
          iconSize: 0.22,
          iconAnchor: IconAnchor.BOTTOM,
          textField: widget.destName,
          textOffset: [0, 1.6],
          textSize: 12,
        ),
      );

      _myMarker = await _points!.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(myPos.longitude, myPos.latitude)),
          image: _markerBytes!,
          iconSize: 0.20,
          iconAnchor: IconAnchor.BOTTOM,
        ),
      );
    }
  }

  void _startLocationUpdates() {
    _posSub?.cancel();
    _posSub = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 10, // อัปเดตเมื่อขยับ 10 เมตร (ประหยัดแบต)
      ),
    ).listen((geo.Position pos) async {
      if (!mounted || _points == null || _myMarker == null) return;

      _myMarker!.geometry = Point(coordinates: Position(pos.longitude, pos.latitude));
      await _points!.update(_myMarker!);

      final now = DateTime.now();
      if (now.difference(_lastRouteUpdate).inSeconds >= _routeUpdateMinSeconds) {
        _lastRouteUpdate = now;
        await _safeDrawRoute(fromLat: pos.latitude, fromLng: pos.longitude);
      }
    });
  }

  Future<void> _ensureRouteLayer() async {
    if (_map == null) return;
    final hasSource = await _map!.style.styleSourceExists(_routeSourceId);
    if (!hasSource) {
      await _map!.style.addSource(GeoJsonSource(id: _routeSourceId, data: _emptyLineGeoJson()));
    }
    final hasLayer = await _map!.style.styleLayerExists(_routeLayerId);
    if (!hasLayer) {
      await _map!.style.addLayer(
        LineLayer(
          id: _routeLayerId,
          sourceId: _routeSourceId,
          lineJoin: LineJoin.ROUND,
          lineCap: LineCap.ROUND,
          lineWidth: 5.0,
          lineColor: 0xFF2196F3, // สีฟ้าที่ดูสะอาดตา
        ),
      );
    }
  }

  String _emptyLineGeoJson() {
    return jsonEncode({
      "type": "FeatureCollection",
      "features": [
        {"type": "Feature", "properties": {}, "geometry": {"type": "LineString", "coordinates": []}}
      ]
    });
  }

  Future<void> _safeDrawRoute({required double fromLat, required double fromLng}) async {
    if (!_styleReady) return;
    if (mounted) setState(() => _loadingRoute = true);
    
    try {
      final url = Uri.parse(
        "https://api.mapbox.com/directions/v5/mapbox/driving/"
        "$fromLng,$fromLat;${widget.destLng},${widget.destLat}"
        "?geometries=geojson&overview=full&access_token=$mapboxToken",
      );

      final res = await http.get(url).timeout(const Duration(seconds: 10)); // ป้องกันค้างจากการดึงเน็ต
      if (res.statusCode == 200) {
        final jsonBody = jsonDecode(res.body);
        if (jsonBody["routes"] != null && jsonBody["routes"].isNotEmpty) {
          final route = jsonBody["routes"][0];
          
          if (mounted) {
            setState(() {
              _routeDistanceMeters = (route["distance"] as num).toDouble();
              _routeDurationSeconds = (route["duration"] as num).toDouble();
            });
          }

          final coords = (route["geometry"]["coordinates"] as List)
              .map((c) => [(c[0] as num).toDouble(), (c[1] as num).toDouble()]).toList();

          final geojson = jsonEncode({
            "type": "FeatureCollection",
            "features": [{"type": "Feature", "properties": {}, "geometry": {"type": "LineString", "coordinates": coords}}]
          });

          await _map!.style.setStyleSourceProperty(_routeSourceId, "data", geojson);
        }
      }
    } catch (e) {
      debugPrint("DRAW ROUTE ERROR: $e");
    } finally {
      if (mounted) setState(() => _loadingRoute = false);
    }
  }
}

// Widget สำหรับปุ่มลอยตัว (Floating Action Button สไตล์มินิมอล)
class _FloatingIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FloatingIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(child: Icon(icon, color: Colors.black87, size: 22)),
        ),
      ),
    );
  }
}

// Widget สำหรับแสดงข้อมูลเส้นทางด้านล่าง
class _InfoCard extends StatelessWidget {
  final String title;
  final bool loading;
  final double? distanceMeters;
  final double? durationSeconds;

  const _InfoCard({
    required this.title,
    required this.loading,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  String _fmtDistance(double meters) {
    if (meters >= 1000) return "${(meters / 1000).toStringAsFixed(1)} กม.";
    return "${meters.toStringAsFixed(0)} ม.";
  }

  String _fmtDuration(double seconds) {
    final totalMin = (seconds / 60).round();
    if (totalMin < 60) return "$totalMin นาที";
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    return "$h ชม. ${m > 0 ? '$m นาที' : ''}";
  }

  @override
  Widget build(BuildContext context) {
    final hasData = distanceMeters != null && durationSeconds != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_car_rounded, color: Colors.blue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                if (loading)
                  const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Text(
                    hasData ? "${_fmtDistance(distanceMeters!)} • ${_fmtDuration(durationSeconds!)}" : "กำลังคำนวณเส้นทาง...",
                    style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}