import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/colors.dart';

class StampRevealSheet extends StatelessWidget {
  const StampRevealSheet({super.key, required this.stamp, required this.xp});
  final Map<String, dynamic> stamp;
  final int xp;

  @override
  Widget build(BuildContext context) {
    final rarity = (stamp['rarity'] as String?) ?? 'common';
    final rarityColor = _rarityColor(rarity);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: TrailColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: TrailColors.onSurfaceMuted.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: rarityColor, width: 3),
              color: rarityColor.withOpacity(0.12),
            ),
            child: const Icon(Icons.auto_awesome_rounded, size: 56, color: TrailColors.accent),
          ).animate().scale(begin: const Offset(0.2, 0.2), duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: rarityColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Text(rarity.toUpperCase(), style: TextStyle(color: rarityColor, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(stamp['name'] ?? 'New Stamp', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 8),
          Text('+$xp XP earned', style: TextStyle(color: TrailColors.accent, fontSize: 20, fontWeight: FontWeight.w700))
              .animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue Quest'),
          ).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Color _rarityColor(String r) => switch (r) {
    'legendary' => const Color(0xFFFFAF00),
    'epic' => const Color(0xFF9333EA),
    'rare' => const Color(0xFF3B82F6),
    _ => TrailColors.onSurfaceMuted,
  };
}
