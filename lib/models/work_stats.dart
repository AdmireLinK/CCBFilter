class WorkStats {
  /// 角色作品统计信息
  final int workCount;
  final double highestRating;
  final int latestAppearance;
  final int earliestAppearance;
  final List<String> appearances;
  final List<int> appearanceIds;

  const WorkStats({
    required this.workCount,
    required this.highestRating,
    required this.latestAppearance,
    required this.earliestAppearance,
    required this.appearances,
    required this.appearanceIds,
  });

  /// 空状态工厂，避免在逻辑中频繁构造默认值
  factory WorkStats.empty() {
    return const WorkStats(
      workCount: 0,
      highestRating: 0.0,
      latestAppearance: 0,
      earliestAppearance: 0,
      appearances: <String>[],
      appearanceIds: <int>[],
    );
  }

  /// 判断当前角色是否存在有效作品
  bool get hasWorks => workCount > 0;
}
