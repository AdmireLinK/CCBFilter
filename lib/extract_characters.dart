// ignore_for_file: avoid_print

import 'dart:io';
import 'extractors/extractor.dart';

Future<void> main() async {
  print('🚀 开始角色数据提取...');
  print('=' * 50);
  
  try {
    // 处理数据 - 现在返回两份数据
    print('📂 正在加载和处理数据文件...');
    print('ℹ️ 将生成两份文件：');
    print('   1. 包含番剧和游戏作品 (type=2,4) -> All.json');
    print('   2. 仅包含番剧作品 (type=2) -> Anime.json');
    final characterData = await Extractor.processAllData();
    
    print('💾 正在保存结果到文件...');
    await Extractor.saveToFiles(characterData);
    
    print('=' * 50);
    print('✅ 数据提取完成!');
    
    // 显示详细的统计信息 - 分别显示两份数据的统计
    final allCharacters = characterData['All']!;
    final animeCharacters = characterData['Anime']!;
    
    print('📊 统计信息 - 包含番剧和游戏 (All.json):');
    print('   - 总角色数: ${allCharacters.length}');
    print('   - 有作品的角色数: ${allCharacters.where((c) => c.workCount > 0).length}');
    
    print('📊 统计信息 - 仅包含番剧 (Anime.json):');
    print('   - 总角色数: ${animeCharacters.length}');
    print('   - 有作品的角色数: ${animeCharacters.where((c) => c.workCount > 0).length}');
    
    // 显示详细的统计信息
    if (allCharacters.isNotEmpty) {
      final maleCount = allCharacters.where((c) => c.gender == '男').length;
      final femaleCount = allCharacters.where((c) => c.gender == '女').length;
      final otherCount = allCharacters.where((c) => c.gender == '其它').length;
      
      final avgWorkCount = allCharacters.map((c) => c.workCount).reduce((a, b) => a + b) / allCharacters.length;
      final maxCollects = allCharacters.map((c) => c.collects).reduce((a, b) => a > b ? a : b);
      final avgCollects = allCharacters.map((c) => c.collects).reduce((a, b) => a + b) / allCharacters.length;
      
      final charactersWithWorks = allCharacters.where((c) => c.workCount > 0).length;
      final charactersWithHighRating = allCharacters.where((c) => c.highestRating >= 8.0).length;
      
      print('\n📈 详细统计信息 (基于包含番剧和游戏的数据):');
      print('   👥 性别分布:');
      print('      - 男性角色: $maleCount (${(maleCount/allCharacters.length*100).toStringAsFixed(1)}%)');
      print('      - 女性角色: $femaleCount (${(femaleCount/allCharacters.length*100).toStringAsFixed(1)}%)');
      print('      - 其他性别: $otherCount (${(otherCount/allCharacters.length*100).toStringAsFixed(1)}%)');
      print('   🎬 作品信息:');
      print('      - 平均作品数: ${avgWorkCount.toStringAsFixed(2)}');
      print('      - 有作品的角色: $charactersWithWorks (${(charactersWithWorks/allCharacters.length*100).toStringAsFixed(1)}%)');
      print('      - 高评分作品角色: $charactersWithHighRating (${(charactersWithHighRating/allCharacters.length*100).toStringAsFixed(1)}%)');
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