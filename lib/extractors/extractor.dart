import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/character.dart';
import '../models/work_stats.dart';
import '../utils/json_processor.dart';
import 'parser.dart';

/// 提供角色聚合、标签筛选与结果序列化的核心逻辑
class Extractor {
  /// 源标签映射（冗余写法会统一归并到这张表）
  static final Map<String, String> sourceTagMap = {
    'GAL改': '游戏改',
    '轻小说改': '小说改',
    '轻改': '小说改',
    '原创动画': '原创',
    '网文改': '小说改',
    '漫改': '漫画改',
    '漫画改编': '漫画改',
    '游戏改编': '游戏改',
    '小说改编': '小说改'
  };

  /// 源标签集合，保证输出仅出现这些归一化值
  static final Set<String> sourceTagSet = {'原创', '游戏改', '小说改', '漫画改'};

  /// 地区标签集合，独立于一般标签计数
  static final Set<String> regionTagSet = {
    '日本', '欧美', '美国', '中国', '法国', '韩国', '英国', '俄罗斯', '中国香港', '苏联', '捷克', '中国台湾', '马来西亚'
  };

  static const int _mainRoleWeight = 3;
  static const int _supportRoleWeight = 1;
  static const int _defaultEarliestYear = 9999;
  static const int _maxAutoTags = 15;

  /// 根据角色作品关联关系提取作品统计信息
  static WorkStats extractWorkInfo(
    List<Map<String, dynamic>> charSubjects,
    Map<int, Map<String, dynamic>> subjects, {
    List<int> allowedTypes = const [2, 4],
    bool includeExtraTagSubjects = false,
  }
  ) {
    final nonGuestRoles = _filterMainRoles(charSubjects);
    if (nonGuestRoles.isEmpty) {
      return WorkStats.empty();
    }

    final validRoles = nonGuestRoles.where((role) {
      final subjectId = role['subject_id'] as int;
      final subject = subjects[subjectId];
      if (subject == null) return false;

      final subjectType = subject['type'] as int? ?? 0;
      final isAllowedType = allowedTypes.contains(subjectType);
      return includeExtraTagSubjects
          ? isAllowedType || subjectsWithExtraTags.contains(subjectId)
          : isAllowedType;
    }).toList();

    if (validRoles.isEmpty) {
      return WorkStats.empty();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final appearances = <String>[];
    final appearanceIds = <int>[];
    var highestRating = 0.0;
    var latestAppearance = 0;
    var earliestAppearance = _defaultEarliestYear;
    var validWorkCount = 0;

    for (final role in validRoles) {
      final subjectId = role['subject_id'] as int;
      final subject = subjects[subjectId];
      if (subject == null) continue;

      final rating = _parseSubjectRating(subject);
      final releaseMeta = _parseReleaseMeta(subject['date']?.toString() ?? '');
      if (_isFutureRelease(releaseMeta, today, now.year)) {
        continue;
      }

      final displayName = _pickDisplayName(
        subject['name_cn']?.toString() ?? '',
        subject['name']?.toString() ?? '',
      );

      appearances.add(displayName);
      appearanceIds.add(subjectId);
      validWorkCount++;

      if (rating > highestRating) {
        highestRating = rating;
      }

      final year = releaseMeta.year;
      if (year != null) {
        if (year > latestAppearance) {
          latestAppearance = year;
        }
        if (year < earliestAppearance) {
          earliestAppearance = year;
        }
      }
    }

    if (earliestAppearance == _defaultEarliestYear) {
      earliestAppearance = 0;
    }

    return WorkStats(
      workCount: validWorkCount,
      highestRating: highestRating,
      latestAppearance: latestAppearance,
      earliestAppearance: earliestAppearance,
      appearances: appearances,
      appearanceIds: appearanceIds,
    );
  }

  /// 提取标签信息（按照策划要求补充、排序并裁剪）
  static List<String> extractTags(
    List<Map<String, dynamic>> charSubjects,
    Map<int, Map<String, dynamic>> subjects,
    Map<int, List<String>> idTags,
    int characterId
  ) {
    final nonGuestRoles = _filterMainRoles(charSubjects);

    final Map<String, int> sourceTagCounts = {};
    final Map<String, int> tagCounts = {};
    final Map<String, int> metaTagCounts = {};
    final Set<String> regionTags = {};

    for (final role in nonGuestRoles) {
      final subjectId = role['subject_id'] as int;
      final subject = subjects[subjectId];
      if (subject != null) {
        final roleType = role['type'] as int;
        final stuffFactor = roleType == 1 ? _mainRoleWeight : _supportRoleWeight;

        final metaTags = subject['meta_tags'];
        if (metaTags is List) {
          for (final tag in metaTags) {
            if (tag is String && tag.isNotEmpty) {
              if (sourceTagSet.contains(tag)) {
                continue;
              } else if (regionTagSet.contains(tag)) {
                regionTags.add(tag);
              } else {
                metaTagCounts[tag] = (metaTagCounts[tag] ?? 0) + 1 * stuffFactor;
              }
            }
          }
        }
  
        final tags = subject['tags'];
        if (tags is List) {
          for (final tag in tags) {
            if (tag is Map<String, dynamic>) {
              final tagName = tag['name']?.toString() ?? '';
              final tagCount = int.tryParse(tag['count']?.toString() ?? '1') ?? 1;
              
              if (tagName.isNotEmpty && !tagName.contains('20')) {
                if (sourceTagSet.contains(tagName)) {
                  sourceTagCounts[tagName] = (sourceTagCounts[tagName] ?? 0) +
                      tagCount * stuffFactor;
                } else if (sourceTagMap.containsKey(tagName)) {
                  final mappedTag = sourceTagMap[tagName]!;
                  sourceTagCounts[mappedTag] = (sourceTagCounts[mappedTag] ?? 0) +
                      tagCount * stuffFactor;
                } else if (regionTagSet.contains(tagName)) {
                  regionTags.add(tagName);
                } else if (regionTags.contains(tagName)) {
                  continue;
                } else {
                  tagCounts[tagName] = (tagCounts[tagName] ?? 0) +
                      tagCount * stuffFactor;
                }
              }
            }
          }
        }
      }
    }
  
    final sortedSourceTags = _sortByWeight(sourceTagCounts);
    final sortedTags = _sortByWeight(tagCounts);
    final sortedMetaTags = _sortByWeight(metaTagCounts);

    final metaTags = <String>[];

    final additionalTags = idTags[characterId] ?? [];
    for (final tag in additionalTags) {
      if (!metaTags.contains(tag)) {
        metaTags.add(tag);
      }
    }

    var otherTagsCount = 0;

    if (sortedSourceTags.isNotEmpty && otherTagsCount < _maxAutoTags) {
      final tagName = sortedSourceTags.first;
      if (!metaTags.contains(tagName)) {
        metaTags.add(tagName);
        otherTagsCount++;
      }
    }

    for (final tagName in sortedMetaTags) {
      if (otherTagsCount >= _maxAutoTags) break;
      if (!metaTags.contains(tagName)) {
        metaTags.add(tagName);
        otherTagsCount++;
      }
    }

    for (final tagName in sortedTags) {
      if (otherTagsCount >= _maxAutoTags) break;
      if (!metaTags.contains(tagName)) {
        metaTags.add(tagName);
        otherTagsCount++;
      }
    }

    for (final regionTag in regionTags) {
      if (otherTagsCount >= _maxAutoTags) break;
      if (!metaTags.contains(regionTag)) {
        metaTags.add(regionTag);
        otherTagsCount++;
      }
    }

    return metaTags;
  }

  /// 提取角色对应的声优列表（中文名优先）
  static List<String> extractAnimeVAs(
    int characterId,
    Map<int, List<Map<String, dynamic>>> personCharacters,
    Map<int, Map<String, dynamic>> persons,
  ) {
    final animeVAs = <String>[];
    final characterVAs = personCharacters[characterId] ?? [];
    for (final vaRelation in characterVAs) {
      final personId = vaRelation['person_id'] as int;
      final person = persons[personId];
      if (person != null) {
        final nameCn = person['name_cn']?.toString() ?? '';
        final name = person['name']?.toString() ?? '';
        final displayName = nameCn.isNotEmpty ? nameCn : name;
        if (displayName.isNotEmpty && !animeVAs.contains(displayName)) {
          animeVAs.add(displayName);
        }
      }
    }
    return animeVAs;
  }

  /// 主处理函数，负责驱动整条数据加工流水线
  static Future<Map<String, List<CharacterInfo>>> processAllData() async {
    final projectRoot = Directory.current.path;
    final dumpDir = path.join(projectRoot, 'dump');

    try {
      // 解析必要的原始数据文件
      final charactersData = JsonProcessor.readJsonLinesFile(
        path.join(dumpDir, 'character.jsonlines')
      );
      final characters = Parser.parseCharacterData(charactersData);
      
      final subjects = JsonProcessor.parseSubjectJsonlines(
        path.join(dumpDir, 'subject.jsonlines')
      );
      final characterSubjects = JsonProcessor.parseSubjectCharactersJsonlines(
        path.join(dumpDir, 'subject-characters.jsonlines')
      );
      // 用 subject-characters.jsonlines 中所有主角/配角角色作为目标角色集合
      final characterIds = characterSubjects.entries
          .where((e) => e.value.any((r) {
                final t = r['type'] as int? ?? 0;
                return t == 1 || t == 2; // 1: 主角, 2: 配角
              }))
          .map((e) => e.key)
          .toList();

      final idTags = JsonProcessor.parseIdTags(
        path.join(dumpDir, 'id_tags.json')
      );
      final persons = JsonProcessor.parsePersonJsonlines(
        path.join(dumpDir, 'person.jsonlines')
      );
      final personCharacters = JsonProcessor.parsePersonCharactersJsonlines(
        path.join(dumpDir, 'person-characters.jsonlines')
      );

      final allTypesCharacters = <CharacterInfo>[];
      final animeOnlyCharacters = <CharacterInfo>[];

      for (final characterId in characterIds) {
        final characterData = characters[characterId];
        if (characterData == null) continue;

        final charSubjects = characterSubjects[characterId] ?? [];
        if (charSubjects.isEmpty) continue;

        final name = characterData['name']?.toString() ?? '';
        final nameCn = characterData['name_cn']?.toString() ?? '';
        final gender = Parser.parseGender(characterData['gender']);
        final collects = characterData['collects'] as int? ?? 0;
        final comments = characterData['comments'] as int? ?? 0;
        final popularity = collects + comments; 

        final allTypesWorkInfo = extractWorkInfo(
          charSubjects, subjects,
          allowedTypes: [2, 4], // 番剧和游戏
          includeExtraTagSubjects: false
        );

        final animeOnlyWorkInfo = extractWorkInfo(
          charSubjects, subjects,
          allowedTypes: [2], // 仅番剧
          includeExtraTagSubjects: true
        );

        final animeVAs = extractAnimeVAs(characterId, personCharacters, persons);

        final allTypesTags = extractTags(charSubjects, subjects, idTags, characterId);
        final animeOnlyTags = extractTags(
          charSubjects.where((role) {
            final subjectId = role['subject_id'] as int;
            final subject = subjects[subjectId];
            final subjectType = subject?['type'] as int? ?? 0;
            return subjectType == 2 || subjectsWithExtraTags.contains(subjectId);
          }).toList(),
          subjects, idTags, characterId
        );

        final allTypesCharacter = CharacterInfo(
          id: characterId,
          name: name,
          nameCn: nameCn,
          gender: gender,
          popularity: popularity, 
          appearances: List<String>.from(allTypesWorkInfo.appearances),
          appearanceIds: List<int>.from(allTypesWorkInfo.appearanceIds),
          latestAppearance: allTypesWorkInfo.latestAppearance,
          earliestAppearance: allTypesWorkInfo.earliestAppearance,
          highestRating: allTypesWorkInfo.highestRating,
          animeVAs: animeVAs,
          metaTags: List<String>.from(allTypesTags),
        );

        final animeOnlyCharacter = CharacterInfo(
          id: characterId,
          name: name,
          nameCn: nameCn,
          gender: gender,
          popularity: popularity,
          appearances: List<String>.from(animeOnlyWorkInfo.appearances),
          appearanceIds: List<int>.from(animeOnlyWorkInfo.appearanceIds),
          latestAppearance: animeOnlyWorkInfo.latestAppearance,
          earliestAppearance: animeOnlyWorkInfo.earliestAppearance,
          highestRating: animeOnlyWorkInfo.highestRating,
          animeVAs: animeVAs,
          metaTags: List<String>.from(animeOnlyTags),
        );

        allTypesCharacters.add(allTypesCharacter);
        animeOnlyCharacters.add(animeOnlyCharacter);
      }

      return {
        'All': allTypesCharacters,
        'Anime': animeOnlyCharacters,
      };

    } catch (e) {
      rethrow;
    }
  }

  /// 将处理结果写入磁盘
  static Future<void> saveToFiles(Map<String, List<CharacterInfo>> processedData) async {
    final projectRoot = Directory.current.path;
    final outputDir = path.join(projectRoot, 'data');

    final allFile = File(path.join(outputDir, 'All.json'));
    final allSorted = [...processedData['All']!]
      ..sort((a, b) => b.popularity.compareTo(a.popularity));
    final allJson = allSorted.map((c) => c.toJson()).toList();
    await JsonProcessor.saveJsonFile(allFile.path, allJson);

    final animeFile = File(path.join(outputDir, 'Anime.json'));
    final animeSorted = [...processedData['Anime']!]
      ..sort((a, b) => b.popularity.compareTo(a.popularity));
    final animeJson = animeSorted.map((c) => c.toJson()).toList();
    await JsonProcessor.saveJsonFile(animeFile.path, animeJson);

  }

  /// 过滤出主角/配角关联记录
  static List<Map<String, dynamic>> _filterMainRoles(List<Map<String, dynamic>> charSubjects) {
    return charSubjects.where((role) {
      final roleType = role['type'] as int? ?? 0;
      return roleType == 1 || roleType == 2;
    }).toList();
  }

  /// 按照权重排序标签，返回标签名称列表
  static List<String> _sortByWeight(Map<String, int> tagCounts) {
    final entries = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((entry) => entry.key).toList();
  }

  /// 解析作品评分，兼容旧数据字段
  static double _parseSubjectRating(Map<String, dynamic> subject) {
    final score = subject['score'];
    if (score is num) {
      return score.toDouble();
    }
    final rating = subject['rating'];
    if (rating is Map<String, dynamic>) {
      final ratingScore = rating['score'];
      if (ratingScore is num) {
        return ratingScore.toDouble();
      }
    }
    return 0.0;
  }

  /// 解析发布日期，兼容无法直接解析成日期的场景
  static _ReleaseMeta _parseReleaseMeta(String rawDate) {
    if (rawDate.isEmpty) {
      return const _ReleaseMeta();
    }

    try {
      final parsed = DateTime.parse(rawDate);
      return _ReleaseMeta(date: parsed, year: parsed.year);
    } catch (_) {
      final yearMatch = RegExp(r'(\d{4})').firstMatch(rawDate);
      if (yearMatch != null) {
        return _ReleaseMeta(year: int.parse(yearMatch.group(1)!));
      }
      return const _ReleaseMeta();
    }
  }

  /// 判断作品是否在未来
  static bool _isFutureRelease(_ReleaseMeta meta, DateTime today, int currentYear) {
    if (meta.date != null) {
      return meta.date!.isAfter(today);
    }
    if (meta.year != null) {
      return meta.year! > currentYear;
    }
    return false;
  }

  /// 统一选择展示名称，中文名优先
  static String _pickDisplayName(String nameCn, String name) {
    if (nameCn.isNotEmpty) {
      return nameCn;
    }
    return name;
  }
}

class _ReleaseMeta {
  /// 作品上映的完整日期
  final DateTime? date;

  /// 仅年份信息（部分作品只有年份可用）
  final int? year;

  const _ReleaseMeta({this.date, this.year});
}