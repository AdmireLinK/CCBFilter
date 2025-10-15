import 'dart:convert';
import 'dart:io';
import 'logger.dart';

/// JSON / JSONLines 文件处理工具
class JsonProcessor {
  /// 读取普通 JSON 文件
  static dynamic readJsonFile(String filePath) {
    try {
      final file = File(filePath);
      final content = file.readAsStringSync();
      return json.decode(content);
    } catch (e) {
      Logger.error('读取JSON文件失败: $filePath', tag: 'JsonProcessor', error: e);
      return null;
    }
  }

  /// 读取 JSONLines 文件并转为 Map 列表
  static List<Map<String, dynamic>> readJsonLinesFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) {
      Logger.warning('JSONLines文件不存在: $filePath', tag: 'JsonProcessor');
      return const [];
    }

    final lines = file.readAsLinesSync();
    final List<Map<String, dynamic>> data = [];

    for (final line in lines) {
      try {
        final parsed = json.decode(line);
        if (parsed is Map<String, dynamic>) {
          data.add(parsed);
        }
      } catch (e) {
        Logger.warning('解析JSON行时发生错误，文件: $filePath', tag: 'JsonProcessor', error: e);
      }
    }

    return data;
  }

  /// 保存 JSON 数据至磁盘（带缩进，便于人工检查）
  static Future<void> saveJsonFile(String filePath, List<Map<String, dynamic>> data) async {
    try {
      final file = File(filePath);
      final directory = file.parent;

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      await file.writeAsString(JsonEncoder.withIndent('  ').convert(data));
      Logger.info('数据已保存到: ${file.path}', tag: 'JsonProcessor');
    } catch (e) {
      Logger.error('保存JSON文件失败: $filePath', tag: 'JsonProcessor', error: e);
      rethrow;
    }
  }

  /// 从角色图片清单中提取角色ID
  @Deprecated('已弃用：角色ID来源改为 id_tags.json，使用 Extractor 内部逻辑获取')
  static List<int> getCharacterIdsFromImages(String filePath) {
    final data = readJsonFile(filePath);
    if (data is List) {
      return data
          .map<int>((item) => item is Map<String, dynamic> ? item['id'] as int? ?? 0 : 0)
          .where((id) => id > 0)
          .toList();
    }
    return const [];
  }

  /// 解析角色信息文件
  static Map<int, Map<String, dynamic>> parseCharacterJsonlines(String filePath) {
    return _mapJsonLinesById(filePath, 'id');
  }

  /// 解析作品信息文件
  static Map<int, Map<String, dynamic>> parseSubjectJsonlines(String filePath) {
    return _mapJsonLinesById(filePath, 'id');
  }

  /// 解析角色-作品关联文件
  static Map<int, List<Map<String, dynamic>>> parseSubjectCharactersJsonlines(String filePath) {
    return _groupJsonLinesById(filePath, 'character_id');
  }

  /// 解析人物信息文件
  static Map<int, Map<String, dynamic>> parsePersonJsonlines(String filePath) {
    return _mapJsonLinesById(filePath, 'id');
  }

  /// 解析人物-角色关联文件
  static Map<int, List<Map<String, dynamic>>> parsePersonCharactersJsonlines(String filePath) {
    return _groupJsonLinesById(filePath, 'character_id');
  }

  /// 解析作品-人物关联文件
  static Map<int, List<Map<String, dynamic>>> parseSubjectPersonsJsonlines(String filePath) {
    return _groupJsonLinesById(filePath, 'subject_id');
  }

  /// 解析手动补充标签表
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

  /// 将 JSONLines 文件按主键映射成 Map
  static Map<int, Map<String, dynamic>> _mapJsonLinesById(String filePath, String keyName) {
    final data = readJsonLinesFile(filePath);
    final Map<int, Map<String, dynamic>> result = {};

    for (final item in data) {
      final key = item[keyName];
      if (key is int) {
        result[key] = item;
      }
    }

    return result;
  }

  /// 将 JSONLines 文件按主键分组为列表
  static Map<int, List<Map<String, dynamic>>> _groupJsonLinesById(String filePath, String keyName) {
    final data = readJsonLinesFile(filePath);
    final Map<int, List<Map<String, dynamic>>> result = {};

    for (final item in data) {
      final key = item[keyName];
      if (key is int) {
        result.putIfAbsent(key, () => <Map<String, dynamic>>[]).add(item);
      }
    }

    return result;
  }
}