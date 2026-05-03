import 'package:flutter/material.dart';
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

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await _dio.get('/me');
      setState(() => _user = res.data as Map<String, dynamic>);
    } catch (_) {}
  }

  Future<void> _logout() async {
    await _storage.deleteAll();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return Scaffold(
      backgroundColor: TrailColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [IconButton(icon: const Icon(Icons.logout_rounded), onPressed: _logout)],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Column(children: [
                    CircleAvatar(radius: 48, backgroundColor: TrailColors.primary, child: Text(
                      (user['username'] as String? ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.w700),
                    )),
                    const SizedBox(height: 12),
                    Text(user['displayName'] ?? user['username'] ?? '', style: Theme.of(context).textTheme.titleLarge),
                    Text('@${user['username'] ?? ''}', style: TextStyle(color: TrailColors.onSurfaceMuted)),
                  ]),
                ),
                const SizedBox(height: 24),
                _Stat(label: 'Level', value: '${user['level'] ?? 1}', icon: Icons.emoji_events_rounded, color: TrailColors.accent),
                _Stat(label: 'Total XP', value: '${user['xpTotal'] ?? 0}', icon: Icons.bolt_rounded, color: TrailColors.primary),
                _Stat(label: 'Role', value: '${user['role'] ?? 'tourist'}', icon: Icons.badge_rounded, color: TrailColors.secondary),
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
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon, required this.color});
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: TrailColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: TrailColors.onSurfaceMuted)),
        const Spacer(),
        Text(value, style: const TextStyle(color: TrailColors.onBackground, fontWeight: FontWeight.w700, fontSize: 16)),
      ]),
    );
  }
}
