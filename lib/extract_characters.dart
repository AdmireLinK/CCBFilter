import 'dart:io';
import 'package:path/path.dart' as path;
import 'data_processor.dart';

Future<void> main() async {
  print('🚀 开始角色数据提取...');
  print('=' * 50);
  
  final processor = DataProcessor();
  
  try {
    // 处理数据
    print('📂 正在加载和处理数据文件...');
    final characters = await processor.processAllData();
    
    // 保存结果
    final projectRoot = Directory.current.path;
    final outputPath = path.join(projectRoot, 'lib', 'data', 'character_info.json');
    print('保存路径: $outputPath');
    
    print('💾 正在保存结果到文件...');
    processor.saveToFile(characters, outputPath);
    
    print('=' * 50);
    print('✅ 数据提取完成!');
    print('📁 结果已保存到: $outputPath');
    print('📊 总角色数: ${characters.length}');
    
    // 显示详细的统计信息
    if (characters.isNotEmpty) {
      final maleCount = characters.where((c) => c.gender == '男').length;
      final femaleCount = characters.where((c) => c.gender == '女').length;
      final otherCount = characters.where((c) => c.gender == '其它').length;
      
      final avgWorkCount = characters.map((c) => c.workCount).reduce((a, b) => a + b) / characters.length;
      final maxCollects = characters.map((c) => c.collects).reduce((a, b) => a > b ? a : b);
      final avgCollects = characters.map((c) => c.collects).reduce((a, b) => a + b) / characters.length;
      
      final charactersWithWorks = characters.where((c) => c.workCount > 0).length;
      final charactersWithHighRating = characters.where((c) => c.highestRating >= 8.0).length;
      
      print('\n📈 详细统计信息:');
      print('   👥 性别分布:');
      print('      - 男性角色: $maleCount (${(maleCount/characters.length*100).toStringAsFixed(1)}%)');
      print('      - 女性角色: $femaleCount (${(femaleCount/characters.length*100).toStringAsFixed(1)}%)');
      print('      - 其他性别: $otherCount (${(otherCount/characters.length*100).toStringAsFixed(1)}%)');
      print('   🎬 作品信息:');
      print('      - 平均作品数: ${avgWorkCount.toStringAsFixed(2)}');
      print('      - 有作品的角色: $charactersWithWorks (${(charactersWithWorks/characters.length*100).toStringAsFixed(1)}%)');
      print('      - 高评分作品角色: $charactersWithHighRating (${(charactersWithHighRating/characters.length*100).toStringAsFixed(1)}%)');
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