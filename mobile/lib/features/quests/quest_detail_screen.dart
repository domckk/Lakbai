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
  String? _userQuestStatus; // null | 'in_progress' | 'completed'

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _dio.get('/quests/${widget.id}');
      final data = res.data as Map<String, dynamic>;
      setState(() {
        _quest = data;
        _userQuestStatus = data['userQuestStatus'] as String?;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startOrContinue() async {
    setState(() => _starting = true);
    try {
      // start is idempotent — safe to call even if already in_progress
      await _dio.post('/quests/${widget.id}/start');
      if (mounted) {
        setState(() => _userQuestStatus = 'in_progress');
        context.go('/quests/${widget.id}/active');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start quest — try again')),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: TrailColors.background, body: Center(child: CircularProgressIndicator()));
    if (_quest == null) return Scaffold(backgroundColor: TrailColors.background, body: Center(child: Text('Quest not found', style: TextStyle(color: TrailColors.onBackground))));

    final quest       = _quest!;
    final checkpoints = (quest['checkpoints'] as List?) ?? [];
    final xp          = (quest['xpReward'] as int?) ?? 0;
    final difficulty  = (quest['difficulty'] as int?) ?? 1;

    return Scaffold(
      backgroundColor: TrailColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: TrailColors.background,
            foregroundColor: TrailColors.onBackground,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: TrailColors.surfaceAlt,
                    child: const Icon(Icons.landscape_rounded, size: 80, color: TrailColors.onSurfaceMuted),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, TrailColors.background],
                      ),
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
                // Difficulty + XP row
                Row(
                  children: [
                    ...List.generate(5, (i) => Icon(Icons.star_rounded, size: 16, color: i < difficulty ? TrailColors.accent : TrailColors.peach)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: TrailColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                      child: Text('+$xp XP', style: const TextStyle(color: TrailColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(quest['title'] ?? '', style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 26)),
                const SizedBox(height: 8),
                Text(quest['summary'] ?? '', style: const TextStyle(color: TrailColors.onSurface, height: 1.6, fontSize: 15)),
                const SizedBox(height: 24),

                Row(
                  children: [
                    const Text('Checkpoints', style: TextStyle(color: TrailColors.onBackground, fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: TrailColors.surfaceAlt, borderRadius: BorderRadius.circular(10)),
                      child: Text('${checkpoints.length}', style: const TextStyle(color: TrailColors.onSurfaceMuted, fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...checkpoints.asMap().entries.map((e) => _CheckpointRow(index: e.key, cp: e.value as Map<String, dynamic>, total: checkpoints.length)),
                const SizedBox(height: 32),
                if (_userQuestStatus == 'completed')
                  FilledButton(
                    onPressed: null,
                    style: FilledButton.styleFrom(backgroundColor: TrailColors.success),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Quest Completed'),
                      ],
                    ),
                  )
                else
                  FilledButton(
                    onPressed: _starting ? null : _startOrContinue,
                    child: _starting
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Text(_userQuestStatus == 'in_progress' ? 'Continue Quest →' : 'Start Quest'),
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
  const _CheckpointRow({required this.index, required this.cp, required this.total});
  final int index, total;
  final Map<String, dynamic> cp;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline column
        Column(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: TrailColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: TrailColors.primary.withOpacity(0.3)),
              ),
              child: Center(child: Text('${index + 1}', style: const TextStyle(color: TrailColors.primary, fontWeight: FontWeight.w700, fontSize: 13))),
            ),
            if (index < total - 1)
              Container(width: 2, height: 32, color: TrailColors.peach),
          ],
        ),
        const SizedBox(width: 12),
        // Content
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: index < total - 1 ? 0 : 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: TrailColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: const Border.fromBorderSide(BorderSide(color: TrailColors.peach)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cp['title'] ?? '', style: const TextStyle(color: TrailColors.onBackground, fontWeight: FontWeight.w600)),
                      if (cp['description'] != null)
                        Text(cp['description'], style: const TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 12, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: TrailColors.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text('+${cp['xpReward'] ?? 0} XP', style: const TextStyle(color: TrailColors.accent, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
