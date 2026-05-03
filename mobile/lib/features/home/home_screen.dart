import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dio = buildDio();
  Map<String, dynamic>? _user;
  int _destCount = 0, _questCount = 0;
  List<dynamic> _leaders = [];
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
        _dio.get('/destinations'),
        _dio.get('/quests'),
        _dio.get('/leaderboards/global?limit=5'),
      ]);
      setState(() {
        _user = results[0].data as Map<String, dynamic>;
        _destCount = (results[1].data as List).length;
        _questCount = (results[2].data as List).length;
        _leaders = results[3].data as List;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TrailColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(context),
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (_user != null) _buildXpCard(context),
                        const SizedBox(height: 20),
                        _buildStatsRow(context),
                        const SizedBox(height: 24),
                        _buildQuickAccess(context),
                        const SizedBox(height: 24),
                        _buildLeaderboard(context),
                        const SizedBox(height: 32),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: TrailColors.background,
      floating: true,
      title: Row(
        children: [
          Image.asset('assets/images/logo.png', height: 28, errorBuilder: (_, __, ___) => const SizedBox()),
          const SizedBox(width: 8),
          const Text('Lakbai', style: TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: TrailColors.onBackground),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildXpCard(BuildContext context) {
    final user = _user!;
    final level = (user['level'] as int?) ?? 1;
    final xp = (user['xpTotal'] as int?) ?? 0;
    final nextXp = (user['xpForNextLevel'] as int?) ?? 100;
    final progress = nextXp > 0 ? ((xp % nextXp) / nextXp).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [TrailColors.primary, TrailColors.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white24,
                child: Text(
                  (user['username'] as String? ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                    ),
                    Text(
                      user['displayName'] ?? user['username'] ?? 'Explorer',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Lv.$level', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('$xp XP', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              color: Colors.white,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text('$nextXp XP to next level', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        _StatCard(label: 'Destinations', value: '$_destCount', icon: Icons.place_rounded, color: TrailColors.secondary),
        const SizedBox(width: 12),
        _StatCard(label: 'Quests', value: '$_questCount', icon: Icons.flag_rounded, color: TrailColors.primary),
      ],
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }

  Widget _buildQuickAccess(BuildContext context) {
    final items = [
      ('Destinations', Icons.place_rounded, TrailColors.secondary, '/destinations'),
      ('Leaderboard', Icons.emoji_events_rounded, TrailColors.accent, '/leaderboard'),
      ('Passport', Icons.auto_stories_rounded, TrailColors.primary, '/passport'),
      ('Rewards', Icons.card_giftcard_rounded, const Color(0xFFEC4899), '/rewards'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Access', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: items.map((item) => GestureDetector(
            onTap: () => context.go(item.$4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: item.$3.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(item.$2, color: item.$3, size: 24),
                ),
                const SizedBox(height: 6),
                Text(item.$1, style: TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 11), textAlign: TextAlign.center),
              ],
            ),
          )).toList(),
        ),
      ],
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms);
  }

  Widget _buildLeaderboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Top Explorers', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
            const Spacer(),
            TextButton(
              onPressed: () => context.go('/leaderboard'),
              child: Text('See all', style: TextStyle(color: TrailColors.primary, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._leaders.asMap().entries.map((e) {
          final idx = e.key;
          final entry = e.value as Map<String, dynamic>;
          final medals = ['🥇', '🥈', '🥉'];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: TrailColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Text(idx < 3 ? medals[idx] : '${idx + 1}', style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: TrailColors.primary.withOpacity(0.2),
                  child: Text(
                    (entry['username'] as String? ?? 'U')[0].toUpperCase(),
                    style: TextStyle(color: TrailColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry['displayName'] ?? entry['username'] ?? '', style: const TextStyle(color: TrailColors.onBackground, fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('Lv.${entry['level'] ?? 1}', style: TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 12)),
                    ],
                  ),
                ),
                Text('${entry['xpTotal'] ?? 0} XP', style: TextStyle(color: TrailColors.accent, fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ).animate().fadeIn(delay: (200 + idx * 50).ms, duration: 300.ms);
        }),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TrailColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(color: TrailColors.onBackground, fontWeight: FontWeight.w700, fontSize: 20)),
                Text(label, style: TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
