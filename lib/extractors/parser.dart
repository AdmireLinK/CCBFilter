class Parser {
  // 从infobox中解析中文名
  static String parseNameCnFromInfobox(String infobox) {
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
  static String parseGenderFromInfobox(String infobox) {
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

  // 解析性别字段
  static String parseGender(dynamic genderData) {
    if (genderData == null) return '其它';
    
    final gender = genderData.toString().toLowerCase();
    if (gender.contains('男') || gender == 'male' || gender == '1') {
      return '男';
    } else if (gender.contains('女') || gender == 'female' || gender == '2') {
      return '女';
    } else {
      return '其它';
    }
  }

  // 解析角色数据，增强infobox处理
  static Map<int, Map<String, dynamic>> parseCharacterData(List<Map<String, dynamic>> characters) {
    final Map<int, Map<String, dynamic>> result = {};

    for (final character in characters) {
      final id = character['id'] as int;
      
      // 解析infobox获取中文名和性别
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
}