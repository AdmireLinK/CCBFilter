import 'package:flutter/material.dart';
import 'utils/logger.dart';
import 'pages/main_layout.dart';

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
      ),
      debugShowCheckedModeBanner: false,
      home: const MainLayout(),
    );
  }
}
