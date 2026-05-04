import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';

class QuestsState {
  const QuestsState({this.slug, this.quests = const [], this.loading = false});
  final String? slug;
  final List<dynamic> quests;
  final bool loading;

  QuestsState copyWith({String? slug, List<dynamic>? quests, bool? loading}) =>
      QuestsState(
        slug: slug ?? this.slug,
        quests: quests ?? this.quests,
        loading: loading ?? this.loading,
      );
}

class QuestsNotifier extends StateNotifier<QuestsState> {
  QuestsNotifier() : super(const QuestsState());

  Future<void> fetch(String slug) async {
    // Already cached for this slug and not currently loading — skip network call
    if (state.slug == slug && (state.quests.isNotEmpty || state.loading)) return;

    // Show stale data while reloading if the slug changed
    state = QuestsState(slug: slug, quests: const [], loading: true);
    try {
      final res = await buildDio().get('/quests?destinationSlug=$slug');
      if (mounted) state = QuestsState(slug: slug, quests: res.data as List);
    } catch (_) {
      if (mounted) state = state.copyWith(loading: false);
    }
  }

  void invalidate() => state = const QuestsState();
}

final questsNotifierProvider =
    StateNotifierProvider<QuestsNotifier, QuestsState>(
  (ref) => QuestsNotifier(),
);
