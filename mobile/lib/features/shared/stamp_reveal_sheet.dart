import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/colors.dart';

class StampRevealSheet extends StatelessWidget {
  const StampRevealSheet({super.key, required this.stamp, required this.xp});
  final Map<String, dynamic> stamp;
  final int xp;

  @override
  Widget build(BuildContext context) {
    final rarity      = (stamp['rarity'] as String?) ?? 'common';
    final rarityColor = _rarityColor(rarity);

    return Container(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
      decoration: const BoxDecoration(
        color: TrailColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: TrailColors.peach, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 28),

          // Stamp icon
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: rarityColor, width: 3),
              color: rarityColor.withOpacity(0.08),
              boxShadow: [BoxShadow(color: rarityColor.withOpacity(0.2), blurRadius: 24, spreadRadius: 4)],
            ),
            child: Icon(Icons.auto_awesome_rounded, size: 52, color: rarityColor),
          ).animate().scale(begin: const Offset(0.2, 0.2), duration: 500.ms, curve: Curves.elasticOut),

          const SizedBox(height: 20),

          // Rarity badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(color: rarityColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: rarityColor.withOpacity(0.3))),
            child: Text(rarity.toUpperCase(), style: TextStyle(color: rarityColor, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 12),

          Text(stamp['name'] ?? 'New Stamp', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: TrailColors.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('+$xp XP earned', style: const TextStyle(color: TrailColors.accent, fontSize: 18, fontWeight: FontWeight.w800)),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),

          const SizedBox(height: 32),

          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue Quest'),
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }

  Color _rarityColor(String r) => switch (r) {
    'legendary' => const Color(0xFFFFAF00),
    'epic'      => const Color(0xFF9333EA),
    'rare'      => const Color(0xFF3B82F6),
    'uncommon'  => const Color(0xFF22C55E),
    _           => TrailColors.onSurfaceMuted,
  };
}
