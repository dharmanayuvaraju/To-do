class UpdateService {
  static const String currentVersion = '1.0.0';
  static const int currentVersionCode = 1;

  /// Check for updates
  static Future<Map<String, dynamic>> checkForUpdates() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return {
      'hasUpdate': false,
      'currentVersion': currentVersion,
      'latestVersion': currentVersion,
      'message': 'Do It Now is up to date with love ❤️',
    };
  }
}
