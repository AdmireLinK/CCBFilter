import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/character.dart';
import '../utils/json_processor.dart';
import 'parser.dart';

class Extractor {
  // 源标签映射  
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

  // 源标签集合
  static final Set<String> sourceTagSet = {
    '原创', '游戏改', '小说改', '漫画改'
  };

  // 地区标签集合
  static final Set<String> regionTagSet = {
    '日本', '欧美', '美国', '中国', '法国', '韩国', '英国', '俄罗斯', '中国香港', '苏联', '捷克', '中国台湾', '马来西亚'
  };

  // 提取作品信息
  static Map<String, dynamic> extractWorkInfo(
    List<Map<String, dynamic>> charSubjects,
    Map<int, Map<String, dynamic>> subjects,
    int characterId,
    {List<int> allowedTypes = const [2, 4],
    bool includeExtraTagSubjects = false}
  ) {
    // 过滤非客串角色（主角和配角）
    final nonGuestRoles = charSubjects.where((role) {
      final roleType = role['type'] as int;
      return roleType == 1 || roleType == 2; // type=1:主角, type=2:配角
    }).toList();

    if (nonGuestRoles.isEmpty) {
      return {
        'workCount': 0,
        'highestRating': 0.0,
        'latestAppearance': 0,
        'earliestAppearance': 0,
        'appearances': [],
        'appearanceIds': [],
      };
    }

    // 过滤符合条件的作品
    final validRoles = nonGuestRoles.where((role) {
      final subjectId = role['subject_id'] as int;
      final subject = subjects[subjectId];
      if (subject == null) return false;

      final subjectType = subject['type'] as int? ?? 0;
      final isAllowedType = allowedTypes.contains(subjectType);
      
      if (includeExtraTagSubjects) {
        return isAllowedType || subjectsWithExtraTags.contains(subjectId);
      } else {
        return isAllowedType;
      }
    }).toList();

    if (validRoles.isEmpty) {
      return {
        'workCount': 0,
        'highestRating': 0.0,
        'latestAppearance': 0,
        'earliestAppearance': 0,
        'appearances': [],
        'appearanceIds': [],
      };
    }

    // 提取作品信息
    final appearances = <String>[];
    final appearanceIds = <int>[];
    double highestRating = 0.0;
    int latestAppearance = 0;
    int earliestAppearance = 9999;
    int validWorkCount = 0; // 有效作品计数（上映时间不晚于当前时间）

    // 获取当前日期
    final now = DateTime.now();
    final currentDate = DateTime(now.year, now.month, now.day);

    for (final role in validRoles) {
      final subjectId = role['subject_id'] as int;
      final subject = subjects[subjectId];
      if (subject != null) {
        final name = subject['name']?.toString() ?? '';
        final nameCn = subject['name_cn']?.toString() ?? '';
        // 修复评分数据读取逻辑：直接从score字段读取，而不是rating.score
        final rating = (subject['score'] as num?)?.toDouble() ?? 
                      (subject['rating']?['score'] as num?)?.toDouble() ?? 0.0;
        final date = subject['date']?.toString() ?? '';

        // 解析日期获取年份和完整日期
        int year = 0;
        DateTime? releaseDate;
        if (date.isNotEmpty) {
          // 尝试解析完整日期（格式：YYYY-MM-DD）
          try {
            releaseDate = DateTime.parse(date);
            year = releaseDate.year;
          } catch (e) {
            // 如果解析失败，只提取年份
            final yearMatch = RegExp(r'(\d{4})').firstMatch(date);
            if (yearMatch != null) {
              year = int.parse(yearMatch.group(1)!);
            }
          }
        }

        // 检查上映时间是否晚于当前时间
        bool isFutureRelease = false;
        if (releaseDate != null) {
          // 有完整日期，精确比较
          isFutureRelease = releaseDate.isAfter(currentDate);
        } else if (year > 0) {
          // 只有年份，比较年份
          isFutureRelease = year > now.year;
        }

        // 如果上映时间晚于当前时间，跳过该作品
        if (isFutureRelease) {
          continue;
        }

        // 使用中文名优先，没有则用原名
        final displayName = nameCn.isNotEmpty ? nameCn : name;
        appearances.add(displayName);
        appearanceIds.add(subjectId);
        validWorkCount++; // 增加有效作品计数

        // 更新最高评分
        if (rating > highestRating) {
          highestRating = rating;
        }

        // 更新最新和最早上场年份
        if (year > 0) {
          if (year > latestAppearance) {
            latestAppearance = year;
          }
          if (year < earliestAppearance) {
            earliestAppearance = year;
          }
        }
      }
    }

    // 如果没有有效的年份，设置为0
    if (earliestAppearance == 9999) {
      earliestAppearance = 0;
    }

    return {
      'workCount': validWorkCount, // 使用有效作品计数
      'highestRating': highestRating,
      'latestAppearance': latestAppearance,
      'earliestAppearance': earliestAppearance,
      'appearances': appearances,
      'appearanceIds': appearanceIds,
    };
  }

  // 提取标签信息 - 修复类型转换并去除重复标签
  static Map<String, dynamic> extractTags(
    List<Map<String, dynamic>> charSubjects,
    Map<int, Map<String, dynamic>> subjects,
    Map<int, List<String>> idTags,
    int characterId
  ) {
    // 过滤非客串角色（主角和配角）
    final nonGuestRoles = charSubjects.where((role) {
      final roleType = role['type'] as int;
      return roleType == 1 || roleType == 2; // type=1:主角, type=2:配角
    }).toList();
  
    final Map<String, int> sourceTagCounts = {};
    final Map<String, int> tagCounts = {};
    final Map<String, int> metaTagCounts = {};
    final Set<String> regionTags = {};
  
    // 2. 从作品中提取标签（基于bangumi.js的逻辑）- 只处理主角和配角
    for (final role in nonGuestRoles) {
      final subjectId = role['subject_id'] as int;
      final subject = subjects[subjectId];
      if (subject != null) {
        // 计算权重：主角权重为3，配角权重为1
        final roleType = role['type'] as int;
        final stuffFactor = roleType == 1 ? 3 : 1; // type=1:主角权重3, type=2:配角权重1
  
        // 处理元标签 - 修复类型转换
        final metaTags = subject['meta_tags'];
        if (metaTags is List) {
          for (final tag in metaTags) {
            if (tag is String && tag.isNotEmpty) {
              if (sourceTagSet.contains(tag)) {
                // 源标签跳过，后面单独处理
                continue;
              } else if (regionTagSet.contains(tag)) {
                regionTags.add(tag);
              } else {
                metaTagCounts[tag] = (metaTagCounts[tag] ?? 0) + 1 * stuffFactor;
              }
            }
          }
        }
  
        // 处理普通标签 - 修复类型转换
        final tags = subject['tags'];
        if (tags is List) {
          for (final tag in tags) {
            if (tag is Map<String, dynamic>) {
              final tagName = tag['name']?.toString() ?? '';
              final tagCount = int.tryParse(tag['count']?.toString() ?? '1') ?? 1;
              
              if (tagName.isNotEmpty && !tagName.contains('20')) {
                if (sourceTagSet.contains(tagName)) {
                  sourceTagCounts[tagName] = (sourceTagCounts[tagName] ?? 0) + tagCount * stuffFactor;
                } else if (sourceTagMap.containsKey(tagName)) {
                  final mappedTag = sourceTagMap[tagName]!;
                  sourceTagCounts[mappedTag] = (sourceTagCounts[mappedTag] ?? 0) + tagCount * stuffFactor;
                } else if (regionTagSet.contains(tagName)) {
                  regionTags.add(tagName);
                } else if (regionTags.contains(tagName)) {
                  // 跳过已处理的地区标签
                  continue;
                } else {
                  tagCounts[tagName] = (tagCounts[tagName] ?? 0) + tagCount * stuffFactor;
                }
              }
            }
          }
        }
      }
    }
  
    // 3. 标签排序和选择（基于bangumi.js的逻辑）
    // 排序源标签
    final sortedSourceTags = sourceTagCounts.entries
        .map((entry) => {entry.key: entry.value})
        .toList()
      ..sort((a, b) => b.values.first.compareTo(a.values.first));

    // 排序普通标签
    final sortedTags = tagCounts.entries
        .map((entry) => {entry.key: entry.value})
        .toList()
      ..sort((a, b) => b.values.first.compareTo(a.values.first));

    // 排序元标签
    final sortedMetaTags = metaTagCounts.entries
        .map((entry) => {entry.key: entry.value})
        .toList()
      ..sort((a, b) => b.values.first.compareTo(a.values.first));

    // 4. 构建最终标签集合（限制数量，避免过多标签）并去除重复
    final metaTags = <String>[];
    
    // 1. 首先添加从id_tags.json获取的补充标签
    final additionalTags = idTags[characterId] ?? [];
    for (final tag in additionalTags) {
      if (!metaTags.contains(tag)) {
        metaTags.add(tag);
      }
    }
    
    // 2. 按照权重高低顺序添加其他类型的标签
    int otherTagsCount = 0;
    const maxOtherTags = 15;
    
    // 只添加一个源标签以避免混淆
    if (sortedSourceTags.isNotEmpty && otherTagsCount < maxOtherTags) {
      final tagName = sortedSourceTags.first.keys.first;
      if (!metaTags.contains(tagName)) {
        metaTags.add(tagName);
        otherTagsCount++;
      }
    }

    // 添加元标签（最多5个）并去除重复
    for (final tagObj in sortedMetaTags) {
      if (otherTagsCount >= maxOtherTags) break; // 其他类型标签数限制
      final tagName = tagObj.keys.first;
      if (!metaTags.contains(tagName)) { // 检查是否已存在
        metaTags.add(tagName);
        otherTagsCount++;
      }
    }

    // 添加普通标签（最多5个）并去除重复
    for (final tagObj in sortedTags) {
      if (otherTagsCount >= maxOtherTags) break; // 其他类型标签数限制
      final tagName = tagObj.keys.first;
      if (!metaTags.contains(tagName)) { // 检查是否已存在
        metaTags.add(tagName);
        otherTagsCount++;
      }
    }

    // 添加地区标签并去除重复
    for (final regionTag in regionTags) {
      if (otherTagsCount >= maxOtherTags) break; // 其他类型标签数限制
      if (!metaTags.contains(regionTag)) { // 检查是否已存在
        metaTags.add(regionTag);
        otherTagsCount++;
      }
    }
  
    return {
      'metaTags': metaTags,
    };
  }

  // 提取声优信息并去除重复
  static List<String> extractAnimeVAs(
    int characterId,
    Map<int, List<Map<String, dynamic>>> personCharacters,
    Map<int, List<Map<String, dynamic>>> subjectPersons,
    Map<int, Map<String, dynamic>> persons,
    Map<int, Map<String, dynamic>> subjects
  ) {
    final animeVAs = <String>[];
    
    // 获取角色对应的声优关系
    final characterVAs = personCharacters[characterId] ?? [];
    
    for (final vaRelation in characterVAs) {
      final personId = vaRelation['person_id'] as int;
      final person = persons[personId];
      
      if (person != null) {
        // 获取声优的中文名
        final nameCn = person['name_cn']?.toString() ?? '';
        final name = person['name']?.toString() ?? '';
        
        // 优先使用中文名，没有则用原名
        final displayName = nameCn.isNotEmpty ? nameCn : name;
        if (displayName.isNotEmpty && !animeVAs.contains(displayName)) {
          // 检查是否已存在，避免重复添加
          animeVAs.add(displayName);
        }
      }
    }
    
    return animeVAs;
  }

  // 主处理函数
  static Future<Map<String, List<CharacterInfo>>> processAllData() async {
    final projectRoot = Directory.current.path;
    final dumpDir = path.join(projectRoot, 'dump');

    try {
      // 1. 获取所有可能的角色ID
      final characterIds = JsonProcessor.getCharacterIdsFromImages(
        path.join(dumpDir, 'character_images.json')
      );

      // 2. 解析所有必要的数据文件
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
      final idTags = JsonProcessor.parseIdTags(
        path.join(dumpDir, 'id_tags.json')
      );
      final persons = JsonProcessor.parsePersonJsonlines(
        path.join(dumpDir, 'person.jsonlines')
      );
      final personCharacters = JsonProcessor.parsePersonCharactersJsonlines(
        path.join(dumpDir, 'person-characters.jsonlines')
      );
      final subjectPersons = JsonProcessor.parseSubjectPersonsJsonlines(
        path.join(dumpDir, 'subject-persons.jsonlines')
      );

      // 3. 处理所有类型作品的角色信息
      final allTypesCharacters = <CharacterInfo>[];
      final animeOnlyCharacters = <CharacterInfo>[];

      for (final characterId in characterIds) {
        final characterData = characters[characterId];
        if (characterData == null) continue;

        final charSubjects = characterSubjects[characterId] ?? [];
        if (charSubjects.isEmpty) continue;

        // 获取角色基本信息
        final name = characterData['name']?.toString() ?? '';
        final nameCn = characterData['name_cn']?.toString() ?? '';
        final gender = Parser.parseGender(characterData['gender']);
        final collects = characterData['collects'] as int? ?? 0;
        final comments = characterData['comments'] as int? ?? 0;
        final popularity = collects + comments; 

        // 提取作品信息 - 所有类型（番剧和游戏）
        final allTypesWorkInfo = extractWorkInfo(
          charSubjects, subjects, characterId,
          allowedTypes: [2, 4], // 番剧和游戏
          includeExtraTagSubjects: false
        );

        // 提取作品信息 - 仅番剧模式（包含额外标签作品）
        final animeOnlyWorkInfo = extractWorkInfo(
          charSubjects, subjects, characterId,
          allowedTypes: [2], // 仅番剧
          includeExtraTagSubjects: true
        );

        // 提取声优信息
        final animeVAs = extractAnimeVAs(
          characterId, personCharacters, subjectPersons, persons, subjects
        );

        // 提取标签信息
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

        // 创建角色信息对象 - 所有类型
        final allTypesCharacter = CharacterInfo(
          id: characterId,
          name: name,
          nameCn: nameCn,
          gender: gender,
          popularity: popularity, 
          appearances: List<String>.from(allTypesWorkInfo['appearances'] ?? []),
          appearanceIds: List<int>.from(allTypesWorkInfo['appearanceIds'] ?? []),
          latestAppearance: allTypesWorkInfo['latestAppearance'] as int,
          earliestAppearance: allTypesWorkInfo['earliestAppearance'] as int,
          highestRating: allTypesWorkInfo['highestRating'] as double,
          animeVAs: animeVAs,
          metaTags: List<String>.from(allTypesTags['metaTags'] ?? []),
        );

        // 创建角色信息对象 - 仅番剧
        final animeOnlyCharacter = CharacterInfo(
          id: characterId,
          name: name,
          nameCn: nameCn,
          gender: gender,
          popularity: popularity,
          appearances: List<String>.from(animeOnlyWorkInfo['appearances'] ?? []),
          appearanceIds: List<int>.from(animeOnlyWorkInfo['appearanceIds'] ?? []),
          latestAppearance: animeOnlyWorkInfo['latestAppearance'] as int,
          earliestAppearance: animeOnlyWorkInfo['earliestAppearance'] as int,
          highestRating: animeOnlyWorkInfo['highestRating'] as double,
          animeVAs: animeVAs,
          metaTags: List<String>.from(animeOnlyTags['metaTags'] ?? []),
        );

        allTypesCharacters.add(allTypesCharacter);
        animeOnlyCharacters.add(animeOnlyCharacter);
      }

      // 4. 返回处理结果
      return {
        'All': allTypesCharacters,
        'Anime': animeOnlyCharacters,
      };

    } catch (e) {
      print('Error processing data: $e');
      rethrow;
    }
  }

  // 保存处理结果到文件
  static Future<void> saveToFiles(Map<String, List<CharacterInfo>> processedData) async {
    final projectRoot = Directory.current.path;
    final outputDir = path.join(projectRoot, 'data');

    // 保存所有类型作品的角色信息
    final allFile = File(path.join(outputDir, 'All.json'));
    final allJson = processedData['All']!
        .map((character) => character.toJson())
        .toList();
    await JsonProcessor.saveJsonFile(allFile.path, allJson);

    // 保存仅番剧作品的角色信息
    final animeFile = File(path.join(outputDir, 'Anime.json'));
    final animeJson = processedData['Anime']!
        .map((character) => character.toJson())
        .toList();
    await JsonProcessor.saveJsonFile(animeFile.path, animeJson);

    print('Data saved to: ${allFile.path} and ${animeFile.path}');
  }
}