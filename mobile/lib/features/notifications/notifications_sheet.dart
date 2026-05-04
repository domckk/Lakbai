import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/colors.dart';
import 'notification_service.dart';

class NotificationsSheet extends StatefulWidget {
  const NotificationsSheet({super.key});

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  final _service = NotificationService.instance;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _service.fetchAll();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
    // Mark all read after rendering so the badge clears
    _service.markAllRead();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: TrailColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: TrailColors.peach,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.notifications_rounded, color: TrailColors.orange, size: 22),
                const SizedBox(width: 10),
                const Text('Notifications',
                    style: TextStyle(color: TrailColors.brown, fontWeight: FontWeight.w800, fontSize: 18)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: TrailColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.close_rounded, color: TrailColors.onSurfaceMuted, size: 18),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: TrailColors.peach),
          // Body
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: TrailColors.orange))
                : _items.isEmpty
                    ? _buildEmpty()
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => Divider(height: 1, indent: 20, endIndent: 20, color: TrailColors.peach.withOpacity(0.5)),
                        itemBuilder: (_, i) => _NotificationTile(item: _items[i])
                            .animate()
                            .fadeIn(delay: (i * 40).ms, duration: 280.ms),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🔔', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 14),
        const Text('All caught up!',
            style: TextStyle(color: TrailColors.brown, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 6),
        Text('You have no notifications yet.',
            style: TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 13)),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});
  final Map<String, dynamic> item;

  String get _icon => (item['icon'] as String?) ?? '🔔';
  String get _title => (item['title'] as String?) ?? '';
  String get _body => (item['body'] as String?) ?? '';
  bool get _isRead => (item['isRead'] as bool?) ?? (item['is_read'] as bool?) ?? false;
  DateTime? get _createdAt {
    final raw = item['createdAt'] ?? item['created_at'];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().toUtc().difference(dt.toUtc());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _isRead ? Colors.transparent : TrailColors.surfaceAlt.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon circle
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: TrailColors.peach,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(_icon, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(_title,
                          style: TextStyle(
                            color: TrailColors.brown,
                            fontWeight: _isRead ? FontWeight.w600 : FontWeight.w800,
                            fontSize: 13,
                          )),
                    ),
                    if (!_isRead)
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: TrailColors.orange, shape: BoxShape.circle),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(_body,
                    style: const TextStyle(color: TrailColors.onSurface, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                if (_createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(_timeAgo(_createdAt!),
                      style: const TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 11)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
