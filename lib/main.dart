import 'package:flutter/material.dart';
import 'utils/logger.dart';
import 'pages/filter_layout.dart';

// 窗口大小常量
// 计算方式：第一行总宽度 = 性别组(145) + 间隔(16) + 第二组(270) + 间隔(16) + 第三组(145) = 592
// 加上外层padding(16×2) = 624
const double kWindowWidth = 624.0;
const double kWindowHeight = 900.0;

/// 桌面端入口应用，提供侧边栏导航、角色筛选与数据更新功能
void main() {
  Logger.setMinLevel(LogLevel.info);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CCBFilter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'HarmonyOS_Sans_SC',
      ),
      debugShowCheckedModeBanner: false,
      home: const FilterLayout(),
    );
  }
}
