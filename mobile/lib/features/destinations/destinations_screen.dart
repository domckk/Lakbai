import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/config.dart';
import '../../core/providers/destination_provider.dart';
import '../../core/theme/colors.dart';

// Slug-specific covers — used before falling back to the index-based list.
const _slugImages = <String, String>{
  'ilocos-norte':  'assets/images/ilocos-norte.jpg',
  'ilocos_norte':  'assets/images/ilocos-norte.jpg',
  'batac':         'assets/images/batac-riverside.jpg',
  'bangui':        'assets/images/bangui.jpg',
  'paoay':         'assets/images/paoay-church.jpg',
  'kapurpurawan':  'assets/images/kapurpurawan.jpg',
  'pagudpud':      'assets/images/pagudpud.jpg',
  'paoay-lake':    'assets/images/paoay-lake.jpg',
  'laoag':         'assets/images/laoag-sand_dunes.jpg',
  'vintar':        'assets/images/vintar.jpg',
};

// Index-based fallback list (used when no slug match found).
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

class DestinationsScreen extends ConsumerStatefulWidget {
  const DestinationsScreen({super.key});

  @override
  ConsumerState<DestinationsScreen> createState() => _DestinationsScreenState();
}

class _DestinationsScreenState extends ConsumerState<DestinationsScreen> {
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
      if (mounted) setState(() { _destinations = res.data as List; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showDetail(Map<String, dynamic> dest) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DestinationSheet(
        dest: dest,
        onChosen: (id) {
          // Optimistic update — UI responds instantly
          ref.read(activeDestinationProvider.notifier).choose(ActiveDestination(
            id: id,
            slug: dest['slug'] as String? ?? id,
            name: dest['name'] as String? ?? '',
          ));
          // Persist to the user's profile in the database (fire-and-forget)
          _dio.patch('/me', data: {'activeDestinationId': id}).catchError((_) {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.place_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('${dest['name']} set as your destination'),
                ],
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
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
              color: TrailColors.primary,
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
                      itemBuilder: (_, i) {
                        final dest = _destinations[i] as Map<String, dynamic>;
                        final chosenId = ref.watch(activeDestinationProvider)?.id;
                        return _DestCard(
                          dest: dest,
                          index: i,
                          isChosen: chosenId == dest['id']?.toString(),
                          onTap: () => _showDetail(dest),
                        );
                      },
                    ),
            ),
    );
  }
}

class _DestCard extends StatelessWidget {
  const _DestCard({required this.dest, required this.index, required this.onTap, this.isChosen = false});
  final Map<String, dynamic> dest;
  final int index;
  final VoidCallback onTap;
  final bool isChosen;

  @override
  Widget build(BuildContext context) {
    final coverUrl   = (dest['heroImageUrl'] ?? dest['coverImageUrl']) as String?;
    final questCount = (dest['questCount'] as num?)?.toInt() ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: TrailColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isChosen ? TrailColors.orange : TrailColors.peach,
            width: isChosen ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(color: TrailColors.peach60, blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: AppConfig.imageUrl(coverUrl),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorWidget: (_, __, ___) => _localFallback(index),
                        )
                      : _localFallback(index, slug: dest['slug'] as String?),
                  if (isChosen)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: TrailColors.primary, borderRadius: BorderRadius.circular(20)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_rounded, color: Colors.white, size: 11),
                            SizedBox(width: 3),
                            Text('Active', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dest['name'] ?? '', style: const TextStyle(color: TrailColors.onBackground, fontWeight: FontWeight.w700, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(dest['region'] ?? '', style: const TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.flag_rounded, size: 12, color: TrailColors.primary),
                      const SizedBox(width: 4),
                      Text('$questCount quests', style: const TextStyle(color: TrailColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _localFallback(int idx, {String? slug}) {
    final asset = (slug != null ? _slugImages[slug] : null)
        ?? _localImages[idx % _localImages.length];
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        color: TrailColors.surfaceAlt,
        child: const Center(child: Icon(Icons.landscape_rounded, size: 40, color: TrailColors.onSurfaceMuted)),
      ),
    );
  }
}

class _DestinationSheet extends StatefulWidget {
  const _DestinationSheet({required this.dest, this.onChosen});
  final Map<String, dynamic> dest;
  final void Function(String id)? onChosen;

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

  String _typeEmoji(String type) => const {
    'landmark':  '🏛️',
    'food':      '🍜',
    'cultural':  '🎭',
    'adventure': '⛰️',
    'heritage':  '🏺',
    'nature':    '🌿',
    'shopping':  '🛍️',
  }[type] ?? '🎯';

  @override
  Widget build(BuildContext context) {
    final dest     = widget.dest;
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
                decoration: BoxDecoration(color: TrailColors.peach, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            _buildSheetCover(dest, coverUrl),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dest['name'] ?? '', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place_rounded, size: 14, color: TrailColors.onSurfaceMuted),
                      const SizedBox(width: 4),
                      Text(dest['region'] ?? '', style: const TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 13)),
                    ],
                  ),
                  if (dest['description'] != null) ...[
                    const SizedBox(height: 12),
                    Text(dest['description'], style: const TextStyle(color: TrailColors.onSurface, height: 1.5, fontSize: 14)),
                  ],
                  const SizedBox(height: 20),
                  const Text('Available Quests', style: TextStyle(color: TrailColors.onBackground, fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 12),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_quests.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: TrailColors.surfaceAlt, borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text('No quests available', style: TextStyle(color: TrailColors.onSurfaceMuted))),
                    )
                  else
                    ..._quests.map((q) {
                      final quest      = q as Map<String, dynamic>;
                      final type       = (quest['questType'] as String?) ?? 'landmark';
                      final difficulty = (quest['difficulty'] as int?) ?? 1;
                      return GestureDetector(
                        onTap: () {
                          widget.onChosen?.call(widget.dest['id']?.toString() ?? '');
                          Navigator.pop(context);
                          context.push('/quests/${quest['id']}');
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: TrailColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: TrailColors.peach),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: TrailColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(child: Text(_typeEmoji(type), style: const TextStyle(fontSize: 18))),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(quest['title'] ?? '', style: const TextStyle(color: TrailColors.onBackground, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        ...List.generate(5, (i) => Icon(Icons.star_rounded, size: 9, color: i < difficulty ? TrailColors.accent : TrailColors.peach)),
                                        const SizedBox(width: 6),
                                        Text('+${quest['xpReward'] ?? 0} XP', style: const TextStyle(color: TrailColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: TrailColors.onSurfaceMuted, size: 18),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                    onPressed: () {
                      widget.onChosen?.call(widget.dest['id']?.toString() ?? '');
                      Navigator.pop(context);
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.place_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Set as my destination'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                    onPressed: () {
                      final slug   = widget.dest['slug'] as String? ?? '';
                      final name   = widget.dest['name'] as String? ?? '';
                      final destId = widget.dest['id']?.toString() ?? '';
                      widget.onChosen?.call(destId);
                      Navigator.pop(context);
                      context.go('/quests?destination=$slug&destinationName=${Uri.encodeComponent(name)}');
                    },
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

  // Cover image: network URL if available, local asset by slug, else nothing.
  Widget _buildSheetCover(Map<String, dynamic> dest, String? coverUrl) {
    if (coverUrl != null) {
      return ClipRRect(
        child: CachedNetworkImage(
          imageUrl: AppConfig.imageUrl(coverUrl),
          height: 180,
          fit: BoxFit.cover,
          width: double.infinity,
          errorWidget: (_, __, ___) => _slugFallback(dest),
        ),
      );
    }
    return _slugFallback(dest);
  }

  Widget _slugFallback(Map<String, dynamic> dest) {
    final slug  = dest['slug'] as String?;
    final asset = slug != null ? _slugImages[slug] : null;
    if (asset == null) return const SizedBox.shrink();
    return ClipRRect(
      child: Image.asset(asset, height: 180, fit: BoxFit.cover, width: double.infinity),
    );
  }
}
