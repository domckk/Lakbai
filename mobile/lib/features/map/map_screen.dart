import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong2.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/colors.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _dio = buildDio();
  List<dynamic> _destinations = [];
  bool _loading = true;

  static const _ilocosNorte = LatLng(18.1979, 120.5936);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _dio.get('/destinations');
      setState(() => _destinations = res.data as List);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TrailColors.background,
      appBar: AppBar(title: const Text('Map'), backgroundColor: TrailColors.background),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                initialCenter: _ilocosNorte,
                initialZoom: 10,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.lakbai',
                ),
                MarkerLayer(
                  markers: _destinations.map((d) {
                    final dest = d as Map<String, dynamic>;
                    final lat = (dest['lat'] as num?)?.toDouble();
                    final lng = (dest['lng'] as num?)?.toDouble();
                    if (lat == null || lng == null) return null;
                    return Marker(
                      point: LatLng(lat, lng),
                      width: 120,
                      height: 60,
                      child: GestureDetector(
                        onTap: () => _showDestinationInfo(dest),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: TrailColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(dest['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                            ),
                            const Icon(Icons.location_on_rounded, color: TrailColors.primary, size: 20),
                          ],
                        ),
                      ),
                    );
                  }).whereType<Marker>().toList(),
                ),
              ],
            ),
    );
  }

  void _showDestinationInfo(Map<String, dynamic> dest) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TrailColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dest['name'] ?? '', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(dest['region'] ?? '', style: TextStyle(color: TrailColors.onSurfaceMuted)),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.flag_rounded, size: 16, color: TrailColors.primary),
                const SizedBox(width: 6),
                Text('${dest['questCount'] ?? 0} quests available', style: TextStyle(color: TrailColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () { Navigator.pop(context); context.go('/destinations'); },
              child: const Text('View Destination'),
            ),
          ],
        ),
      ),
    );
  }
}
