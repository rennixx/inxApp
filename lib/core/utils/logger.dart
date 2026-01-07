class AppLogger {
  AppLogger._();

  static const bool _enableLogs = true;

  static void debug(String message, {String? tag}) {
    if (_enableLogs) {
      final prefix = tag != null ? '[$tag] ' : '';
      print('[DEBUG] $prefix$message');
    }
  }

  static void info(String message, {String? tag}) {
    if (_enableLogs) {
      final prefix = tag != null ? '[$tag] ' : '';
      print('[INFO] $prefix$message');
    }
  }

  static void warning(String message, {String? tag}) {
    if (_enableLogs) {
      final prefix = tag != null ? '[$tag] ' : '';
      print('[WARNING] $prefix$message');
    }
  }

  static void error(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    final prefix = tag != null ? '[$tag] ' : '';
    print('[ERROR] $prefix$message');
    if (error != null) {
      print('Error: $error');
    }
    if (stackTrace != null) {
      print(stackTrace);
    }
  }
}
