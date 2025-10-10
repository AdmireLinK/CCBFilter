import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

// 角色信息结构体
class CharacterInfo {
  final int id;
  final String name;
  final String nameCn;
  final String gender;
  final int collects;
  final int workCount;
  final double highestRating;
  final int latestYear;
  final int earliestYear;
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
    required this.latestYear,
    required this.earliestYear,
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
      'latestYear': latestYear,
      'earliestYear': earliestYear,
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

  // 解析character.jsonlines文件
  Map<int, Map<String, dynamic>> parseCharacterJsonlines(String filePath) {
    final file = File(filePath);
    final lines = file.readAsLinesSync();
    final Map<int, Map<String, dynamic>> characters = {};

    for (final line in lines) {
      try {
        final data = json.decode(line) as Map<String, dynamic>;
        final id = data['id'] as int;
        characters[id] = data;
      } catch (e) {
        print('Error parsing character line: $e');
      }
    }

    return characters;
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

        if (!characterSubjects.containsKey(characterId)) {
          characterSubjects[characterId] = [];
        }

        characterSubjects[characterId]!.add({
          'subject_id': subjectId,
          'type': type,
        });
      } catch (e) {
        print('Error parsing subject-characters line: $e');
      }
    }

    return characterSubjects;
  }

  // 解析subject.jsonlines文件
  Map<int, Map<String, dynamic>> parseSubjectJsonlines(String filePath) {
    final file = File(filePath);
    final lines = file.readAsLinesSync();
    final Map<int, Map<String, dynamic>> subjects = {};

    for (final line in lines) {
      try {
        final data = json.decode(line) as Map<String, dynamic>;
        final id = data['id'] as int;
        subjects[id] = data;
      } catch (e) {
        print('Error parsing subject line: $e');
      }
    }

    return subjects;
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

  // 处理性别转换
  String parseGender(dynamic genderData) {
    if (genderData == null) return '其它';
    
    final genderStr = genderData.toString().toLowerCase();
    if (genderStr.contains('男') || genderStr == 'male') {
      return '男';
    } else if (genderStr.contains('女') || genderStr == 'female') {
      return '女';
    } else {
      return '其它';
    }
  }

  // 提取作品信息（不包括客串角色）
  Map<String, dynamic> extractWorkInfo(
    List<Map<String, dynamic>> characterSubjects,
    Map<int, Map<String, dynamic>> subjects,
    int characterId
  ) {
    final nonGuestRoles = characterSubjects
        .where((role) => role['type'] != 3) // 排除客串角色
        .toList();

    final workIds = nonGuestRoles.map((role) => role['subject_id'] as int).toList();
    final workNames = <String>[];
    double highestRating = 0.0;
    int latestYear = -1;
    int earliestYear = -1;

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
          if (latestYear == -1 || year > latestYear) {
            latestYear = year;
          }
          if (earliestYear == -1 || year < earliestYear) {
            earliestYear = year;
          }
        }
      }
    }

    return {
      'workCount': nonGuestRoles.length,
      'highestRating': highestRating,
      'latestYear': latestYear == -1 ? 0 : latestYear,
      'earliestYear': earliestYear == -1 ? 0 : earliestYear,
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

    // 3. 从作品中提取标签（基于bangumi.js的逻辑）
    for (final role in characterSubjects) {
      final subjectId = role['subject_id'] as int;
      final subject = subjects[subjectId];
      if (subject != null) {
        // 计算权重：主角权重为3，配角权重为1
        final roleType = role['staff']?.toString() ?? '';
        final stuffFactor = roleType == '主角' ? 3 : 1;

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

    // 6. 添加导演信息（保留原有逻辑）
    for (final role in characterSubjects) {
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
  Future<List<CharacterInfo>> processAllData() async {
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
    final List<CharacterInfo> result = [];
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

      // 提取作品信息（不包括客串）
      final workInfo = extractWorkInfo(subjectsForCharacter, subjects, characterId);

      // 提取标签信息
      final tags = extractTags(characterData, idTags, subjectsForCharacter, subjects, characterId);

      // 创建角色信息
      final name = characterData['name']?.toString() ?? '';
      final nameCn = characterData['name_cn']?.toString() ?? '';
      final gender = parseGender(characterData['gender']);
      final collects = int.tryParse(characterData['collects']?.toString() ?? '0') ?? 0;

      final characterInfo = CharacterInfo(
        id: characterId,
        name: name,
        nameCn: nameCn.isNotEmpty ? nameCn : name,
        gender: gender,
        collects: collects,
        workCount: workInfo['workCount'] as int,
        highestRating: workInfo['highestRating'] as double,
        latestYear: workInfo['latestYear'] as int,
        earliestYear: workInfo['earliestYear'] as int,
        tags: tags,
        workNames: List<String>.from(workInfo['workNames'] as List),
      );

      result.add(characterInfo);
      processed++;

      // 为每个角色输出详细日志
      final progress = (processed / totalCharacters * 100).toStringAsFixed(1);
      final displayName = nameCn.isNotEmpty ? nameCn : name;
      print('[$processed/$totalCharacters] ($progress%) 角色ID $characterId: $displayName - '
          '性别: $gender, 收藏数: $collects, 作品数: ${workInfo['workCount']}, '
          '最高评分: ${workInfo['highestRating']}, 标签数: ${tags.length}');

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
    print('   - 总处理角色数: ${result.length}');
    print('   - 总耗时: ${totalTime.inMinutes}分${totalTime.inSeconds % 60}秒');
    print('   - 平均处理速度: ${(result.length / totalTime.inSeconds).toStringAsFixed(2)} 角色/秒');

    return result;
  }

  // 保存结果到文件
  void saveToFile(List<CharacterInfo> characters, String outputPath) {
    final List<Map<String, dynamic>> jsonData = characters.map((c) => c.toJson()).toList();
    final jsonString = json.encode(jsonData);
    
    final file = File(outputPath);
    file.writeAsStringSync(jsonString);
    print('Saved ${characters.length} characters to $outputPath');
  }
}