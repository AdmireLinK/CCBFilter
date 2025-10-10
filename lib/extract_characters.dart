import 'dart:io';
import 'package:path/path.dart' as path;
import 'data_processor.dart';

Future<void> main() async {
  print('🚀 开始角色数据提取...');
  print('=' * 50);
  
  final processor = DataProcessor();
  
  try {
    // 处理数据 - 现在返回两份数据
    print('📂 正在加载和处理数据文件...');
    print('ℹ️ 将生成两份文件：');
    print('   1. 包含番剧和游戏作品 (type=2,4)');
    print('   2. 仅包含番剧作品 (type=2)');
    final characterData = await processor.processAllData();
    
    // 保存结果 - 使用新的保存方法
    final projectRoot = Directory.current.path;
    final baseOutputPath = path.join(projectRoot, 'lib', 'data', 'character_info.json');
    print('保存基础路径: $baseOutputPath');
    
    print('💾 正在保存结果到文件...');
    processor.saveToFiles(characterData, baseOutputPath);
    
    print('=' * 50);
    print('✅ 数据提取完成!');
    
    // 显示详细的统计信息 - 分别显示两份数据的统计
    final allTypesCharacters = characterData['all_types']!;
    final animeOnlyCharacters = characterData['anime_only']!;
    
    print('📊 统计信息 - 包含番剧和游戏:');
    print('   - 总角色数: ${allTypesCharacters.length}');
    print('   - 有作品的角色数: ${allTypesCharacters.where((c) => c.workCount > 0).length}');
    
    print('📊 统计信息 - 仅包含番剧:');
    print('   - 总角色数: ${animeOnlyCharacters.length}');
    print('   - 有作品的角色数: ${animeOnlyCharacters.where((c) => c.workCount > 0).length}');
    
    // 显示详细的统计信息
    if (allTypesCharacters.isNotEmpty) {
      final maleCount = allTypesCharacters.where((c) => c.gender == '男').length;
      final femaleCount = allTypesCharacters.where((c) => c.gender == '女').length;
      final otherCount = allTypesCharacters.where((c) => c.gender == '其它').length;
      
      final avgWorkCount = allTypesCharacters.map((c) => c.workCount).reduce((a, b) => a + b) / allTypesCharacters.length;
      final maxCollects = allTypesCharacters.map((c) => c.collects).reduce((a, b) => a > b ? a : b);
      final avgCollects = allTypesCharacters.map((c) => c.collects).reduce((a, b) => a + b) / allTypesCharacters.length;
      
      final charactersWithWorks = allTypesCharacters.where((c) => c.workCount > 0).length;
      final charactersWithHighRating = allTypesCharacters.where((c) => c.highestRating >= 8.0).length;
      
      print('\n📈 详细统计信息 (基于包含番剧和游戏的数据):');
      print('   👥 性别分布:');
      print('      - 男性角色: $maleCount (${(maleCount/allTypesCharacters.length*100).toStringAsFixed(1)}%)');
      print('      - 女性角色: $femaleCount (${(femaleCount/allTypesCharacters.length*100).toStringAsFixed(1)}%)');
      print('      - 其他性别: $otherCount (${(otherCount/allTypesCharacters.length*100).toStringAsFixed(1)}%)');
      print('   🎬 作品信息:');
      print('      - 平均作品数: ${avgWorkCount.toStringAsFixed(2)}');
      print('      - 有作品的角色: $charactersWithWorks (${(charactersWithWorks/allTypesCharacters.length*100).toStringAsFixed(1)}%)');
      print('      - 高评分作品角色: $charactersWithHighRating (${(charactersWithHighRating/allTypesCharacters.length*100).toStringAsFixed(1)}%)');
      print('   ❤️ 收藏信息:');
      print('      - 平均收藏数: ${avgCollects.toStringAsFixed(0)}');
      print('      - 最高收藏数: $maxCollects');
    }
    
  } catch (e) {
    print('=' * 50);
    print('❌ 数据提取过程中出现错误:');
    print('   $e');
    print('=' * 50);
    exit(1);
  }
}

// 专门用于Flutter应用调用的函数
Future<bool> extractData() async {
  try {
    await main();
    return true;
  } catch (e) {
    print('❌ Flutter应用调用失败: $e');
    return false;
  }
}