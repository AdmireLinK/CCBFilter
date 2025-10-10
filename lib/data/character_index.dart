import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

class CharacterIndex {
  late Map<int, Map<String, dynamic>> _characters;
  late Map<String, List<int>> _nameIndex;
  late Map<String, List<int>> _tagIndex;
  late Map<String, List<int>> _genderIndex;

  CharacterIndex(String filePath) {
    _loadData(filePath);
    _buildIndexes();
  }

  void _loadData(String filePath) {
    final file = File(filePath);
    final content = file.readAsStringSync();
    final List<dynamic> data = json.decode(content);
    
    _characters = {};
    for (final item in data) {
      final id = item['id'] as int;
      _characters[id] = item;
    }
  }

  void _buildIndexes() {
    _nameIndex = {};
    _tagIndex = {};
    _genderIndex = {};
    
    for (final character in _characters.values) {
      final id = character['id'] as int;
      
      // 名称索引
      final name = (character['name'] as String).toLowerCase();
      final nameCn = (character['nameCn'] as String).toLowerCase();
      
      _addToIndex(_nameIndex, name, id);
      if (nameCn.isNotEmpty && nameCn != name) {
        _addToIndex(_nameIndex, nameCn, id);
      }
      
      // 标签索引
      final tags = List<String>.from(character['tags'] as List);
      for (final tag in tags) {
        _addToIndex(_tagIndex, tag.toLowerCase(), id);
      }
      
      // 性别索引
      final gender = character['gender'] as String;
      _addToIndex(_genderIndex, gender, id);
    }
  }
  
  void _addToIndex(Map<String, List<int>> index, String key, int id) {
    if (!index.containsKey(key)) {
      index[key] = [];
    }
    index[key]!.add(id);
  }

  // 根据ID获取角色信息
  Map<String, dynamic>? getCharacterById(int id) {
    return _characters[id];
  }

  // 根据名称搜索角色
  List<Map<String, dynamic>> searchByName(String query) {
    final queryLower = query.toLowerCase();
    final resultIds = <int>{};
    
    for (final name in _nameIndex.keys) {
      if (name.contains(queryLower)) {
        resultIds.addAll(_nameIndex[name]!);
      }
    }
    
    return resultIds.map((id) => _characters[id]!).toList();
  }

  // 根据标签搜索角色
  List<Map<String, dynamic>> searchByTag(String tag) {
    final tagLower = tag.toLowerCase();
    final ids = _tagIndex[tagLower] ?? [];
    return ids.map((id) => _characters[id]!).toList();
  }

  // 根据性别筛选角色
  List<Map<String, dynamic>> filterByGender(String gender) {
    final ids = _genderIndex[gender] ?? [];
    return ids.map((id) => _characters[id]!).toList();
  }

  // 获取所有角色
  List<Map<String, dynamic>> getAllCharacters() {
    return _characters.values.toList();
  }

  // 获取统计信息
  Map<String, dynamic> getStatistics() {
    return {
      'totalCharacters': _characters.length,
      'maleCount': _genderIndex['男']?.length ?? 0,
      'femaleCount': _genderIndex['女']?.length ?? 0,
      'otherGenderCount': _genderIndex['其它']?.length ?? 0,
      'uniqueTags': _tagIndex.keys.length,
    };
  }
}