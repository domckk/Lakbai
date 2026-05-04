import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
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
  List<dynamic> _wallet    = [];
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reward redeemed!')));
      _loadAvailable();
      _loadWallet();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not redeem reward')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TrailColors.background,
      appBar: AppBar(
        title: const Text('Rewards'),
        backgroundColor: TrailColors.background,
        leading: context.canPop() ? const BackButton() : null,
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Available'), Tab(text: 'My Wallet')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_buildAvailable(), _buildWallet()],
      ),
    );
  }

  Widget _buildAvailable() {
    if (_loadingAvail) return const Center(child: CircularProgressIndicator());
    if (_available.isEmpty) {
      return Center(child: Text('No rewards available', style: TextStyle(color: TrailColors.onSurfaceMuted)));
    }
    return RefreshIndicator(
      color: TrailColors.primary,
      onRefresh: _loadAvailable,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _available.length,
        itemBuilder: (_, i) {
          final r        = _available[i] as Map<String, dynamic>;
          final unlocked = r['isUnlocked'] as bool? ?? false;
          final discount = r['discountPct'] as int?;
          final reqXp    = (r['requiredXp'] as int?) ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TrailColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: unlocked ? TrailColors.primary.withOpacity(0.3) : TrailColors.peach),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: (unlocked ? TrailColors.primary : TrailColors.onSurfaceMuted).withOpacity(0.1),
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
                      const SizedBox(height: 3),
                      if (discount != null)
                        Text('$discount% off', style: const TextStyle(color: TrailColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                      Text(
                        unlocked ? '✓ Unlocked' : '$reqXp XP required',
                        style: TextStyle(color: unlocked ? TrailColors.success : TrailColors.onSurfaceMuted, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                if (unlocked)
                  FilledButton(
                    onPressed: () => _redeem(r['id'] as String),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(72, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
    if (_wallet.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: TrailColors.surfaceAlt, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.wallet_rounded, size: 36, color: TrailColors.onSurfaceMuted),
            ),
            const SizedBox(height: 16),
            const Text('No vouchers yet', style: TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 15)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: TrailColors.primary,
      onRefresh: _loadWallet,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _wallet.length,
        itemBuilder: (_, i) {
          final r    = _wallet[i] as Map<String, dynamic>;
          final code = r['code'] as String? ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TrailColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TrailColors.primary.withOpacity(0.2)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['title'] ?? '', style: const TextStyle(color: TrailColors.onBackground, fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: TrailColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: TrailColors.primary.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(code, style: const TextStyle(color: TrailColors.primary, fontWeight: FontWeight.w800, letterSpacing: 2.5, fontSize: 15), overflow: TextOverflow.ellipsis),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied!')));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: TrailColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.copy_rounded, size: 16, color: TrailColors.primary),
                        ),
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
