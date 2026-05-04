abstract final class AppConfig {
  static const String apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'https://lakbai-production.up.railway.app/v1');
  static const String mapboxToken =
      String.fromEnvironment('MAPBOX_TOKEN', defaultValue: '');

  /// Resolves a relative image path from the API (e.g. /images/foo.jpg)
  /// to a full URL. Absolute URLs (http/https) are returned unchanged.
  static String imageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final host = apiBaseUrl.replaceAll(RegExp(r'/v\d+/?$'), '');
    return '$host$path';
  }
}
