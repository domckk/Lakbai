import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/colors.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> with SingleTickerProviderStateMixin {
  final _dio = buildDio();
  late final TabController _tabs = TabController(length: 2, vsync: this);
  List<dynamic> _available = [];
  List<dynamic> _wallet = [];
  bool _loadingAvail = true, _loadingWallet = true;

  @override
  void initState() {
    super.initState();
    _loadAvailable();
    _loadWallet();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadAvailable() async {
    try {
      final res = await _dio.get('/rewards');
      setState(() => _available = res.data as List);
    } finally {
      if (mounted) setState(() => _loadingAvail = false);
    }
  }

  Future<void> _loadWallet() async {
    try {
      final res = await _dio.get('/me/rewards');
      setState(() => _wallet = res.data as List);
    } finally {
      if (mounted) setState(() => _loadingWallet = false);
    }
  }

  Future<void> _redeem(String rewardId) async {
    try {
      await _dio.post('/rewards/$rewardId/redeem');
      _showToast('Reward redeemed!');
      _loadAvailable();
      _loadWallet();
    } catch (e) {
      _showToast('Could not redeem reward');
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TrailColors.background,
      appBar: AppBar(
        title: const Text('Rewards'),
        backgroundColor: TrailColors.background,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: TrailColors.primary,
          labelColor: TrailColors.primary,
          unselectedLabelColor: TrailColors.onSurfaceMuted,
          tabs: const [Tab(text: 'Available'), Tab(text: 'Wallet')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildAvailable(),
          _buildWallet(),
        ],
      ),
    );
  }

  Widget _buildAvailable() {
    if (_loadingAvail) return const Center(child: CircularProgressIndicator());
    if (_available.isEmpty) return Center(child: Text('No rewards available', style: TextStyle(color: TrailColors.onSurfaceMuted)));

    return RefreshIndicator(
      onRefresh: _loadAvailable,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _available.length,
        itemBuilder: (_, i) {
          final r = _available[i] as Map<String, dynamic>;
          final unlocked = r['isUnlocked'] as bool? ?? false;
          final discount = r['discountPct'] as int?;
          final reqXp = (r['requiredXp'] as int?) ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TrailColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: unlocked ? TrailColors.primary.withOpacity(0.3) : Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: (unlocked ? TrailColors.primary : TrailColors.onSurfaceMuted).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.card_giftcard_rounded, color: unlocked ? TrailColors.primary : TrailColors.onSurfaceMuted, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r['title'] ?? '', style: const TextStyle(color: TrailColors.onBackground, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      if (discount != null)
                        Text('$discount% off', style: TextStyle(color: TrailColors.accent, fontSize: 12, fontWeight: FontWeight.w700)),
                      Text(unlocked ? 'Unlocked' : '$reqXp XP required', style: TextStyle(color: unlocked ? TrailColors.success : TrailColors.onSurfaceMuted, fontSize: 12)),
                    ],
                  ),
                ),
                if (unlocked)
                  FilledButton(
                    onPressed: () => _redeem(r['id'] as String),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(70, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    child: const Text('Redeem'),
                  ),
              ],
            ),
          ).animate().fadeIn(delay: (i * 50).ms, duration: 300.ms);
        },
      ),
    );
  }

  Widget _buildWallet() {
    if (_loadingWallet) return const Center(child: CircularProgressIndicator());
    if (_wallet.isEmpty) return Center(child: Text('No vouchers yet', style: TextStyle(color: TrailColors.onSurfaceMuted)));

    return RefreshIndicator(
      onRefresh: _loadWallet,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _wallet.length,
        itemBuilder: (_, i) {
          final r = _wallet[i] as Map<String, dynamic>;
          final code = r['code'] as String? ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TrailColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TrailColors.accent.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['title'] ?? '', style: const TextStyle(color: TrailColors.onBackground, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: TrailColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: TrailColors.accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(code, style: TextStyle(color: TrailColors.accent, fontWeight: FontWeight.w700, letterSpacing: 2, fontSize: 15), overflow: TextOverflow.ellipsis)),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        color: TrailColors.onSurfaceMuted,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!')));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (i * 50).ms, duration: 300.ms);
        },
      ),
    );
  }
}
