import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _dio = buildDio();
  final _storage = const FlutterSecureStorage();
  Map<String, dynamic>? _user;
  List<dynamic> _badges = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _dio.get('/me'),
        _dio.get('/me/badges'),
      ]);
      setState(() {
        _user = results[0].data as Map<String, dynamic>;
        _badges = results[1].data as List;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await _storage.deleteAll();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TrailColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: TrailColors.background,
        actions: [
          IconButton(icon: const Icon(Icons.logout_rounded), onPressed: _logout, color: TrailColors.error),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildAvatar(),
                  const SizedBox(height: 20),
                  _buildXpCard(),
                  const SizedBox(height: 20),
                  _buildStats(),
                  if (_badges.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildBadges(context),
                  ],
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TrailColors.error,
                      side: const BorderSide(color: TrailColors.error),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAvatar() {
    final user = _user!;
    final initial = (user['username'] as String? ?? 'U')[0].toUpperCase();
    final role = (user['role'] as String? ?? 'tourist');

    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: TrailColors.primary,
            child: Text(initial, style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 12),
          Text(user['displayName'] ?? user['username'] ?? '', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('@${user['username'] ?? ''}', style: TextStyle(color: TrailColors.onSurfaceMuted)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: TrailColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(role.toUpperCase(), style: TextStyle(color: TrailColors.primary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildXpCard() {
    final user = _user!;
    final level = (user['level'] as int?) ?? 1;
    final xp = (user['xpTotal'] as int?) ?? 0;
    final nextXp = (user['xpForNextLevel'] as int?) ?? 100;
    final progress = nextXp > 0 ? ((xp % nextXp) / nextXp).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TrailColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TrailColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: TrailColors.accent, size: 20),
              const SizedBox(width: 6),
              Text('Level $level', style: TextStyle(color: TrailColors.onBackground, fontWeight: FontWeight.w700, fontSize: 16)),
              const Spacer(),
              Text('$xp XP', style: TextStyle(color: TrailColors.accent, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: TrailColors.surfaceAlt,
              color: TrailColors.primary,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text('$nextXp XP to next level', style: TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 12)),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }

  Widget _buildStats() {
    final user = _user!;
    return Column(
      children: [
        _StatRow(icon: Icons.emoji_events_rounded, label: 'Level', value: '${user['level'] ?? 1}', color: TrailColors.accent),
        _StatRow(icon: Icons.bolt_rounded, label: 'Total XP', value: '${user['xpTotal'] ?? 0}', color: TrailColors.primary),
        _StatRow(icon: Icons.email_outlined, label: 'Email', value: '${user['email'] ?? ''}', color: TrailColors.secondary),
      ],
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms);
  }

  Widget _buildBadges(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Badges', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.9,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _badges.length,
          itemBuilder: (_, i) {
            final badge = _badges[i] as Map<String, dynamic>;
            final rarity = (badge['rarity'] as String?) ?? 'common';
            final color = _rarityColor(rarity);
            return Column(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Icon(Icons.military_tech_rounded, color: color, size: 26),
                ),
                const SizedBox(height: 4),
                Text(badge['name'] ?? '', style: TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 10), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ).animate().fadeIn(delay: (i * 40).ms, duration: 300.ms);
          },
        ),
      ],
    );
  }

  Color _rarityColor(String rarity) {
    switch (rarity) {
      case 'uncommon': return const Color(0xFF22C55E);
      case 'rare': return const Color(0xFF3B82F6);
      case 'epic': return const Color(0xFFA855F7);
      case 'legendary': return const Color(0xFFF59E0B);
      default: return const Color(0xFF9CA3AF);
    }
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.icon, required this.label, required this.value, required this.color});
  final IconData icon;
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: TrailColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: TrailColors.onSurfaceMuted)),
          const Spacer(),
          Text(value, style: const TextStyle(color: TrailColors.onBackground, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
