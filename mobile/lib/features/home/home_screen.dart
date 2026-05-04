import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/providers/destination_provider.dart';
import '../../core/theme/colors.dart';
import '../notifications/notification_service.dart';
import '../notifications/notifications_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _dio = buildDio();
  Map<String, dynamic>? _user;
  List<dynamic> _quests   = [];
  List<dynamic> _leaders  = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    NotificationService.instance.start();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);

    // Fire all three in parallel — each updates state as it arrives.
    await Future.wait([
      _dio.get('/me').then((res) {
        if (!mounted) return;
        final user = res.data as Map<String, dynamic>;
        setState(() => _user = user);
        final destData = user['activeDestination'] as Map<String, dynamic>?;
        if (destData != null) {
          ref.read(activeDestinationProvider.notifier).choose(ActiveDestination(
            id:   destData['id']   as String,
            slug: destData['slug'] as String,
            name: destData['name'] as String,
          ));
        }
      }).catchError((_) {}),

      _dio.get('/leaderboards/global?limit=5').then((res) {
        if (mounted) setState(() => _leaders = res.data as List);
      }).catchError((_) {}),

      _dio.get('/quests').then((res) {
        if (mounted) setState(() => _quests = res.data as List);
      }).catchError((_) {}),
    ]);

    if (mounted) setState(() => _loading = false);
  }

  int get _totalXp => _leaders.fold(0, (s, e) {
    final entry = e as Map<String, dynamic>;
    return s + ((entry['score'] as num?) ?? (entry['xpTotal'] as num?) ?? 0).toInt();
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TrailColors.background,
      body: RefreshIndicator(
        color: TrailColors.orange,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_user != null) ...[
                    _buildXpCard(),
                    const SizedBox(height: 16),
                  ],
                  _buildStatCards(),
                  const SizedBox(height: 20),
                  _buildQuickAccess(context),
                  const SizedBox(height: 20),
                  _buildTopExplorers(context),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: TrailColors.surface,
      foregroundColor: TrailColors.onBackground,
      floating: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: TrailColors.peach),
      ),
      title: Text(
        'Hey, ${_user?['username'] ?? 'Explorer'}',
        style: const TextStyle(fontWeight: FontWeight.w800, color: TrailColors.brown, fontSize: 18),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _NotificationBell(),
        ),
      ],
    );
  }

  // ── XP Card ──────────────────────────────────────────────────────────

  Widget _buildXpCard() {
    final user    = _user!;
    final level   = (user['level'] as int?) ?? 1;
    final xp      = (user['xpTotal'] as int?) ?? 0;
    final nextXp  = (user['xpForNextLevel'] as int?) ?? 100;
    final xpPct   = nextXp > 0 ? (xp / nextXp).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: TrailColors.brown,
        borderRadius: BorderRadius.all(Radius.circular(20)),
        boxShadow: [BoxShadow(color: TrailColors.brownShadow, blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -20, right: -20,
            child: SizedBox(
              width: 100, height: 100,
              child: DecoratedBox(
                decoration: BoxDecoration(color: TrailColors.orangeFaint, shape: BoxShape.circle),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Progress', style: TextStyle(color: TrailColors.peach, fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text('Level $level', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Total XP', style: TextStyle(color: TrailColors.peach, fontSize: 12)),
                      const SizedBox(height: 2),
                      _AnimatedNumber(
                        value: xp,
                        style: const TextStyle(color: TrailColors.orange, fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('$xp XP', style: TextStyle(color: TrailColors.peach, fontSize: 11)),
                  const Spacer(),
                  Text('$nextXp XP to Lv ${level + 1}', style: TextStyle(color: TrailColors.peach, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: xpPct,
                  backgroundColor: TrailColors.brownMid,
                  valueColor: const AlwaysStoppedAnimation(TrailColors.orange),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 6),
              Text('${(xpPct * 100).round()}% to next level', style: const TextStyle(color: Color(0x99FFD4A8), fontSize: 11)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06);
  }

  // ── 4 Stat Cards ─────────────────────────────────────────────────────

  Widget _buildStatCards() {
    final activeDest = ref.watch(activeDestinationProvider);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        // ── My Destination ── shows name instead of count (no extra API call)
        _buildDestinationCard(activeDest),
        // ── Active Quests ──
        _buildNumberCard(
          title: 'Active Quests',
          value: _quests.length,
          emoji: '📍',
          subtitle: 'Missions',
          onTap: () {
            final dest = ref.read(activeDestinationProvider);
            if (dest != null) {
              context.go('/quests?destination=${dest.slug}&destinationName=${Uri.encodeComponent(dest.name)}');
            } else {
              context.go('/quests');
            }
          },
        ),
        // ── Top Explorers ──
        _buildNumberCard(
          title: 'Top Explorers',
          value: _leaders.length,
          emoji: '👥',
          subtitle: 'On leaderboard',
          onTap: () => context.push('/leaderboard'),
        ),
        // ── Total XP ──
        _buildNumberCard(
          title: 'Total XP',
          value: _totalXp,
          emoji: '⭐',
          subtitle: 'Across platform',
          onTap: () => context.push('/leaderboard'),
        ),
      ],
    );
  }

  Widget _buildDestinationCard(ActiveDestination? dest) {
    return GestureDetector(
      onTap: () => context.push('/destinations'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TrailColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dest != null ? TrailColors.orange.withOpacity(0.4) : TrailColors.peach,
          ),
          boxShadow: [BoxShadow(color: TrailColors.peach50, blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Text('MY DESTINATION', style: TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                ),
                const Text('🗺️', style: TextStyle(fontSize: 20)),
              ],
            ),
            const SizedBox(height: 4),
            dest != null
                ? Text(
                    dest.name,
                    style: const TextStyle(color: TrailColors.brown, fontSize: 15, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : const Text(
                    'Not set',
                    style: TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 14, fontStyle: FontStyle.italic),
                  ),
            const SizedBox(height: 2),
            Text(
              dest != null ? 'Active destination' : 'Tap to choose',
              style: const TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberCard({
    required String title,
    required int value,
    required String emoji,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TrailColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TrailColors.peach),
          boxShadow: [BoxShadow(color: TrailColors.peach50, blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(title.toUpperCase(), style: const TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                ),
                Text(emoji, style: const TextStyle(fontSize: 20)),
              ],
            ),
            const SizedBox(height: 4),
            _loading
                ? Container(width: 40, height: 24, decoration: BoxDecoration(color: TrailColors.surfaceAlt, borderRadius: BorderRadius.circular(6)))
                : _AnimatedNumber(value: value, style: const TextStyle(color: TrailColors.brown, fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ── Top Explorers ──────────────────────────────────────────────────────

  Widget _buildTopExplorers(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: TrailColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(20)),
        border: Border.fromBorderSide(BorderSide(color: TrailColors.peach)),
        boxShadow: [BoxShadow(color: TrailColors.peach50, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('🏆 Top Explorers', style: TextStyle(color: TrailColors.brown, fontWeight: FontWeight.w800, fontSize: 16)),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/leaderboard'),
                child: const Text('View all →', style: TextStyle(color: TrailColors.orange, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            ...List.generate(3, (i) => Container(
              height: 48, margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: TrailColors.surfaceAlt, borderRadius: BorderRadius.circular(12)),
            ))
          else if (_leaders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  const Text('🏅', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 10),
                  const Text('No activity yet', style: TextStyle(color: TrailColors.brown, fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('Appears after users complete quests.', style: TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 12)),
                ],
              ),
            )
          else
            ..._leaders.asMap().entries.map((e) {
              final i     = e.key;
              final entry = e.value as Map<String, dynamic>;
              final user  = (entry['user'] as Map<String, dynamic>?) ?? entry;
              final score = (entry['score'] as num?) ?? (entry['xpTotal'] as num?) ?? 0;
              final medals = ['🥇', '🥈', '🥉'];
              final isLast = i == _leaders.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(color: TrailColors.peach, shape: BoxShape.circle),
                          child: Center(
                            child: i < 3
                                ? Text(medals[i], style: const TextStyle(fontSize: 16))
                                : Text('#${i + 1}', style: const TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user['displayName'] ?? user['username'] ?? '', style: const TextStyle(color: TrailColors.brown, fontWeight: FontWeight.w700, fontSize: 14)),
                              Text('Level ${user['level'] ?? 1}', style: const TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text('${score.toInt().toLocaleString()} XP', style: const TextStyle(color: TrailColors.orange, fontWeight: FontWeight.w800, fontSize: 14)),
                      ],
                    ),
                  ),
                  if (!isLast) const Divider(height: 1, color: TrailColors.peach50),
                ],
              );
            }),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  // ── Quick Access ────────────────────────────────────────────────────────
  // Non-tab routes use context.push() so the AppBar back button appears.
  // Tab routes (quests, passport) use context.go() to switch tabs.

  Widget _buildQuickAccess(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: TrailColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(20)),
        border: Border.fromBorderSide(BorderSide(color: TrailColors.peach)),
        boxShadow: [BoxShadow(color: TrailColors.peach50, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚡ Quick Access', style: TextStyle(color: TrailColors.brown, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.1,
            children: [
              _quickItem(context, 'Destinations', '🗺️', push: '/destinations'),
              _quickItem(context, 'Quests',       '📍', questsTab: true),
              _quickItem(context, 'Map',          '🗺️', push: '/map'),
              _quickItem(context, 'Leaderboard',  '🏆', push: '/leaderboard'),
              _quickItem(context, 'Passport',     '📖', go: '/passport'),
              _quickItem(context, 'Rewards',      '🎁', push: '/rewards'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 260.ms, duration: 400.ms);
  }

  Widget _quickItem(BuildContext context, String label, String emoji, {
    String? push,
    String? go,
    bool questsTab = false,
  }) {
    return GestureDetector(
      onTap: () {
        if (questsTab) {
          final dest = ref.read(activeDestinationProvider);
          if (dest != null) {
            context.go('/quests?destination=${dest.slug}&destinationName=${Uri.encodeComponent(dest.name)}');
          } else {
            context.go('/quests');
          }
        } else if (push != null) {
          context.push(push);
        } else if (go != null) {
          context.go(go);
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          color: TrailColors.background,
          borderRadius: BorderRadius.all(Radius.circular(14)),
          border: Border.fromBorderSide(BorderSide(color: TrailColors.peach)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: TrailColors.brown, fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Notification Bell ────────────────────────────────────────────────────

class _NotificationBell extends StatefulWidget {
  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell> {
  final _service = NotificationService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _openSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = _service.unreadCount;
    return GestureDetector(
      onTap: _openSheet,
      child: SizedBox(
        width: 38, height: 38,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: TrailColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TrailColors.peach),
              ),
              child: const Icon(Icons.notifications_rounded, color: TrailColors.brown, size: 20),
            ),
            if (count > 0)
              Positioned(
                top: -4, right: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: TrailColors.orange,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Animated number counter ───────────────────────────────────────────────

class _AnimatedNumber extends StatelessWidget {
  const _AnimatedNumber({required this.value, required this.style});
  final int value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(v.toLocaleString(), style: style),
    );
  }
}

extension on int {
  String toLocaleString() {
    final s = toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}
