import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/colors.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _dio = buildDio();
  List<dynamic> _leaders = [];
  bool _loading = true;
  bool _isGlobal = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final scope = _isGlobal ? 'global' : 'weekly';
      final res = await _dio.get('/leaderboards/$scope?limit=50');
      if (mounted) setState(() { _leaders = res.data as List; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TrailColors.background,
      appBar: AppBar(title: const Text('Leaderboard'), backgroundColor: TrailColors.background, leading: context.canPop() ? const BackButton() : null),
      body: Column(
        children: [
          _buildToggle(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    color: TrailColors.primary,
                    onRefresh: _load,
                    child: _leaders.isEmpty
                        ? Center(child: Text('No data yet', style: TextStyle(color: TrailColors.onSurfaceMuted)))
                        : CustomScrollView(
                            slivers: [
                              if (_leaders.length >= 3)
                                SliverToBoxAdapter(child: _buildPodium()),
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                sliver: SliverList.builder(
                                  itemCount: _leaders.length > 3 ? _leaders.length - 3 : 0,
                                  itemBuilder: (_, i) => _LeaderRow(
                                    entry: _leaders[i + 3] as Map<String, dynamic>,
                                    rank: i + 4,
                                    index: i,
                                  ),
                                ),
                              ),
                              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
                            ],
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: TrailColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: const Border.fromBorderSide(BorderSide(color: TrailColors.peach)),
        ),
        child: Row(
          children: [
            _ToggleBtn(label: 'Global', selected: _isGlobal,  onTap: () { setState(() => _isGlobal = true);  _load(); }),
            _ToggleBtn(label: 'Weekly', selected: !_isGlobal, onTap: () { setState(() => _isGlobal = false); _load(); }),
          ],
        ),
      ),
    );
  }

  Widget _buildPodium() {
    if (_leaders.length < 3) return const SizedBox();
    final top3   = _leaders.take(3).toList();
    final heights = [150.0, 110.0, 90.0];
    final order   = [1, 0, 2];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: order.map((idx) {
          final entry  = top3[idx] as Map<String, dynamic>;
          final user   = (entry['user'] as Map<String, dynamic>?) ?? entry;
          final score  = (entry['score'] as num?) ?? (entry['xpTotal'] as num?) ?? 0;
          final medals = ['🥇', '🥈', '🥉'];
          final isFirst = idx == 0;

          return Expanded(
            child: Column(
              children: [
                Text(medals[idx], style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 6),
                CircleAvatar(
                  radius: isFirst ? 30 : 22,
                  backgroundColor: isFirst ? TrailColors.orangeFaint : TrailColors.surfaceAlt,
                  child: Text(
                    (user['username'] as String? ?? 'U')[0].toUpperCase(),
                    style: TextStyle(color: TrailColors.primary, fontWeight: FontWeight.w700, fontSize: isFirst ? 22 : 16),
                  ),
                ),
                const SizedBox(height: 6),
                Text(user['displayName'] ?? user['username'] ?? '', style: const TextStyle(color: TrailColors.onBackground, fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${score.toInt()} XP', style: const TextStyle(color: TrailColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Container(
                  height: heights[idx],
                  decoration: BoxDecoration(
                    color: isFirst ? TrailColors.primaryLight : TrailColors.surfaceAlt,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    border: Border.all(color: isFirst ? TrailColors.primaryMedium : TrailColors.peach),
                  ),
                  child: Center(
                    child: Text('${idx + 1}', style: TextStyle(color: isFirst ? TrailColors.primary : TrailColors.onSurfaceMuted, fontWeight: FontWeight.w800, fontSize: 20)),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: (idx * 100).ms, duration: 400.ms),
          );
        }).toList(),
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? TrailColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(label, style: TextStyle(color: selected ? Colors.white : TrailColors.onSurfaceMuted, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ),
      ),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({required this.entry, required this.rank, required this.index});
  final Map<String, dynamic> entry;
  final int rank, index;

  @override
  Widget build(BuildContext context) {
    final user  = (entry['user'] as Map<String, dynamic>?) ?? entry;
    final score = (entry['score'] as num?) ?? (entry['xpTotal'] as num?) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: TrailColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: const Border.fromBorderSide(BorderSide(color: TrailColors.peach)),
        boxShadow: const [
          BoxShadow(color: TrailColors.shadowXs, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: 28, child: Text('$rank', style: const TextStyle(color: TrailColors.onSurfaceMuted, fontWeight: FontWeight.w700))),
          CircleAvatar(
            radius: 18,
            backgroundColor: TrailColors.primaryLight,
            child: Text((user['username'] as String? ?? 'U')[0].toUpperCase(), style: const TextStyle(color: TrailColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['displayName'] ?? user['username'] ?? '', style: const TextStyle(color: TrailColors.onBackground, fontWeight: FontWeight.w600, fontSize: 14)),
                Text('Lv.${user['level'] ?? 1}', style: const TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: const BoxDecoration(color: TrailColors.primaryFaint, borderRadius: BorderRadius.all(Radius.circular(10))),
            child: Text('${score.toInt()} XP', style: const TextStyle(color: TrailColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
