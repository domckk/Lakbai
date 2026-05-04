import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ActiveDestination {
  const ActiveDestination({required this.id, required this.slug, required this.name});
  final String id;
  final String slug;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'slug': slug, 'name': name};

  factory ActiveDestination.fromJson(Map<String, dynamic> j) => ActiveDestination(
        id: j['id'] as String,
        slug: j['slug'] as String,
        name: j['name'] as String,
      );
}

class ActiveDestinationNotifier extends StateNotifier<ActiveDestination?> {
  ActiveDestinationNotifier() : super(null) {
    _hydrate();
  }

  static const _storage = FlutterSecureStorage();
  static const _key = 'active_destination_v1';

  Future<void> _hydrate() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw != null && mounted) {
        state = ActiveDestination.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {}
  }

  void choose(ActiveDestination dest) {
    state = dest;
    _storage
        .write(key: _key, value: jsonEncode(dest.toJson()))
        .catchError((_) {});
  }

  void clear() {
    state = null;
    _storage.delete(key: _key).catchError((_) {});
  }
}

final activeDestinationProvider =
    StateNotifierProvider<ActiveDestinationNotifier, ActiveDestination?>(
  (ref) => ActiveDestinationNotifier(),
);
