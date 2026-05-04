import 'package:flutter/material.dart';
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
      if (mounted) setState(() { _passports = res.data as List; _loading = false; });
    } catch (_) {
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
              color: TrailColors.primary,
              onRefresh: _load,
              child: _passports.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72, height: 72,
                            decoration: BoxDecoration(color: TrailColors.surfaceAlt, borderRadius: BorderRadius.circular(20)),
                            child: const Icon(Icons.auto_stories_outlined, size: 36, color: TrailColors.onSurfaceMuted),
                          ),
                          const SizedBox(height: 16),
                          const Text('No passports yet', style: TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 15)),
                          const SizedBox(height: 8),
                          const Text('Set a destination to unlock its passport.', style: TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 13)),
                        ],
                      ),
                    )
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
                        onTap: () => _openStampSheet(_passports[i] as Map<String, dynamic>),
                      ),
                    ),
            ),
    );
  }

  void _openStampSheet(Map<String, dynamic> passport) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StampsSheet(passportId: passport['id'] as String, title: passport['title'] as String? ?? ''),
    );
  }
}

// ── Passport Card ─────────────────────────────────────────────────────────

class _PassportCard extends StatelessWidget {
  const _PassportCard({required this.passport, required this.onTap});
  final Map<String, dynamic> passport;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final earned   = (passport['earnedStamps'] as int?) ?? 0;
    final total    = (passport['totalStamps']  as int?) ?? 1;
    final pct      = total > 0 ? earned / total : 0.0;
    final complete = pct >= 1.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TrailColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: complete ? TrailColors.primaryMedium : TrailColors.peach),
          boxShadow: const [
            BoxShadow(color: TrailColors.shadowSm, blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: complete ? TrailColors.primaryLight : const Color(0x1E0E5E6F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.auto_stories_rounded,
                      color: complete ? TrailColors.primary : TrailColors.secondary, size: 20),
                ),
                const Spacer(),
                if (complete)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: const BoxDecoration(
                        color: TrailColors.primaryFaint,
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                    child: const Text('Done ✓',
                        style: TextStyle(color: TrailColors.primary, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            const Spacer(),
            Text(passport['title'] ?? '',
                style: const TextStyle(
                    color: TrailColors.onBackground, fontWeight: FontWeight.w700, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('$earned/$total stamps',
                    style: const TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 11)),
                const Spacer(),
                Text('${(pct * 100).round()}%',
                    style: TextStyle(
                        color: complete ? TrailColors.primary : TrailColors.secondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                backgroundColor: TrailColors.peach,
                color: complete ? TrailColors.primary : TrailColors.secondary,
                minHeight: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stamps Sheet — fetches full detail on open ────────────────────────────

class _StampsSheet extends StatefulWidget {
  const _StampsSheet({required this.passportId, required this.title});
  final String passportId;
  final String title;

  @override
  State<_StampsSheet> createState() => _StampsSheetState();
}

class _StampsSheetState extends State<_StampsSheet> {
  final _dio = buildDio();
  Map<String, dynamic>? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _dio.get('/me/passports/${widget.passportId}');
      if (mounted) setState(() { _detail = res.data as Map<String, dynamic>; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  static const _rarityColors = {
    'common':    Color(0xFF9CA3AF),
    'uncommon':  Color(0xFF22C55E),
    'rare':      Color(0xFF3B82F6),
    'epic':      Color(0xFFA855F7),
    'legendary': Color(0xFFF59E0B),
  };

  static const _rarityLabels = {
    'common':    'Common',
    'uncommon':  'Uncommon',
    'rare':      'Rare',
    'epic':      'Epic',
    'legendary': 'Legendary',
  };

  @override
  Widget build(BuildContext context) {
    final stamps = (_detail?['stamps'] as List?) ?? [];
    final earned = stamps.where((s) => (s as Map)['earnedAt'] != null).length;
    final total  = stamps.length;

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
            // ── Handle ───────────────────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40, height: 4,
                decoration: BoxDecoration(color: TrailColors.peach, borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.title,
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: TrailColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('$earned/$total',
                        style: const TextStyle(
                            color: TrailColors.onSurfaceMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                ],
              ),
            ),

            // ── Progress bar ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total > 0 ? earned / total : 0,
                  backgroundColor: TrailColors.peach,
                  color: TrailColors.primary,
                  minHeight: 6,
                ),
              ),
            ),

            // ── Stamp grid ───────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : stamps.isEmpty
                      ? Center(
                          child: Text('No stamps defined yet',
                              style: TextStyle(color: TrailColors.onSurfaceMuted)))
                      : GridView.builder(
                          controller: ctrl,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.82,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: stamps.length,
                          itemBuilder: (_, i) {
                            final stamp    = stamps[i] as Map<String, dynamic>;
                            final isEarned = stamp['earnedAt'] != null;
                            final rarity   = (stamp['rarity'] as String?) ?? 'common';
                            final color    = _rarityColors[rarity] ?? const Color(0xFF9CA3AF);
                            // Backend returns 'name' field (not 'title')
                            final name     = (stamp['name'] as String?) ?? '';

                            return Container(
                              decoration: BoxDecoration(
                                color: isEarned ? TrailColors.surface : TrailColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: isEarned
                                        ? color.withValues(alpha: 0.45)
                                        : TrailColors.peach),
                                boxShadow: isEarned
                                    ? [BoxShadow(
                                        color: color.withValues(alpha: 0.12),
                                        blurRadius: 8, offset: const Offset(0, 3))]
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  isEarned
                                      ? Icon(Icons.stars_rounded, color: color, size: 34)
                                      : const Icon(Icons.lock_outline_rounded,
                                          color: TrailColors.peach, size: 28),
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                          color: isEarned
                                              ? TrailColors.onBackground
                                              : TrailColors.onSurfaceMuted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _rarityLabels[rarity] ?? rarity,
                                    style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700),
                                  ),
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
