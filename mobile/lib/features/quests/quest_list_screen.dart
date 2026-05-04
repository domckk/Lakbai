import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../core/config.dart';
import '../../core/providers/quests_provider.dart';
import '../../core/theme/colors.dart';

class QuestListScreen extends ConsumerStatefulWidget {
  const QuestListScreen({
    super.key,
    required this.destinationSlug,
    this.destinationName,
  });

  final String? destinationSlug;
  final String? destinationName;

  @override
  ConsumerState<QuestListScreen> createState() => _QuestListScreenState();
}

class _QuestListScreenState extends ConsumerState<QuestListScreen> {
  String _selectedType = 'all';
  int _selectedDifficulty = 0;
  Position? _userPosition;

  static const _types = [
    ('all',       'All'),
    ('heritage',  'Heritage'),
    ('adventure', 'Adventure'),
    ('nature',    'Nature'),
    ('landmark',  'Landmark'),
    ('cultural',  'Culture'),
    ('food',      'Food'),
    ('shopping',  'Shopping'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.destinationSlug != null) {
      // Fetch quest data into cache (no-op if already cached for this slug)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(questsNotifierProvider.notifier).fetch(widget.destinationSlug!);
      });
    }
    _requestLocation();
  }

  Future<void> _requestLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 5)),
      );
      if (mounted) setState(() => _userPosition = pos);
    } catch (_) {}
  }

  Future<void> _refresh() async {
    ref.read(questsNotifierProvider.notifier).invalidate();
    if (widget.destinationSlug != null) {
      await ref.read(questsNotifierProvider.notifier).fetch(widget.destinationSlug!);
    }
  }

  // Client-side filter applied to the cached full list.
  List<dynamic> _applyFilters(List<dynamic> all) {
    return all.where((q) {
      final quest = q as Map<String, dynamic>;
      final typeOk = _selectedType == 'all' || quest['questType'] == _selectedType;
      final diffOk = _selectedDifficulty == 0 || quest['difficulty'] == _selectedDifficulty;
      return typeOk && diffOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.destinationSlug == null) {
      return Scaffold(
        backgroundColor: TrailColors.background,
        appBar: AppBar(
          title: const Text('Quests'),
          backgroundColor: TrailColors.background,
          leading: context.canPop() ? const BackButton() : null,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: TrailColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.map_outlined, size: 40, color: TrailColors.primary),
                ),
                const SizedBox(height: 20),
                const Text('Choose a destination first', style: TextStyle(color: TrailColors.onBackground, fontSize: 20, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                const SizedBox(height: 10),
                const Text('Quests are tied to a destination. Pick one to see the missions available there.', style: TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 14, height: 1.5), textAlign: TextAlign.center),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => context.push('/destinations'),
                  icon: const Icon(Icons.place_rounded),
                  label: const Text('Browse Destinations'),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
          ),
        ),
      );
    }

    final questsState = ref.watch(questsNotifierProvider);
    final isRelevant  = questsState.slug == widget.destinationSlug;
    final allQuests   = isRelevant ? questsState.quests : const [];
    final loading     = isRelevant ? questsState.loading : true;
    final filtered    = _applyFilters(allQuests);

    return Scaffold(
      backgroundColor: TrailColors.background,
      appBar: AppBar(
        title: const Text('Quests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: TrailColors.onBackground)),
        backgroundColor: TrailColors.background,
        leading: context.canPop() ? const BackButton() : null,
      ),
      body: Column(
        children: [
          _buildDestinationBanner(),
          _buildTypeFilter(),
          _buildDifficultyFilter(),
          Expanded(
            child: loading && allQuests.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    color: TrailColors.primary,
                    onRefresh: _refresh,
                    child: filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('📍', style: TextStyle(fontSize: 48)),
                                const SizedBox(height: 12),
                                const Text('No quests found', style: TextStyle(color: TrailColors.onBackground, fontSize: 16, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                const Text('Try adjusting your filters.', style: TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 13)),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) => _QuestCard(
                              quest: filtered[i] as Map<String, dynamic>,
                              index: i,
                              userPosition: _userPosition,
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationBanner() {
    if (widget.destinationName == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: TrailColors.brown,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: [BoxShadow(color: TrailColors.brownShadow, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: const Color(0x2EFF8C3B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.place_rounded, color: TrailColors.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Exploring', style: TextStyle(color: Color(0xB3FFD4A8), fontSize: 11, fontWeight: FontWeight.w500)),
                const SizedBox(height: 1),
                Text(widget.destinationName!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/destinations'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0x2EFF8C3B),
                borderRadius: BorderRadius.circular(10),
                border: const Border.fromBorderSide(BorderSide(color: Color(0x4DFF8C3B))),
              ),
              child: const Text('Change', style: TextStyle(color: TrailColors.orange, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.05, end: 0);
  }

  Widget _buildTypeFilter() {
    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _types.length,
        itemBuilder: (_, i) {
          final t = _types[i];
          final selected = t.$1 == _selectedType;
          return GestureDetector(
            onTap: () => setState(() => _selectedType = t.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected ? TrailColors.orange : TrailColors.peach.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? TrailColors.orange : TrailColors.peach),
              ),
              child: Center(
                child: Text(t.$2, style: TextStyle(color: selected ? Colors.white : TrailColors.onSurfaceMuted, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDifficultyFilter() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 6,
        itemBuilder: (_, i) {
          final selected = i == _selectedDifficulty;
          final label = i == 0 ? 'Any' : '★' * i;
          return GestureDetector(
            onTap: () => setState(() => _selectedDifficulty = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: selected ? TrailColors.peach : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? TrailColors.orange : TrailColors.peach),
              ),
              child: Center(
                child: Text(label, style: TextStyle(color: selected ? TrailColors.brown : TrailColors.onSurfaceMuted, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({required this.quest, required this.index, this.userPosition});
  final Map<String, dynamic> quest;
  final int index;
  final Position? userPosition;

  static const _typeColors = {
    'landmark':  Color(0xFF6366F1),
    'food':      Color(0xFFEC4899),
    'cultural':  Color(0xFFF59E0B),
    'adventure': Color(0xFFEF4444),
    'heritage':  Color(0xFF8B5CF6),
    'nature':    Color(0xFF10B981),
    'shopping':  Color(0xFFEC4899),
  };

  static const _typeLabels = {
    'landmark':  'Landmark',
    'food':      'Food',
    'cultural':  'Cultural',
    'adventure': 'Adventure',
    'heritage':  'Heritage',
    'nature':    'Nature',
    'shopping':  'Shopping',
  };

  String? _distanceLabel() {
    if (userPosition == null) return null;
    // Try common field names the API might provide for quest start coordinates
    final lat = (quest['latitude'] ?? quest['lat'] ?? quest['startLat']) as num?;
    final lng = (quest['longitude'] ?? quest['lng'] ?? quest['startLng']) as num?;
    if (lat == null || lng == null) return null;
    final meters = Geolocator.distanceBetween(
      userPosition!.latitude, userPosition!.longitude,
      lat.toDouble(), lng.toDouble(),
    );
    return meters < 1000
        ? '${meters.round()}m'
        : '${(meters / 1000).toStringAsFixed(1)}km';
  }

  @override
  Widget build(BuildContext context) {
    final type       = (quest['questType'] as String?) ?? 'landmark';
    final difficulty = (quest['difficulty'] as int?) ?? 1;
    final xp         = (quest['xpReward'] as int?) ?? 0;
    final duration   = (quest['estDurationMin'] as int?) ?? 0;
    final coverUrl   = quest['coverImageUrl'] as String?;
    final isPremium  = (quest['isPremium'] as bool?) ?? false;
    final color      = _typeColors[type] ?? TrailColors.primary;
    final distance   = _distanceLabel();

    return GestureDetector(
      // push so the AppBar back button works on QuestDetailScreen
      onTap: () => context.push('/quests/${quest['id']}'),
      child: Container(
        decoration: BoxDecoration(
          color: TrailColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: const Border.fromBorderSide(BorderSide(color: TrailColors.peach)),
          boxShadow: const [
            BoxShadow(color: TrailColors.shadowSm, blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 110,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  coverUrl != null
                      ? CachedNetworkImage(imageUrl: AppConfig.imageUrl(coverUrl), fit: BoxFit.cover, errorWidget: (_, __, ___) => _placeholder())
                      : _placeholder(),
                  if (isPremium)
                    Positioned(
                      top: 6, right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF7C3AED), borderRadius: BorderRadius.circular(8)),
                        child: const Text('⭐ Premium', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                    child: Text(_typeLabels[type] ?? type, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 6),
                  Text(quest['title'] ?? '', style: const TextStyle(color: TrailColors.onBackground, fontWeight: FontWeight.w700, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: List.generate(5, (i) => Icon(Icons.star_rounded, size: 10, color: i < difficulty ? TrailColors.accent : TrailColors.peach))),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('+$xp XP', style: const TextStyle(color: TrailColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      if (distance != null)
                        Text(distance, style: const TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 11))
                      else if (duration > 0)
                        Text('~${duration}min', style: const TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 11)),
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

  Widget _placeholder() => Container(
    color: TrailColors.surfaceAlt,
    child: const Center(child: Icon(Icons.landscape_rounded, size: 36, color: TrailColors.onSurfaceMuted)),
  );
}
