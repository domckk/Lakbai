import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/colors.dart';

class PassportScreen extends StatefulWidget {
  const PassportScreen({super.key});

  @override
  State<PassportScreen> createState() => _PassportScreenState();
}

class _PassportScreenState extends State<PassportScreen> {
  final _dio = buildDio();
  List<dynamic> _passports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _dio.get('/me/passports');
      setState(() => _passports = res.data as List);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TrailColors.background,
      appBar: AppBar(title: const Text('Passport'), backgroundColor: TrailColors.background),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _passports.isEmpty
                  ? Center(child: Text('No passports yet', style: TextStyle(color: TrailColors.onSurfaceMuted)))
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _passports.length,
                      itemBuilder: (_, i) => _PassportCard(
                        passport: _passports[i] as Map<String, dynamic>,
                        index: i,
                        onTap: () => _showStamps(_passports[i] as Map<String, dynamic>),
                      ),
                    ),
            ),
    );
  }

  void _showStamps(Map<String, dynamic> passport) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StampsSheet(passport: passport),
    );
  }
}

class _PassportCard extends StatelessWidget {
  const _PassportCard({required this.passport, required this.index, required this.onTap});
  final Map<String, dynamic> passport;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final earned = (passport['earnedStamps'] as int?) ?? 0;
    final total = (passport['totalStamps'] as int?) ?? 1;
    final pct = total > 0 ? earned / total : 0.0;
    final complete = pct >= 1.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TrailColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: complete ? TrailColors.accent.withOpacity(0.5) : Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: (complete ? TrailColors.accent : TrailColors.primary).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.auto_stories_rounded, color: complete ? TrailColors.accent : TrailColors.primary, size: 20),
                ),
                const Spacer(),
                if (complete) const Text('✅', style: TextStyle(fontSize: 16)),
              ],
            ),
            const Spacer(),
            Text(passport['title'] ?? '', style: const TextStyle(color: TrailColors.onBackground, fontWeight: FontWeight.w600, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('$earned/$total', style: TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 12)),
                const Spacer(),
                Text('${(pct * 100).round()}%', style: TextStyle(color: complete ? TrailColors.accent : TrailColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                backgroundColor: TrailColors.surfaceAlt,
                color: complete ? TrailColors.accent : TrailColors.primary,
                minHeight: 5,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: (index * 50).ms, duration: 300.ms),
    );
  }
}

class _StampsSheet extends StatelessWidget {
  const _StampsSheet({required this.passport});
  final Map<String, dynamic> passport;

  static const _rarityColors = {
    'common': Color(0xFF9CA3AF),
    'uncommon': Color(0xFF22C55E),
    'rare': Color(0xFF3B82F6),
    'epic': Color(0xFFA855F7),
    'legendary': Color(0xFFF59E0B),
  };

  @override
  Widget build(BuildContext context) {
    final stamps = (passport['stamps'] as List?) ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: TrailColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(passport['title'] ?? '', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  Text('${passport['earnedStamps'] ?? 0}/${passport['totalStamps'] ?? 0}', style: TextStyle(color: TrailColors.onSurfaceMuted)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: stamps.isEmpty
                  ? Center(child: Text('No stamps yet', style: TextStyle(color: TrailColors.onSurfaceMuted)))
                  : GridView.builder(
                      controller: ctrl,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: stamps.length,
                      itemBuilder: (_, i) {
                        final stamp = stamps[i] as Map<String, dynamic>;
                        final earned = stamp['earnedAt'] != null;
                        final rarity = (stamp['rarity'] as String?) ?? 'common';
                        final rarityColor = _rarityColors[rarity] ?? const Color(0xFF9CA3AF);

                        return Container(
                          decoration: BoxDecoration(
                            color: TrailColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: earned ? rarityColor.withOpacity(0.4) : Colors.white.withOpacity(0.05)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              earned
                                  ? Icon(Icons.stars_rounded, color: rarityColor, size: 32)
                                  : const Icon(Icons.lock_rounded, color: Colors.white24, size: 28),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(stamp['title'] ?? '', style: TextStyle(color: earned ? TrailColors.onBackground : TrailColors.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                              ),
                              const SizedBox(height: 4),
                              Text(rarity, style: TextStyle(color: rarityColor, fontSize: 9, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
