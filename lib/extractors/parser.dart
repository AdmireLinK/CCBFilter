import '../utils/logger.dart';

/// 负责解析原始 Bangumi 数据并补全关键字段
class Parser {
  static const List<String> _nameKeys = ['中文名', '简体中文名', '姓名', '名称', '名字', '本名'];
  static const List<String> _genderKeys = ['性别', '性別', 'gender'];

  /// 从 infobox 文本中提取中文名
  static String parseNameCnFromInfobox(String infobox) {
    try {
      final candidates = _extractInfoboxPairs(infobox);
      for (final entry in candidates) {
        if (_nameKeys.contains(entry.key)) {
          return _cleanInfoboxValue(entry.value);
        }
      }
    } catch (e) {
      Logger.warning('解析infobox中文名时发生错误', tag: 'Parser', error: e);
    }
    return '';
  }

  /// 从 infobox 文本中提取性别
  static String parseGenderFromInfobox(String infobox) {
    try {
      final candidates = _extractInfoboxPairs(infobox);
      for (final entry in candidates) {
        if (_genderKeys.contains(entry.key)) {
          final genderValue = _cleanInfoboxValue(entry.value).toLowerCase();
          if (genderValue.contains('男') || genderValue == 'male') {
            return '男';
          }
          if (genderValue.contains('女') || genderValue == 'female') {
            return '女';
          }
          return '其它';
        }
      }
    } catch (e) {
      Logger.warning('解析infobox性别时发生错误', tag: 'Parser', error: e);
    }
    return '';
  }

  /// 解析性别字段并统一输出
  static String parseGender(dynamic genderData) {
    if (genderData == null) {
      return '其它';
    }

    final gender = genderData.toString().toLowerCase();
    if (gender.contains('男') || gender == 'male' || gender == '1') {
      return '男';
    }
    if (gender.contains('女') || gender == 'female' || gender == '2') {
      return '女';
    }
    return '其它';
  }

  /// 增强角色数据：利用 infobox 覆盖中文名与性别
  static Map<int, Map<String, dynamic>> parseCharacterData(List<Map<String, dynamic>> characters) {
    final Map<int, Map<String, dynamic>> result = {};

    for (final character in characters) {
      final id = character['id'] as int;

      final infobox = character['infobox']?.toString() ?? '';
      if (infobox.isNotEmpty) {
        final nameCn = parseNameCnFromInfobox(infobox);
        if (nameCn.isNotEmpty) {
          character['name_cn'] = nameCn;
        }

        final gender = parseGenderFromInfobox(infobox);
        if (gender.isNotEmpty) {
          character['gender'] = gender;
        }
      }

      result[id] = character;
    }

    return result;
  }

  /// 将 infobox 文本拆解成键值对，兼容字段换行
  static List<MapEntry<String, String>> _extractInfoboxPairs(String infobox) {
    if (!infobox.startsWith('{{Infobox')) {
      return const [];
    }

    final lines = infobox.split('\n');
    final pairs = <MapEntry<String, String>>[];

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (!trimmedLine.startsWith('|')) {
        continue;
      }

      final parts = trimmedLine.substring(1).split('=');
      if (parts.length < 2) {
        continue;
      }

      final key = parts.first.trim();
      final value = parts.sublist(1).join('=').trim();
      if (key.isEmpty || value.isEmpty) {
        continue;
      }

      pairs.add(MapEntry(key, value));
    }

    return pairs;
  }

  /// 清洗 infobox 文本中携带的 wiki 标记
  static String _cleanInfoboxValue(String rawValue) {
    return rawValue
        .replaceAll('[[', '')
        .replaceAll(']]', '')
        .replaceAll('{{', '')
        .replaceAll('}}', '')
        .trim();
  }
}