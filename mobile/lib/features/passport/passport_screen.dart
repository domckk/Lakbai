import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/colors.dart';

class PassportScreen extends StatefulWidget {
  const PassportScreen({super.key});

  @override
  State<PassportScreen> createState() => _PassportScreenState();
}

class _PassportScreenState extends State<PassportScreen> {
  final _dio = buildDio();
  List<dynamic> _passports = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await _dio.get('/me/passports');
      setState(() => _passports = res.data as List);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TrailColors.background,
      appBar: AppBar(title: const Text('Passport')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _passports.isEmpty
              ? Center(child: Text('No passports yet', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: TrailColors.onSurfaceMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _passports.length,
                  itemBuilder: (_, i) => _PassportCard(passport: _passports[i] as Map<String, dynamic>),
                ),
    );
  }
}

class _PassportCard extends StatelessWidget {
  const _PassportCard({required this.passport});
  final Map<String, dynamic> passport;

  @override
  Widget build(BuildContext context) {
    final earned = (passport['earnedStamps'] as int?) ?? 0;
    final total = (passport['totalStamps'] as int?) ?? 1;
    final pct = total > 0 ? earned / total : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TrailColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TrailColors.accent.withOpacity(pct >= 1 ? 0.6 : 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(passport['title'] ?? '', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
          const SizedBox(height: 12),
          Row(children: [
            Text('$earned / $total stamps', style: TextStyle(color: TrailColors.onSurfaceMuted)),
            const Spacer(),
            Text('${(pct * 100).round()}%', style: TextStyle(color: pct >= 1 ? TrailColors.accent : TrailColors.primary, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              backgroundColor: TrailColors.surfaceAlt,
              color: pct >= 1 ? TrailColors.accent : TrailColors.primary,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
