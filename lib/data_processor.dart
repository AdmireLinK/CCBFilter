import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

// 包含额外标签的作品ID集合（来自extra_tag_subjects.js）
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

// 角色信息结构体
class CharacterInfo {
  final int id;
  final String name;
  final String nameCn;
  final String gender;
  final int collects;
  final int workCount;
  final double highestRating;
  final int latestAppearance;
  final int earliestAppearance;
  final List<String> tags;
  final List<String> workNames;

  CharacterInfo({
    required this.id,
    required this.name,
    required this.nameCn,
    required this.gender,
    required this.collects,
    required this.workCount,
    required this.highestRating,
    required this.latestAppearance,
    required this.earliestAppearance,
    required this.tags,
    required this.workNames,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameCn': nameCn,
      'gender': gender,
      'collects': collects,
      'workCount': workCount,
      'highestRating': highestRating,
      'latestAppearance': latestAppearance,
      'earliestAppearance': earliestAppearance,
      'tags': tags,
      'workNames': workNames,
    };
  }
}

class DataProcessor {
  // 从character_images.json获取所有可能的角色ID
  List<int> getCharacterIdsFromImages(String filePath) {
    final file = File(filePath);
    final content = file.readAsStringSync();
    final List<dynamic> data = json.decode(content);
    
    return data.map<int>((item) => item['id'] as int).toList();
  }

  // 解析character.jsonlines文件 - 增强版，支持infobox解析
  Map<int, Map<String, dynamic>> parseCharacterJsonlines(String filePath) {
    final file = File(filePath);
    final lines = file.readAsLinesSync();
    final Map<int, Map<String, dynamic>> characters = {};

    for (final line in lines) {
      try {
        final data = json.decode(line) as Map<String, dynamic>;
        final id = data['id'] as int;
        
        // 解析infobox获取中文名和性别
        final infobox = data['infobox']?.toString() ?? '';
        if (infobox.isNotEmpty) {
          final nameCn = parseNameCnFromInfobox(infobox);
          if (nameCn.isNotEmpty) {
            data['name_cn'] = nameCn;
          }
          
          final gender = parseGenderFromInfobox(infobox);
          if (gender.isNotEmpty) {
            data['gender'] = gender;
          }
        }
        
        characters[id] = data;
      } catch (e) {
        print('Error parsing character line: $e');
      }
    }

    return characters;
  }

  // 从infobox中解析中文名
  String parseNameCnFromInfobox(String infobox) {
    try {
      // 简单的infobox解析逻辑，基于wiki-parser-go的实现
      if (infobox.startsWith('{{Infobox')) {
        final lines = infobox.split('\n');
        for (final line in lines) {
          final trimmedLine = line.trim();
          if (trimmedLine.startsWith('|')) {
            final parts = trimmedLine.substring(1).split('=');
            if (parts.length >= 2) {
              final key = parts[0].trim();
              final value = parts.sublist(1).join('=').trim();
              
              // 常见的中文名字段
              if (key == '中文名' || key == '简体中文名' || key == '姓名' || 
                  key == '名称' || key == '名字' || key == '本名') {
                // 清理值中的wiki标记
                return value
                  .replaceAll('[[', '')
                  .replaceAll(']]', '')
                  .replaceAll('{{', '')
                  .replaceAll('}}', '')
                  .trim();
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error parsing infobox for name: $e');
    }
    return '';
  }

  // 从infobox中解析性别
  String parseGenderFromInfobox(String infobox) {
    try {
      if (infobox.startsWith('{{Infobox')) {
        final lines = infobox.split('\n');
        for (final line in lines) {
          final trimmedLine = line.trim();
          if (trimmedLine.startsWith('|')) {
            final parts = trimmedLine.substring(1).split('=');
            if (parts.length >= 2) {
              final key = parts[0].trim();
              final value = parts.sublist(1).join('=').trim();
              
              // 常见的性别字段
              if (key == '性别' || key == '性別' || key == 'gender' || 
                  key == '性別' || key == '性別') {
                final genderValue = value
                  .replaceAll('[[', '')
                  .replaceAll(']]', '')
                  .replaceAll('{{', '')
                  .replaceAll('}}', '')
                  .trim()
                  .toLowerCase();
                
                if (genderValue.contains('男') || genderValue == 'male') {
                  return '男';
                } else if (genderValue.contains('女') || genderValue == 'female') {
                  return '女';
                } else {
                  return '其它';
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error parsing infobox for gender: $e');
    }
    return '';
  }

  // 解析subject.jsonlines文件 - 增强版，支持正确的字段提取
  Map<int, Map<String, dynamic>> parseSubjectJsonlines(String filePath) {
    final file = File(filePath);
    final lines = file.readAsLinesSync();
    final Map<int, Map<String, dynamic>> subjects = {};

    for (final line in lines) {
      try {
        final data = json.decode(line) as Map<String, dynamic>;
        final id = data['id'] as int;
        
        // 正确提取评分信息
        final ratingData = data['rating'];
        double rating = 0.0;
        if (ratingData is Map<String, dynamic>) {
          // 评分可能在rating对象的score字段中
          final score = ratingData['score'];
          if (score != null) {
            rating = double.tryParse(score.toString()) ?? 0.0;
          }
        } else if (ratingData != null) {
          rating = double.tryParse(ratingData.toString()) ?? 0.0;
        }
        data['rating'] = rating;
        
        // 正确提取年份信息
        final dateData = data['date'];
        int year = 0;
        if (dateData != null) {
          final dateStr = dateData.toString();
          // 尝试从日期字符串中提取年份
          final yearMatch = RegExp(r'(\d{4})').firstMatch(dateStr);
          if (yearMatch != null) {
            year = int.tryParse(yearMatch.group(1)!) ?? 0;
          }
        }
        
        // 如果date字段没有年份，尝试从air_date字段提取
        if (year == 0) {
          final airDateData = data['air_date'];
          if (airDateData != null) {
            final airDateStr = airDateData.toString();
            final airYearMatch = RegExp(r'(\d{4})').firstMatch(airDateStr);
            if (airYearMatch != null) {
              year = int.tryParse(airYearMatch.group(1)!) ?? 0;
            }
          }
        }
        
        data['year'] = year;
        
        subjects[id] = data;
      } catch (e) {
        print('Error parsing subject line: $e');
      }
    }

    return subjects;
  }

  // 处理性别转换 - 增强版，支持从infobox和直接数据中提取
  String parseGender(dynamic genderData) {
    if (genderData == null) return '其它';
    
    // 如果genderData已经是解析后的字符串，直接返回
    if (genderData is String) {
      final genderStr = genderData.toLowerCase();
      if (genderStr.contains('男') || genderStr == 'male') {
        return '男';
      } else if (genderStr.contains('女') || genderStr == 'female') {
        return '女';
      } else {
        return '其它';
      }
    }
    
    // 如果是其他类型，转换为字符串处理
    final genderStr = genderData.toString().toLowerCase();
    if (genderStr.contains('男') || genderStr == 'male') {
      return '男';
    } else if (genderStr.contains('女') || genderStr == 'female') {
      return '女';
    } else {
      return '其它';
    }
  }

  // 解析subject-characters.jsonlines文件
  Map<int, List<Map<String, dynamic>>> parseSubjectCharactersJsonlines(String filePath) {
    final file = File(filePath);
    final lines = file.readAsLinesSync();
    final Map<int, List<Map<String, dynamic>>> characterSubjects = {};

    for (final line in lines) {
      try {
        final data = json.decode(line) as Map<String, dynamic>;
        final characterId = data['character_id'] as int;
        final subjectId = data['subject_id'] as int;
        final type = data['type'] as int;
        final order = data['order'] as int;

        if (!characterSubjects.containsKey(characterId)) {
          characterSubjects[characterId] = [];
        }

        characterSubjects[characterId]!.add({
          'subject_id': subjectId,
          'type': type,
          'order': order,
        });
      } catch (e) {
        print('Error parsing subject-characters line: $e');
      }
    }

    return characterSubjects;
  }

  // 解析id_tags.json文件
  Map<int, List<String>> parseIdTags(String filePath) {
    final file = File(filePath);
    final content = file.readAsStringSync();
    final Map<String, dynamic> data = json.decode(content);
    
    final Map<int, List<String>> idTags = {};
    
    data.forEach((key, value) {
      final id = int.parse(key);
      final tags = List<String>.from(value as List);
      idTags[id] = tags;
    });
    
    return idTags;
  }

  // 提取作品信息（不包括客串角色）- 支持不同的作品类型过滤和额外标签作品
  Map<String, dynamic> extractWorkInfo(
    List<Map<String, dynamic>> characterSubjects,
    Map<int, Map<String, dynamic>> subjects,
    int characterId, {
    List<int> allowedTypes = const [2, 4], // 默认允许番剧(type=2)和游戏(type=4)
    bool includeExtraTagSubjects = false // 是否包含额外标签作品（仅番剧模式时使用）
  }) {
    // 首先过滤掉非主角和配角的角色（基于bangumi.js的逻辑）- 使用type字段
    final mainRoles = characterSubjects.where((role) {
      final roleType = role['type'] as int;
      return roleType == 1 || roleType == 2; // type=1:主角, type=2:配角
    }).toList();

    // 然后排除客串角色（type=3）
    final nonGuestRoles = mainRoles.where((role) => role['type'] != 3).toList();

    // 根据过滤条件筛选作品
    final filteredRoles = nonGuestRoles.where((role) {
      final subjectId = role['subject_id'] as int;
      final subject = subjects[subjectId];
      if (subject == null) return false;
      
      // 获取作品类型
      final subjectType = subject['type'] as int? ?? 0;
      
      if (includeExtraTagSubjects) {
        // 仅番剧模式：包含类型2的作品或者额外标签作品
        return subjectType == 2 || subjectsWithExtraTags.contains(subjectId);
      } else {
        // 包含番剧和游戏模式：根据允许的类型过滤
        return allowedTypes.contains(subjectType);
      }
    }).toList();

    final workIds = filteredRoles.map((role) => role['subject_id'] as int).toList();
    final workNames = <String>[];
    double highestRating = 0.0;
    int latestAppearance = -1;
    int earliestAppearance = -1;

    for (final subjectId in workIds) {
      final subject = subjects[subjectId];
      if (subject != null) {
        // 处理作品名称
        final nameCn = subject['name_cn']?.toString() ?? '';
        final name = subject['name']?.toString() ?? '';
        final workName = nameCn.isNotEmpty ? nameCn : name;
        workNames.add(workName);

        // 处理评分
        final rating = double.tryParse(subject['rating']?.toString() ?? '0') ?? 0.0;
        if (rating > highestRating) {
          highestRating = rating;
        }

        // 处理年份
        final yearStr = subject['year']?.toString() ?? '';
        final year = int.tryParse(yearStr) ?? 0;
        if (year > 0) {
          if (latestAppearance == -1 || year > latestAppearance) {
            latestAppearance = year;
          }
          if (earliestAppearance == -1 || year < earliestAppearance) {
            earliestAppearance = year;
          }
        }
      }
    }

    return {
      'workCount': filteredRoles.length,
      'highestRating': highestRating,
      'latestAppearance': latestAppearance == -1 ? 0 : latestAppearance,
      'earliestAppearance': earliestAppearance == -1 ? 0 : earliestAppearance,
      'workNames': workNames,
    };
  }

  // 提取标签信息 - 基于bangumi.js的getCharacterAppearances逻辑进行改进
  List<String> extractTags(
    Map<String, dynamic> characterData,
    Map<int, List<String>> idTags,
    List<Map<String, dynamic>> characterSubjects,
    Map<int, Map<String, dynamic>> subjects,
    int characterId
  ) {
    // 首先过滤掉非主角和配角的角色（基于bangumi.js的逻辑）- 使用type字段
    final mainRoles = characterSubjects.where((role) {
      final roleType = role['type'] as int;
      return roleType == 1 || roleType == 2; // type=1:主角, type=2:配角
    }).toList();

    // 然后排除客串角色（type=3）
    final nonGuestRoles = mainRoles.where((role) => role['type'] != 3).toList();

    // 定义标签分类和映射系统
    final Map<String, String> sourceTagMap = {
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
    
    final Set<String> sourceTagSet = {'原创', '游戏改', '小说改', '漫画改'};
    final Set<String> regionTagSet = {
      '日本', '欧美', '美国', '中国', '法国', '韩国', '英国', 
      '俄罗斯', '中国香港', '苏联', '捷克', '中国台湾', '马来西亚'
    };

    // 标签计数映射
    final Map<String, int> sourceTagCounts = {};
    final Map<String, int> tagCounts = {};
    final Map<String, int> metaTagCounts = {};
    final Set<String> regionTags = {};
    final Set<String> allMetaTags = {};

    // 1. 从id_tags.json获取补充标签
    final additionalTags = idTags[characterId] ?? [];
    allMetaTags.addAll(additionalTags);

    // 2. 从角色数据中获取CV信息
    final cv = characterData['cv']?.toString() ?? '';
    if (cv.isNotEmpty) {
      allMetaTags.add('CV:$cv');
    }

    // 3. 从作品中提取标签（基于bangumi.js的逻辑）- 只处理主角和配角
    for (final role in nonGuestRoles) {
      final subjectId = role['subject_id'] as int;
      final subject = subjects[subjectId];
      if (subject != null) {
        // 计算权重：主角权重为3，配角权重为1
        final roleType = role['type'] as int;
        final stuffFactor = roleType == 1 ? 3 : 1; // type=1:主角权重3, type=2:配角权重1

        // 处理元标签
        final metaTags = subject['meta_tags'] ?? [];
        if (metaTags is List) {
          for (final tag in metaTags) {
            if (tag is String && tag.isNotEmpty) {
              if (sourceTagSet.contains(tag)) {
                // 源标签跳过，后面单独处理
                continue;
              } else if (regionTagSet.contains(tag)) {
                regionTags.add(tag);
              } else {
                metaTagCounts[tag] = (metaTagCounts[tag] ?? 0) + stuffFactor;
              }
            }
          }
        }

        // 处理普通标签
        final tags = subject['tags'] ?? [];
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

    // 4. 标签排序和选择（基于bangumi.js的逻辑）
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

    // 5. 构建最终标签集合（限制数量，避免过多标签）
    // 只添加一个源标签以避免混淆
    if (sortedSourceTags.isNotEmpty) {
      allMetaTags.add(sortedSourceTags.first.keys.first);
    }

    // 添加元标签（最多5个）
    for (final tagObj in sortedMetaTags) {
      if (allMetaTags.length >= 15) break; // 总标签数限制
      allMetaTags.add(tagObj.keys.first);
    }

    // 添加普通标签（最多5个）
    for (final tagObj in sortedTags) {
      if (allMetaTags.length >= 15) break; // 总标签数限制
      allMetaTags.add(tagObj.keys.first);
    }

    // 添加地区标签
    allMetaTags.addAll(regionTags);

    // 6. 添加导演信息（保留原有逻辑）- 只处理主角和配角
    for (final role in nonGuestRoles) {
      final subjectId = role['subject_id'] as int;
      final subject = subjects[subjectId];
      if (subject != null) {
        final directors = subject['directors'] ?? [];
        if (directors is List) {
          for (final director in directors) {
            final directorName = director['name']?.toString() ?? '';
            if (directorName.isNotEmpty && allMetaTags.length < 20) {
              allMetaTags.add('导演:$directorName');
            }
          }
        }
      }
    }

    return allMetaTags.toList();
  }

  // 主处理函数 - 修改为异步版本
  Future<Map<String, List<CharacterInfo>>> processAllData() async {
    // 使用当前工作目录作为项目根目录
    final projectRoot = Directory.current.path;
    print('项目根目录: $projectRoot');

    // 1. 获取所有可能的角色ID
    final characterImagesPath = path.join(projectRoot, 'lib', 'data', 'character_images.json');
    print('character_images.json路径: $characterImagesPath');
    
    // 检查文件是否存在
    final characterImagesFile = File(characterImagesPath);
    if (!characterImagesFile.existsSync()) {
      throw Exception('文件不存在: $characterImagesPath');
    }
    
    final characterIds = getCharacterIdsFromImages(characterImagesPath);
    print('Found ${characterIds.length} character IDs');

    // 2. 解析所有数据文件
    final characterPath = path.join(projectRoot, 'lib', 'dump', 'character.jsonlines');
    print('character.jsonlines路径: $characterPath');
    final characters = parseCharacterJsonlines(characterPath);
    print('Parsed ${characters.length} characters');

    final subjectCharactersPath = path.join(projectRoot, 'lib', 'dump', 'subject-characters.jsonlines');
    print('subject-characters.jsonlines路径: $subjectCharactersPath');
    final characterSubjects = parseSubjectCharactersJsonlines(subjectCharactersPath);
    print('Parsed subject-character relationships');

    final subjectPath = path.join(projectRoot, 'lib', 'dump', 'subject.jsonlines');
    print('subject.jsonlines路径: $subjectPath');
    final subjects = parseSubjectJsonlines(subjectPath);
    print('Parsed ${subjects.length} subjects');

    final idTagsPath = path.join(projectRoot, 'lib', 'data', 'id_tags.json');
    print('id_tags.json路径: $idTagsPath');
    final idTags = parseIdTags(idTagsPath);
    print('Parsed id_tags');

    // 3. 处理每个角色 - 使用异步处理避免阻塞UI
    final List<CharacterInfo> resultAllTypes = [];
    final List<CharacterInfo> resultAnimeOnly = [];
    int processed = 0;
    int totalCharacters = characterIds.length;
    final startTime = DateTime.now();

    print('开始处理角色数据...');
    print('预计处理 $totalCharacters 个角色');

    for (final characterId in characterIds) {
      // 定期让出控制权，避免阻塞UI
      if (processed % 100 == 0) {
        await Future.delayed(Duration.zero);
      }

      final characterData = characters[characterId];
      if (characterData == null) {
        print('跳过角色ID $characterId - 在character.jsonlines中未找到数据');
        continue;
      }

      final subjectsForCharacter = characterSubjects[characterId] ?? [];

      // 提取作品信息 - 两份不同的过滤条件
      final workInfoAllTypes = extractWorkInfo(subjectsForCharacter, subjects, characterId, allowedTypes: [2, 4]);
      final workInfoAnimeOnly = extractWorkInfo(
        subjectsForCharacter, 
        subjects, 
        characterId, 
        allowedTypes: [2],
        includeExtraTagSubjects: true  // 添加这个参数以包含额外标签作品
      );

      // 提取标签信息（使用相同的标签逻辑）
      final tags = extractTags(characterData, idTags, subjectsForCharacter, subjects, characterId);

      // 创建角色信息
      final name = characterData['name']?.toString() ?? '';
      final nameCn = characterData['name_cn']?.toString() ?? '';
      final gender = parseGender(characterData['gender']);
      final collects = int.tryParse(characterData['collects']?.toString() ?? '0') ?? 0;

      // 创建两份不同的角色信息
      final characterInfoAllTypes = CharacterInfo(
        id: characterId,
        name: name,
        nameCn: nameCn.isNotEmpty ? nameCn : name,
        gender: gender,
        collects: collects,
        workCount: workInfoAllTypes['workCount'] as int,
        highestRating: workInfoAllTypes['highestRating'] as double,
        latestAppearance: workInfoAllTypes['latestAppearance'] as int,
        earliestAppearance: workInfoAllTypes['earliestAppearance'] as int,
        tags: tags,
        workNames: List<String>.from(workInfoAllTypes['workNames'] as List),
      );

      final characterInfoAnimeOnly = CharacterInfo(
        id: characterId,
        name: name,
        nameCn: nameCn.isNotEmpty ? nameCn : name,
        gender: gender,
        collects: collects,
        workCount: workInfoAnimeOnly['workCount'] as int,
        highestRating: workInfoAnimeOnly['highestRating'] as double,
        latestAppearance: workInfoAnimeOnly['latestAppearance'] as int,
        earliestAppearance: workInfoAnimeOnly['earliestAppearance'] as int,
        tags: tags,
        workNames: List<String>.from(workInfoAnimeOnly['workNames'] as List),
      );

      resultAllTypes.add(characterInfoAllTypes);
      resultAnimeOnly.add(characterInfoAnimeOnly);
      processed++;

      // 为每个角色输出详细日志
      final progress = (processed / totalCharacters * 100).toStringAsFixed(1);
      final displayName = nameCn.isNotEmpty ? nameCn : name;
      print('[$processed/$totalCharacters] ($progress%) 角色ID $characterId: $displayName - '
          '性别: $gender, 收藏数: $collects, 作品数(全部): ${workInfoAllTypes['workCount']}, '
          '作品数(番剧): ${workInfoAnimeOnly['workCount']}, '
          '最高评分: ${workInfoAllTypes['highestRating']}, 标签数: ${tags.length}');

      // 每100个角色输出一次进度报告
      if (processed % 100 == 0) {
        final elapsed = DateTime.now().difference(startTime);
        final estimatedTotal = elapsed * totalCharacters ~/ processed;
        final remaining = estimatedTotal - elapsed;
        print('--- 进度报告: 已处理 $processed/$totalCharacters 个角色 '
            '(${elapsed.inMinutes}分${elapsed.inSeconds % 60}秒), '
            '预计剩余时间: ${remaining.inMinutes}分${remaining.inSeconds % 60}秒 ---');
      }
    }

    final endTime = DateTime.now();
    final totalTime = endTime.difference(startTime);
    print('✅ 角色数据处理完成!');
    print('📊 统计信息:');
    print('   - 总处理角色数: ${resultAllTypes.length}');
    print('   - 包含番剧和游戏的角色数: ${resultAllTypes.where((c) => c.workCount > 0).length}');
    print('   - 仅包含番剧的角色数: ${resultAnimeOnly.where((c) => c.workCount > 0).length}');
    print('   - 总耗时: ${totalTime.inMinutes}分${totalTime.inSeconds % 60}秒');
    print('   - 平均处理速度: ${(resultAllTypes.length / totalTime.inSeconds).toStringAsFixed(2)} 角色/秒');

    return {
      'all_types': resultAllTypes,
      'anime_only': resultAnimeOnly,
    };
  }

  // 保存结果到文件 - 修改为保存两份文件
  void saveToFiles(Map<String, List<CharacterInfo>> characterData, String baseOutputPath) {
    final allTypesCharacters = characterData['all_types']!;
    final animeOnlyCharacters = characterData['anime_only']!;
    
    // 保存包含番剧和游戏的文件
    final allTypesPath = baseOutputPath.replaceAll('.json', '_all_types.json');
    saveToFile(allTypesCharacters, allTypesPath);
    
    // 保存仅包含番剧的文件
    final animeOnlyPath = baseOutputPath.replaceAll('.json', '_anime_only.json');
    saveToFile(animeOnlyCharacters, animeOnlyPath);
    
    print('✅ 已生成两份文件:');
    print('   - $allTypesPath (${allTypesCharacters.length} 个角色)');
    print('   - $animeOnlyPath (${animeOnlyCharacters.length} 个角色)');
  }

  // 保留原有的单个文件保存方法
  void saveToFile(List<CharacterInfo> characters, String outputPath) {
    final List<Map<String, dynamic>> jsonData = characters.map((c) => c.toJson()).toList();
    final jsonString = json.encode(jsonData);
    
    final file = File(outputPath);
    file.writeAsStringSync(jsonString);
    print('Saved ${characters.length} characters to $outputPath');
  }
}