// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

class JsonProcessor {
  // 从JSON文件读取数据
  static dynamic readJsonFile(String filePath) {
    final file = File(filePath);
    final content = file.readAsStringSync();
    return json.decode(content);
  }

  // 从JSONLINES文件读取数据
  static List<Map<String, dynamic>> readJsonLinesFile(String filePath) {
    final file = File(filePath);
    final lines = file.readAsLinesSync();
    final List<Map<String, dynamic>> data = [];

    for (final line in lines) {
      try {
        final parsed = json.decode(line);
        if (parsed is Map<String, dynamic>) {
          data.add(parsed);
        }
      } catch (e) {
        print('Error parsing JSON line: $e');
      }
    }

    return data;
  }

  // 保存JSON数据到文件
  static Future<void> saveJsonFile(String filePath, List<Map<String, dynamic>> data) async {
    final file = File(filePath);
    final directory = file.parent;
    
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    await file.writeAsString(JsonEncoder.withIndent('  ').convert(data));
    print('Data saved to: ${file.path}');
  }

  // 从character_images.json获取所有可能的角色ID - 修复类型转换
  static List<int> getCharacterIdsFromImages(String filePath) {
    final data = readJsonFile(filePath);
    if (data is List) {
      return data.map<int>((item) {
        if (item is Map<String, dynamic>) {
          return item['id'] as int;
        }
        return 0;
      }).where((id) => id > 0).toList();
    }
    return [];
  }

  // 解析character.jsonlines文件
  static Map<int, Map<String, dynamic>> parseCharacterJsonlines(String filePath) {
    final data = readJsonLinesFile(filePath);
    final Map<int, Map<String, dynamic>> characters = {};

    for (final item in data) {
      final id = item['id'] as int;
      characters[id] = item;
    }

    return characters;
  }

  // 解析subject.jsonlines文件
  static Map<int, Map<String, dynamic>> parseSubjectJsonlines(String filePath) {
    final data = readJsonLinesFile(filePath);
    final Map<int, Map<String, dynamic>> subjects = {};

    for (final item in data) {
      final id = item['id'] as int;
      subjects[id] = item;
    }

    return subjects;
  }

  // 解析subject-characters.jsonlines文件
  static Map<int, List<Map<String, dynamic>>> parseSubjectCharactersJsonlines(String filePath) {
    final data = readJsonLinesFile(filePath);
    final Map<int, List<Map<String, dynamic>>> characterSubjects = {};

    for (final item in data) {
      final characterId = item['character_id'] as int;
      if (!characterSubjects.containsKey(characterId)) {
        characterSubjects[characterId] = [];
      }
      characterSubjects[characterId]!.add(item);
    }

    return characterSubjects;
  }

  // 解析person.jsonlines文件
  static Map<int, Map<String, dynamic>> parsePersonJsonlines(String filePath) {
    final data = readJsonLinesFile(filePath);
    final Map<int, Map<String, dynamic>> persons = {};

    for (final item in data) {
      final id = item['id'] as int;
      persons[id] = item;
    }

    return persons;
  }

  // 解析person-characters.jsonlines文件
  static Map<int, List<Map<String, dynamic>>> parsePersonCharactersJsonlines(String filePath) {
    final data = readJsonLinesFile(filePath);
    final Map<int, List<Map<String, dynamic>>> personCharacters = {};

    for (final item in data) {
      final characterId = item['character_id'] as int;
      if (!personCharacters.containsKey(characterId)) {
        personCharacters[characterId] = [];
      }
      personCharacters[characterId]!.add(item);
    }

    return personCharacters;
  }

  // 解析subject-persons.jsonlines文件
  static Map<int, List<Map<String, dynamic>>> parseSubjectPersonsJsonlines(String filePath) {
    final data = readJsonLinesFile(filePath);
    final Map<int, List<Map<String, dynamic>>> subjectPersons = {};

    for (final item in data) {
      final subjectId = item['subject_id'] as int;
      if (!subjectPersons.containsKey(subjectId)) {
        subjectPersons[subjectId] = [];
      }
      subjectPersons[subjectId]!.add(item);
    }

    return subjectPersons;
  }

  // 解析id_tags.json文件 - 修复类型转换
  static Map<int, List<String>> parseIdTags(String filePath) {
    final data = readJsonFile(filePath);
    final Map<int, List<String>> idTags = {};

    if (data is Map<String, dynamic>) {
      data.forEach((key, value) {
        final id = int.tryParse(key);
        if (id != null && value is List) {
          idTags[id] = value.cast<String>();
        }
      });
    }

    return idTags;
  }
}