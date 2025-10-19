import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'utils/logger.dart';
import 'pages/filter_page.dart';

// 窗口大小常量
// 计算方式：第一行总宽度 = 性别组(145) + 间隔(16) + 第二组(270) + 间隔(16) + 第三组(145) = 592
// 加上外层padding(16×2) = 624
const double kWindowWidth = 875.0;
const double kWindowHeight = 880.0;

/// 桌面端入口应用，提供侧边栏导航、角色筛选与数据更新功能
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logger.setMinLevel(LogLevel.info);

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    await windowManager.ensureInitialized();

    const windowSize = Size(kWindowWidth, kWindowHeight);
    const windowOptions = WindowOptions(
      size: windowSize,
      minimumSize: windowSize,
      maximumSize: windowSize,
      center: true,
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.hidden,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setResizable(false);
      await windowManager.setAsFrameless();
      await windowManager.show();
      await windowManager.focus();
    });
  }

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
      home: const FilterPage(),
    );
  }
}
