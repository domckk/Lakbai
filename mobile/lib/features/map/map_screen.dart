import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/colors.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _dio     = buildDio();
  final _mapCtrl = MapController();

  List<dynamic> _destinations = [];
  bool          _loading      = true;
  Position?     _userPos;
  StreamSubscription<Position>? _posStream;

  static const _ilocosNorte = LatLng(18.1979, 120.5936);

  @override
  void initState() {
    super.initState();
    _load();
    _startLocation();
  }

  @override
  void dispose() {
    _posStream?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await _dio.get('/destinations');
      if (mounted) {
        setState(() { _destinations = res.data as List; _loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startLocation() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) return;

    _posStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      if (mounted) setState(() => _userPos = pos);
    });
  }

  void _centerOnUser() {
    final pos = _userPos;
    if (pos == null) return;
    _mapCtrl.move(LatLng(pos.latitude, pos.longitude), 15);
  }

  @override
  Widget build(BuildContext context) {
    final userPoint = _userPos != null
        ? LatLng(_userPos!.latitude, _userPos!.longitude)
        : null;

    return Scaffold(
      backgroundColor: TrailColors.background,
      appBar: AppBar(
        title: const Text('Map'),
        backgroundColor: TrailColors.background,
        leading: context.canPop() ? const BackButton() : null,
        actions: [
          if (_userPos != null)
            IconButton(
              icon: const Icon(Icons.my_location_rounded,
                  color: TrailColors.primary),
              onPressed: _centerOnUser,
              tooltip: 'Center on me',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapCtrl,
                  options: const MapOptions(
                    initialCenter: _ilocosNorte,
                    initialZoom: 10,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.lakbai',
                    ),

                    // Destination markers
                    MarkerLayer(
                      markers: _destinations.map((d) {
                        final dest = d as Map<String, dynamic>;
                        final lat = (dest['lat'] as num?)?.toDouble();
                        final lng = (dest['lng'] as num?)?.toDouble();
                        if (lat == null || lng == null) return null;
                        return Marker(
                          point: LatLng(lat, lng),
                          width: 130,
                          height: 60,
                          child: GestureDetector(
                            onTap: () => _showDestinationInfo(dest),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: TrailColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: TrailColors.orangeShadow,
                                          blurRadius: 8,
                                          offset: Offset(0, 3)),
                                    ],
                                  ),
                                  child: Text(
                                    dest['name'] ?? '',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.location_on_rounded,
                                    color: TrailColors.primary, size: 22),
                              ],
                            ),
                          ),
                        );
                      }).whereType<Marker>().toList(),
                    ),

                    // User location blue dot
                    if (userPoint != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: userPoint,
                            width: 22,
                            height: 22,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black26, blurRadius: 6),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                // Locate-me FAB when GPS acquired
                if (_userPos != null)
                  Positioned(
                    bottom: 24,
                    right: 16,
                    child: FloatingActionButton.small(
                      onPressed: _centerOnUser,
                      backgroundColor: Colors.white,
                      foregroundColor: TrailColors.primary,
                      child:
                          const Icon(Icons.my_location_rounded, size: 22),
                    ),
                  ),
              ],
            ),
    );
  }

  void _showDestinationInfo(Map<String, dynamic> dest) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MapDestinationSheet(dest: dest),
    );
  }
}

class _MapDestinationSheet extends StatefulWidget {
  const _MapDestinationSheet({required this.dest});
  final Map<String, dynamic> dest;

  @override
  State<_MapDestinationSheet> createState() => _MapDestinationSheetState();
}

class _MapDestinationSheetState extends State<_MapDestinationSheet> {
  final _dio    = buildDio();
  List<dynamic> _quests  = [];
  bool          _loading = true;

  @override
  void initState() {
    super.initState();
    _loadQuests();
  }

  Future<void> _loadQuests() async {
    try {
      final slug = widget.dest['slug'] ?? widget.dest['id'];
      final res  = await _dio.get('/quests?destinationSlug=$slug');
      setState(() => _quests = res.data as List);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dest     = widget.dest;
    final coverUrl = (dest['heroImageUrl'] ?? dest['coverImageUrl']) as String?;
    final slug     = dest['slug'] as String? ?? '';
    final name     = dest['name'] as String? ?? '';

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.35,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: TrailColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: ctrl,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: TrailColors.peach,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            if (coverUrl != null)
              ClipRRect(
                child: CachedNetworkImage(
                    imageUrl: coverUrl,
                    height: 160,
                    fit: BoxFit.cover,
                    width: double.infinity),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dest['name'] ?? '',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place_rounded,
                          size: 14, color: TrailColors.onSurfaceMuted),
                      const SizedBox(width: 4),
                      Text(dest['region'] ?? '',
                          style: const TextStyle(
                              color: TrailColors.onSurfaceMuted,
                              fontSize: 13)),
                    ],
                  ),
                  if (dest['description'] != null) ...[
                    const SizedBox(height: 12),
                    Text(dest['description'],
                        style: const TextStyle(
                            color: TrailColors.onSurface,
                            height: 1.5,
                            fontSize: 14)),
                  ],
                  const SizedBox(height: 20),
                  const Text('Quests',
                      style: TextStyle(
                          color: TrailColors.onBackground,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  const SizedBox(height: 12),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_quests.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: TrailColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Center(
                          child: Text('No quests available',
                              style: TextStyle(
                                  color: TrailColors.onSurfaceMuted))),
                    )
                  else
                    ..._quests.take(4).map((q) {
                      final quest = q as Map<String, dynamic>;
                      return ListTile(
                        onTap: () {
                          Navigator.pop(context);
                          context.go('/quests/${quest['id']}');
                        },
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                              color: TrailColors.primaryFaint,
                              borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.flag_rounded,
                              color: TrailColors.primary, size: 18),
                        ),
                        title: Text(quest['title'] ?? '',
                            style: const TextStyle(
                                color: TrailColors.onBackground,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        subtitle: Text('+${quest['xpReward'] ?? 0} XP',
                            style: const TextStyle(
                                color: TrailColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                        trailing: const Icon(Icons.chevron_right_rounded,
                            color: TrailColors.onSurfaceMuted),
                      );
                    }),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go(
                          '/quests?destination=$slug&destinationName=${Uri.encodeComponent(name)}');
                    },
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48)),
                    child: const Text('View all quests →'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
