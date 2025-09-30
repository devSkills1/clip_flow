/// 应用配置管理
/// 支持开发和生产环境的配置隔离
class AppConfig {
  static const String _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'dev',
  );

  /// 当前环境
  static AppEnvironment get environment {
    switch (_environment.toLowerCase()) {
      case 'prod':
      case 'production':
        return AppEnvironment.production;
      case 'dev':
      case 'development':
      default:
        return AppEnvironment.development;
    }
  }

  /// 应用包名
  static String get packageName {
    switch (environment) {
      case AppEnvironment.production:
        return 'com.clipflow.pro';
      case AppEnvironment.development:
        return 'com.clipflow.pro.dev';
    }
  }

  /// 应用显示名称
  static String get appName {
    switch (environment) {
      case AppEnvironment.production:
        return 'ClipFlow Pro';
      case AppEnvironment.development:
        return 'ClipFlow Pro (Dev)';
    }
  }

  /// 应用版本后缀
  static String get versionSuffix {
    switch (environment) {
      case AppEnvironment.production:
        return '';
      case AppEnvironment.development:
        return '-dev';
    }
  }

  /// 是否为开发环境
  static bool get isDevelopment => environment == AppEnvironment.development;

  /// 是否为生产环境
  static bool get isProduction => environment == AppEnvironment.production;

  /// 数据库名称
  static String get databaseName {
    switch (environment) {
      case AppEnvironment.production:
        return 'clipflow_pro.db';
      case AppEnvironment.development:
        return 'clipflow_pro_dev.db';
    }
  }

  /// 日志级别
  static LogLevel get logLevel {
    switch (environment) {
      case AppEnvironment.production:
        return LogLevel.warning;
      case AppEnvironment.development:
        return LogLevel.debug;
    }
  }

  /// 调试模式
  static bool get enableDebugFeatures => isDevelopment;

  /// 性能监控
  static bool get enablePerformanceMonitoring => isProduction;
}

/// 应用环境枚举
enum AppEnvironment {
  development,
  production,
}

/// 日志级别
enum LogLevel {
  debug,
  info,
  warning,
  error,
}
