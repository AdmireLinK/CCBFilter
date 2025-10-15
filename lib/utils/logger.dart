import 'dart:developer' as developer;

/// 日志级别枚举
enum LogLevel { debug, info, warning, error }

/// 统一的日志系统
class Logger {
  static LogLevel _minLevel = LogLevel.info;

  /// 设置最小日志级别
  static void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  /// 调试日志
  static void debug(String message, {String? tag}) {
    _log(LogLevel.debug, message, tag: tag);
  }

  /// 信息日志
  static void info(String message, {String? tag}) {
    _log(LogLevel.info, message, tag: tag);
  }

  /// 警告日志
  static void warning(String message, {String? tag, Object? error}) {
    _log(LogLevel.warning, message, tag: tag, error: error);
  }

  /// 错误日志
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.error,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 内部日志记录方法
  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < _minLevel.index) {
      return;
    }

    final levelName = level.toString().split('.').last.toUpperCase();
    final timestamp = DateTime.now().toIso8601String();
    final tagPrefix = tag != null ? '[$tag] ' : '';

    // 构建完整的日志消息
    String logMessage = '$timestamp [$levelName] $tagPrefix$message';

    if (error != null) {
      logMessage += '\nError: $error';
    }

    if (stackTrace != null) {
      logMessage += '\nStack trace: $stackTrace';
    }

    // 使用dart:developer的log方法，可以在Flutter DevTools中查看
    developer.log(logMessage, level: level.index, time: DateTime.now());
  }
}
