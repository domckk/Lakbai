import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/colors.dart';

const _localImages = [
  'assets/images/bangui.jpg',
  'assets/images/paoay-church.jpg',
  'assets/images/kapurpurawan.jpg',
  'assets/images/pagudpud.jpg',
  'assets/images/paoay-lake.jpg',
  'assets/images/laoag-sand_dunes.jpg',
  'assets/images/batac-riverside.jpg',
  'assets/images/vintar.jpg',
];

class DestinationsScreen extends StatefulWidget {
  const DestinationsScreen({super.key});

  @override
  State<DestinationsScreen> createState() => _DestinationsScreenState();
}

class _DestinationsScreenState extends State<DestinationsScreen> {
  final _dio = buildDio();
  List<dynamic> _destinations = [];
  bool _loading = true;

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

  void _showDetail(Map<String, dynamic> dest) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DestinationSheet(dest: dest),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TrailColors.background,
      appBar: AppBar(
        title: const Text('Destinations'),
        backgroundColor: TrailColors.background,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _destinations.isEmpty
                  ? Center(child: Text('No destinations yet', style: TextStyle(color: TrailColors.onSurfaceMuted)))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _destinations.length,
                      itemBuilder: (_, i) => _DestCard(
                        dest: _destinations[i] as Map<String, dynamic>,
                        index: i,
                        onTap: () => _showDetail(_destinations[i] as Map<String, dynamic>),
                      ),
                    ),
            ),
    );
  }
}

class _DestCard extends StatelessWidget {
  const _DestCard({required this.dest, required this.index, required this.onTap});
  final Map<String, dynamic> dest;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final coverUrl = (dest['heroImageUrl'] ?? dest['coverImageUrl']) as String?;
    final questCount = (dest['questCount'] as int?) ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: TrailColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorWidget: (_, __, ___) => _localFallback(index),
                    )
                  : _localFallback(index),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dest['name'] ?? '', style: const TextStyle(color: TrailColors.onBackground, fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(dest['region'] ?? '', style: TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.flag_rounded, size: 12, color: TrailColors.primary),
                      const SizedBox(width: 4),
                      Text('$questCount quests', style: TextStyle(color: TrailColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: (index * 50).ms, duration: 300.ms),
    );
  }

  Widget _localFallback(int idx) => Image.asset(
    _localImages[idx % _localImages.length],
    fit: BoxFit.cover,
    width: double.infinity,
    errorBuilder: (_, __, ___) => Container(
      color: TrailColors.surfaceAlt,
      child: const Center(child: Icon(Icons.landscape_rounded, size: 40, color: Colors.white24)),
    ),
  );
}

class _DestinationSheet extends StatefulWidget {
  const _DestinationSheet({required this.dest});
  final Map<String, dynamic> dest;

  @override
  State<_DestinationSheet> createState() => _DestinationSheetState();
}

class _DestinationSheetState extends State<_DestinationSheet> {
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
    final dest = widget.dest;
    final coverUrl = (dest['heroImageUrl'] ?? dest['coverImageUrl']) as String?;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
                child: CachedNetworkImage(imageUrl: coverUrl, height: 180, fit: BoxFit.cover, width: double.infinity),
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
                  Text('Quests', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
                  const SizedBox(height: 12),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_quests.isEmpty)
                    Text('No quests available', style: TextStyle(color: TrailColors.onSurfaceMuted))
                  else
                    ..._quests.map((q) {
                      final quest = q as Map<String, dynamic>;
                      return ListTile(
                        onTap: () { Navigator.pop(context); context.go('/quests/${quest['id']}'); },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                        title: Text(quest['title'] ?? '', style: const TextStyle(color: TrailColors.onBackground, fontWeight: FontWeight.w600)),
                        subtitle: Text('+${quest['xpReward'] ?? 0} XP · ${quest['estDurationMin'] ?? 0} min', style: TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: TrailColors.onSurfaceMuted),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
