import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/colors.dart';

class QuestDetailScreen extends StatefulWidget {
  const QuestDetailScreen({super.key, required this.id});
  final String id;

  @override
  State<QuestDetailScreen> createState() => _QuestDetailScreenState();
}

class _QuestDetailScreenState extends State<QuestDetailScreen> {
  final _dio = buildDio();
  Map<String, dynamic>? _quest;
  bool _loading = true, _starting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _dio.get('/quests/${widget.id}');
      setState(() => _quest = res.data as Map<String, dynamic>);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      await _dio.post('/quests/${widget.id}/start');
      if (mounted) context.go('/quests/${widget.id}/active');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to start quest')));
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: TrailColors.background, body: Center(child: CircularProgressIndicator()));
    }
    if (_quest == null) {
      return Scaffold(backgroundColor: TrailColors.background, body: Center(child: Text('Quest not found', style: TextStyle(color: TrailColors.onBackground))));
    }

    final quest = _quest!;
    final checkpoints = (quest['checkpoints'] as List?) ?? [];
    final xp = (quest['xpReward'] as int?) ?? 0;
    final difficulty = (quest['difficulty'] as int?) ?? 1;

    return Scaffold(
      backgroundColor: TrailColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: TrailColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: TrailColors.surfaceAlt, child: const Icon(Icons.landscape_rounded, size: 80, color: Colors.white24)),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, TrailColors.background]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    ...List.generate(5, (i) => Icon(Icons.star_rounded, size: 16, color: i < difficulty ? TrailColors.primary : TrailColors.onSurfaceMuted.withOpacity(0.3))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: TrailColors.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                      child: Text('+$xp XP', style: TextStyle(color: TrailColors.accent, fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(quest['title'] ?? '', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 26)),
                const SizedBox(height: 8),
                Text(quest['summary'] ?? '', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: TrailColors.onSurfaceMuted, height: 1.5)),
                const SizedBox(height: 24),
                Text('${checkpoints.length} Checkpoints', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
                const SizedBox(height: 12),
                ...checkpoints.asMap().entries.map((e) => _CheckpointRow(index: e.key, cp: e.value as Map<String, dynamic>)),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _starting ? null : _start,
                  child: _starting ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Start Quest'),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckpointRow extends StatelessWidget {
  const _CheckpointRow({required this.index, required this.cp});
  final int index;
  final Map<String, dynamic> cp;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: TrailColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: TrailColors.primary.withOpacity(0.15), shape: BoxShape.circle),
            child: Center(child: Text('${index + 1}', style: TextStyle(color: TrailColors.primary, fontWeight: FontWeight.w700, fontSize: 13))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cp['title'] ?? '', style: const TextStyle(color: TrailColors.onBackground, fontWeight: FontWeight.w600)),
                if (cp['description'] != null)
                  Text(cp['description'], style: TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text('+${cp['xpReward'] ?? 0} XP', style: TextStyle(color: TrailColors.accent, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
