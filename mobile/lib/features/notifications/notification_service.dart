import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/api/api_client.dart';

class NotificationService extends ChangeNotifier {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _dio = buildDio();
  int _unreadCount = 0;
  Timer? _timer;

  int get unreadCount => _unreadCount;

  void start() {
    _fetchCount();
    _timer ??= Timer.periodic(const Duration(seconds: 30), (_) => _fetchCount());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refresh() => _fetchCount();

  Future<void> _fetchCount() async {
    try {
      final res = await _dio.get('/notifications/unread-count');
      final count = (res.data['count'] as int?) ?? 0;
      if (count != _unreadCount) {
        _unreadCount = count;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> fetchAll() async {
    try {
      final res = await _dio.get('/notifications');
      return (res.data as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.patch('/notifications/read-all');
      if (_unreadCount != 0) {
        _unreadCount = 0;
        notifyListeners();
      }
    } catch (_) {}
  }
}
