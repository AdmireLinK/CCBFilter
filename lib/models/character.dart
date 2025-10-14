// 角色信息结构体
class CharacterInfo {
  final int id;
  final String name;
  final String nameCn;
  final String gender;
  final int popularity;
  final List<String> appearances;
  final List<int> appearanceIds;
  final int latestAppearance;
  final int earliestAppearance;
  final double highestRating;
  final List<String> animeVAs;
  final List<String> metaTags;

  CharacterInfo({
    required this.id,
    required this.name,
    required this.nameCn,
    required this.gender,
    required this.popularity,
    required this.appearances,
    required this.appearanceIds,
    required this.latestAppearance,
    required this.earliestAppearance,
    required this.highestRating,
    required this.animeVAs,
    required this.metaTags,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameCn': nameCn,
      'gender': gender,
      'popularity': popularity,
      'appearances': appearances,
      'appearanceIds': appearanceIds,
      'latestAppearance': latestAppearance,
      'earliestAppearance': earliestAppearance,
      'highestRating': highestRating,
      'animeVAs': animeVAs,
      'metaTags': metaTags,
    };
  }

  // 获取作品数量
  int get workCount => appearances.length;
}

// 包含额外标签的作品ID集合
final Set<int> subjectsWithExtraTags = {
  18011, // 英雄联盟
  20810, // 刀塔2
  175552, // 赛马娘 Pretty Derby
  225878, // 明日方舟
  284157, // 原神
  360097, // 崩坏：星穹铁道
  380974, // 绝区零
  194792, // 王者荣耀
  172168, // 崩坏3
  300648, // 蔚蓝档案
  385208, // 鸣潮
  208559, // 碧蓝航线
  109378, // 命运-冠位指定
  228217, // 第五人格
  296327, // 永劫无间
  208415, // BanG Dream! 少女乐团派对！
  293554, // 战双帕弥什
  378389, // 尘白禁区
  219588, // 公主连结！Re:Dive
  365720, // 重返未来：1999
};