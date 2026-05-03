import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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
  final _dio = buildDio();
  List<dynamic> _quests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadQuests();
  }

  Future<void> _loadQuests() async {
    try {
      final slug = widget.dest['slug'] ?? widget.dest['id'];
      final res = await _dio.get('/quests?destinationSlug=$slug');
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
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            if (coverUrl != null)
              ClipRRect(
                child: CachedNetworkImage(imageUrl: coverUrl, height: 160, fit: BoxFit.cover, width: double.infinity),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dest['name'] ?? '', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(dest['region'] ?? '', style: TextStyle(color: TrailColors.onSurfaceMuted)),
                  if (dest['description'] != null) ...[
                    const SizedBox(height: 12),
                    Text(dest['description'], style: TextStyle(color: TrailColors.onSurface, height: 1.5)),
                  ],
                  const SizedBox(height: 20),
                  Text('Quests', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_quests.isEmpty)
                    Text('No quests available', style: TextStyle(color: TrailColors.onSurfaceMuted))
                  else
                    ..._quests.take(4).map((q) {
                      final quest = q as Map<String, dynamic>;
                      return ListTile(
                        onTap: () { Navigator.pop(context); context.go('/quests/${quest['id']}'); },
                        contentPadding: EdgeInsets.zero,
                        title: Text(quest['title'] ?? '', style: const TextStyle(color: TrailColors.onBackground, fontWeight: FontWeight.w600)),
                        subtitle: Text('+${quest['xpReward'] ?? 0} XP', style: TextStyle(color: TrailColors.accent, fontSize: 12, fontWeight: FontWeight.w700)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: TrailColors.onSurfaceMuted),
                      );
                    }),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/quests?destination=$slug&destinationName=${Uri.encodeComponent(name)}');
                    },
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
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
