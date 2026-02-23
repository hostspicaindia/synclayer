/// Logging utility for SyncLayer SDK
///
/// Provides structured logging with different levels and optional callbacks
/// for custom logging implementations.
class SyncLogger {
  static SyncLogger? _instance;
  static bool _isEnabled = true;
  static LogLevel _minLevel = LogLevel.info;
  static void Function(LogLevel level, String message,
      [dynamic error, StackTrace? stackTrace])? _customLogger;

  SyncLogger._();

  static SyncLogger get instance {
    _instance ??= SyncLogger._();
    return _instance!;
  }

  /// Enable or disable logging
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Set minimum log level
  static void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  /// Set custom logger callback
  ///
  /// Example:
  /// ```dart
  /// SyncLogger.setCustomLogger((level, message, error, stackTrace) {
  ///   // Send to your analytics service
  ///   analytics.log(level.name, message);
  /// });
  /// ```
  static void setCustomLogger(
    void Function(LogLevel level, String message,
            [dynamic error, StackTrace? stackTrace])?
        logger,
  ) {
    _customLogger = logger;
  }

  /// Log debug message
  void debug(String message) {
    _log(LogLevel.debug, message);
  }

  /// Log info message
  void info(String message) {
    _log(LogLevel.info, message);
  }

  /// Log warning message
  void warning(String message, [dynamic error]) {
    _log(LogLevel.warning, message, error);
  }

  /// Log error message
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  void _log(LogLevel level, String message,
      [dynamic error, StackTrace? stackTrace]) {
    if (!_isEnabled || level.index < _minLevel.index) {
      return;
    }

    final timestamp = DateTime.now().toIso8601String();
    final prefix = _getLevelPrefix(level);
    final formattedMessage = '[$timestamp] $prefix $message';

    // Call custom logger if set
    if (_customLogger != null) {
      _customLogger!(level, message, error, stackTrace);
    }

    // Default console logging
    if (error != null) {
      print('$formattedMessage\nError: $error');
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
    } else {
      print(formattedMessage);
    }
  }

  String _getLevelPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍 DEBUG';
      case LogLevel.info:
        return 'ℹ️  INFO';
      case LogLevel.warning:
        return '⚠️  WARN';
      case LogLevel.error:
        return '❌ ERROR';
    }
  }
}

/// Log levels for SyncLayer
enum LogLevel {
  debug,
  info,
  warning,
  error,
}
