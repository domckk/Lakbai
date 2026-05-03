import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/colors.dart';

class QuestListScreen extends StatefulWidget {
  const QuestListScreen({
    super.key,
    required this.destinationSlug,
    this.destinationName,
  });

  final String? destinationSlug;
  final String? destinationName;

  @override
  State<QuestListScreen> createState() => _QuestListScreenState();
}

class _QuestListScreenState extends State<QuestListScreen> {
  final _dio = buildDio();
  List<dynamic> _quests = [];
  bool _loading = false;
  String _selectedType = 'all';
  int _selectedDifficulty = 0;

  static const _types = [
    ('all', 'All'),
    ('landmark', 'Heritage'),
    ('food', 'Food'),
    ('cultural', 'Culture'),
    ('adventure', 'Adventure'),
    ('heritage', 'Heritage'),
    ('nature', 'Nature'),
    ('shopping', 'Shopping'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.destinationSlug != null) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      var query = '/quests?destinationSlug=${widget.destinationSlug}';
      if (_selectedType != 'all') query += '&type=$_selectedType';
      if (_selectedDifficulty > 0) query += '&difficulty=$_selectedDifficulty';
      final res = await _dio.get(query);
      setState(() => _quests = res.data as List);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gate: no destination selected
    if (widget.destinationSlug == null) {
      return Scaffold(
        backgroundColor: TrailColors.background,
        appBar: AppBar(title: const Text('Quests'), backgroundColor: TrailColors.background),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🗺️', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 20),
                const Text(
                  'Choose a destination first',
                  style: TextStyle(color: TrailColors.onBackground, fontSize: 20, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Quests are tied to a destination. Pick one to see the missions available there.',
                  style: TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 14, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => context.go('/destinations'),
                  icon: const Icon(Icons.place_rounded),
                  label: const Text('Browse Destinations'),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: TrailColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            if (widget.destinationName != null)
              Text(
                widget.destinationName!,
                style: TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 12),
              ),
          ],
        ),
        backgroundColor: TrailColors.background,
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/destinations'),
            icon: Icon(Icons.swap_horiz_rounded, size: 16, color: TrailColors.primary),
            label: Text('Change', style: TextStyle(color: TrailColors.primary, fontSize: 13)),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTypeFilter(),
          _buildDifficultyFilter(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _quests.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('📍', style: TextStyle(fontSize: 48)),
                                const SizedBox(height: 12),
                                Text(
                                  'No quests found',
                                  style: TextStyle(color: TrailColors.onBackground, fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Try adjusting your filters.',
                                  style: TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 13),
                                ),
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
                            itemCount: _quests.length,
                            itemBuilder: (_, i) => _QuestCard(
                              quest: _quests[i] as Map<String, dynamic>,
                              index: i,
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilter() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _types.length,
        itemBuilder: (_, i) {
          final t = _types[i];
          final selected = t.$1 == _selectedType;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedType = t.$1);
              _load();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected ? TrailColors.primary : TrailColors.surfaceAlt,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  t.$2,
                  style: TextStyle(
                    color: selected ? Colors.white : TrailColors.onSurfaceMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
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
            onTap: () {
              setState(() => _selectedDifficulty = i);
              _load();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: selected ? TrailColors.accent.withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? TrailColors.accent : TrailColors.surfaceAlt),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? TrailColors.accent : TrailColors.onSurfaceMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({required this.quest, required this.index});
  final Map<String, dynamic> quest;
  final int index;

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

  @override
  Widget build(BuildContext context) {
    final type       = (quest['questType'] as String?) ?? 'landmark';
    final difficulty = (quest['difficulty'] as int?) ?? 1;
    final xp         = (quest['xpReward'] as int?) ?? 0;
    final duration   = (quest['estDurationMin'] as int?) ?? 0;
    final coverUrl   = quest['coverImageUrl'] as String?;
    final isPremium  = (quest['isPremium'] as bool?) ?? false;
    final color      = _typeColors[type] ?? TrailColors.primary;

    return GestureDetector(
      onTap: () => context.go('/quests/${quest['id']}'),
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
            SizedBox(
              height: 110,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: coverUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _placeholder(),
                        )
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
                    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text(_typeLabels[type] ?? type, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    quest['title'] ?? '',
                    style: const TextStyle(color: TrailColors.onBackground, fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(children: List.generate(5, (i) => Icon(Icons.star_rounded, size: 10, color: i < difficulty ? TrailColors.accent : TrailColors.surfaceAlt))),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('+$xp XP', style: TextStyle(color: TrailColors.accent, fontSize: 11, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      if (duration > 0)
                        Text('${duration}m', style: TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: (index * 40).ms, duration: 300.ms),
    );
  }

  Widget _placeholder() => Container(
    color: TrailColors.surfaceAlt,
    child: const Center(child: Icon(Icons.landscape_rounded, size: 36, color: Colors.white24)),
  );
}
