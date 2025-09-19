/// 应用路由常量定义
///
/// 统一管理应用中所有路由路径，避免硬编码字符串。
class AppRoutes {
  /// 私有构造函数，防止实例化
  AppRoutes._();

  /// 主页路由
  static const String home = '/';

  /// 设置页面路由
  static const String settings = '/settings';

  /// 搜索页面路由
  static const String search = '/search';

  /// 团队页面路由
  static const String team = '/team';

  /// 关于页面路由
  static const String about = '/about';

  /// 帮助页面路由
  static const String help = '/help';

  /// 所有路由列表
  static const List<String> allRoutes = [
    home,
    settings,
    search,
    team,
    about,
    help,
  ];
}
