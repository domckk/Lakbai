import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/colors.dart';

const _avatarFileName = 'profile_avatar.jpg';

Future<File> _getAvatarStorageFile() async {
  final dir = await getApplicationDocumentsDirectory();
  return File('${dir.path}/$_avatarFileName');
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _dio     = buildDio();
  final _storage = const FlutterSecureStorage();
  Map<String, dynamic>? _user;
  List<dynamic> _badges = [];
  bool _loading = true;
  File? _localAvatar;

  @override
  void initState() {
    super.initState();
    _load();
    _loadAvatar();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([_dio.get('/me'), _dio.get('/me/badges')]);
      if (mounted) {
        setState(() {
          _user    = results[0].data as Map<String, dynamic>;
          _badges  = results[1].data as List;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadAvatar() async {
    final file = await _getAvatarStorageFile();
    if (file.existsSync() && mounted) {
      setState(() => _localAvatar = file);
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: TrailColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEDED),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: TrailColors.error, size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sign out?',
                style: TextStyle(color: TrailColors.onBackground, fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'You will need to log in again to access your account.',
                style: TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 14, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TrailColors.onSurface,
                        backgroundColor: TrailColors.background,
                        side: const BorderSide(color: TrailColors.peach),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: TrailColors.error,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true && mounted) {
      await _storage.deleteAll();
      if (mounted) context.go('/login');
    }
  }

  void _showEditSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        user: _user!,
        currentAvatar: _localAvatar,
        onSaved: (updated) {
          if (mounted) setState(() => _user = updated);
        },
      ),
    );
    // Reload avatar in case user changed it
    _loadAvatar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TrailColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: TrailColors.background,
        leading: context.canPop() ? const BackButton() : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: TrailColors.primary,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildAvatar(),
                  const SizedBox(height: 20),
                  _buildXpCard(),
                  const SizedBox(height: 16),
                  _buildStats(),
                  if (_badges.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildBadges(),
                  ],
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    onPressed: _confirmLogout,
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
    final user    = _user!;
    final initial = (user['username'] as String? ?? 'U')[0].toUpperCase();
    final role    = (user['role'] as String? ?? 'tourist');

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: TrailColors.primary,
                backgroundImage: _localAvatar != null ? FileImage(_localAvatar!) : null,
                child: _localAvatar == null
                    ? Text(initial, style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.w700))
                    : null,
              ),
              Positioned(
                bottom: 0, right: 0,
                child: GestureDetector(
                  onTap: _showEditSheet,
                  child: Container(
                    width: 30, height: 30,
                    decoration: const BoxDecoration(
                      color: TrailColors.orange,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: TrailColors.orangeShadow, blurRadius: 6, offset: Offset(0, 2))],
                    ),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(user['displayName'] ?? user['username'] ?? '', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('@${user['username'] ?? ''}', style: const TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 14)),
          if ((user['homeRegion'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.place_rounded, size: 13, color: TrailColors.onSurfaceMuted),
                const SizedBox(width: 3),
                Text(user['homeRegion'] as String, style: const TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 13)),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: const BoxDecoration(
              color: TrailColors.primaryFaint,
              borderRadius: BorderRadius.all(Radius.circular(20)),
              border: Border.fromBorderSide(BorderSide(color: TrailColors.primaryMedium)),
            ),
            child: Text(role.toUpperCase(), style: const TextStyle(color: TrailColors.primary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildXpCard() {
    final user     = _user!;
    final level    = (user['level'] as int?) ?? 1;
    final xp       = (user['xpTotal'] as int?) ?? 0;
    final nextXp   = (user['xpForNextLevel'] as int?) ?? 100;
    final progress = nextXp > 0 ? ((xp % nextXp) / nextXp).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: TrailColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(18)),
        border: Border.fromBorderSide(BorderSide(color: Color(0x33FF8C3B))),
        boxShadow: [BoxShadow(color: TrailColors.shadowXs, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: const BoxDecoration(color: TrailColors.primaryLight, borderRadius: BorderRadius.all(Radius.circular(10))),
                child: const Icon(Icons.bolt_rounded, color: TrailColors.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Level $level', style: const TextStyle(color: TrailColors.onBackground, fontWeight: FontWeight.w700, fontSize: 16)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: const BoxDecoration(color: TrailColors.primaryFaint, borderRadius: BorderRadius.all(Radius.circular(10))),
                child: Text('$xp XP', style: const TextStyle(color: TrailColors.accent, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: progress, backgroundColor: TrailColors.peach, color: TrailColors.primary, minHeight: 8),
          ),
          const SizedBox(height: 6),
          Text('$nextXp XP to next level', style: const TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 12)),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms);
  }

  Widget _buildStats() {
    final user = _user!;
    return Column(
      children: [
        _StatRow(icon: Icons.emoji_events_rounded, label: 'Level',    value: '${user['level'] ?? 1}',   color: TrailColors.accent),
        _StatRow(icon: Icons.bolt_rounded,         label: 'Total XP', value: '${user['xpTotal'] ?? 0}', color: TrailColors.primary),
        _StatRow(icon: Icons.email_outlined,       label: 'Email',    value: '${user['email'] ?? ''}',  color: TrailColors.secondary),
      ],
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms);
  }

  Widget _buildBadges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Badges', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: TrailColors.onBackground)),
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
            final badge  = _badges[i] as Map<String, dynamic>;
            final rarity = (badge['rarity'] as String?) ?? 'common';
            final color  = _rarityColor(rarity);
            return Column(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Icon(Icons.military_tech_rounded, color: color, size: 26),
                ),
                const SizedBox(height: 4),
                Text(badge['name'] ?? '', style: const TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 10), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            );
          },
        ),
      ],
    );
  }

  Color _rarityColor(String rarity) => switch (rarity) {
    'uncommon'  => const Color(0xFF22C55E),
    'rare'      => const Color(0xFF3B82F6),
    'epic'      => const Color(0xFFA855F7),
    'legendary' => const Color(0xFFF59E0B),
    _           => const Color(0xFF9CA3AF),
  };
}

// ── Edit Profile Sheet ─────────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.user, required this.onSaved, this.currentAvatar});
  final Map<String, dynamic> user;
  final File? currentAvatar;
  final void Function(Map<String, dynamic> updated) onSaved;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _dio         = buildDio();
  final _formKey     = GlobalKey<FormState>();
  final _picker      = ImagePicker();
  late final _displayNameCtrl = TextEditingController(text: widget.user['displayName'] as String? ?? '');
  late final _homeRegionCtrl  = TextEditingController(text: widget.user['homeRegion']  as String? ?? '');
  bool _saving = false;
  File? _pickedAvatar;

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _homeRegionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked != null && mounted) {
        setState(() => _pickedAvatar = File(picked.path));
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      // Save profile data via API
      final res = await _dio.patch('/me', data: {
        'displayName': _displayNameCtrl.text.trim(),
        'homeRegion':  _homeRegionCtrl.text.trim(),
      });

      // Save avatar locally if a new one was picked
      if (_pickedAvatar != null) {
        final dest = await _getAvatarStorageFile();
        await _pickedAvatar!.copy(dest.path);
      }

      widget.onSaved(res.data as Map<String, dynamic>);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final displayAvatar = _pickedAvatar ?? widget.currentAvatar;
    final initial = (widget.user['username'] as String? ?? 'U')[0].toUpperCase();

    return Container(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: TrailColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: const BoxDecoration(color: TrailColors.peach, borderRadius: BorderRadius.all(Radius.circular(2))),
                ),
              ),
              const Text('Edit Profile', style: TextStyle(color: TrailColors.onBackground, fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 20),

              // ── Avatar picker ──────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: TrailColors.primary,
                        backgroundImage: displayAvatar != null ? FileImage(displayAvatar) : null,
                        child: displayAvatar == null
                            ? Text(initial, style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.w700))
                            : null,
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 28, height: 28,
                          decoration: const BoxDecoration(
                            color: TrailColors.orange,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: TrailColors.orangeShadow, blurRadius: 4, offset: Offset(0, 2))],
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: _pickAvatar,
                  child: const Text('Change Photo', style: TextStyle(color: TrailColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),

              // ── Fields ─────────────────────────────────────────────────
              _field(
                controller: _displayNameCtrl,
                label: 'Display Name',
                hint: 'Your public name',
                icon: Icons.person_rounded,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Display name is required' : null,
              ),
              const SizedBox(height: 14),
              _field(
                controller: _homeRegionCtrl,
                label: 'Home Region',
                hint: 'e.g. Ilocos Norte',
                icon: Icons.place_rounded,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: TrailColors.onBackground, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: TrailColors.onSurfaceMuted, size: 20),
        labelStyle: const TextStyle(color: TrailColors.onSurfaceMuted),
        hintStyle: const TextStyle(color: TrailColors.onSurfaceMuted),
        filled: true,
        fillColor: TrailColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TrailColors.peach)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TrailColors.peach)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TrailColors.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TrailColors.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: TrailColors.error, width: 2)),
      ),
    );
  }
}

// ── Stat Row ──────────────────────────────────────────────────────────────

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
      decoration: BoxDecoration(
        color: TrailColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: const Border.fromBorderSide(BorderSide(color: TrailColors.peach)),
        boxShadow: const [BoxShadow(color: TrailColors.shadowXs, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(color: TrailColors.onBackground, fontWeight: FontWeight.w700, fontSize: 14), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
