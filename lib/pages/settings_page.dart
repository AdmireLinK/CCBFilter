import 'dart:async';
import 'package:flutter/material.dart';
import '../extractors/extractor.dart';
import '../models/character.dart';
import '../utils/logger.dart';

/// 设置页面,提供数据更新功能
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const int _maxLogs = 100;

  final List<String> _logs = [];

  bool isExtracting = false;
  double progress = 0.0;
  String statusMessage = '点击按钮开始更新数据';

  /// 向日志面板写入消息(带时间戳)
  void _appendLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} $message');
      if (_logs.length > _maxLogs) {
        _logs.removeAt(0);
      }
    });
  }

  /// 触发数据提取流程
  Future<void> _startExtraction() async {
    if (isExtracting) return;

    setState(() {
      isExtracting = true;
      progress = 0.0;
      statusMessage = '🚀 开始读取本地数据集...';
      _logs.clear();
    });

    _appendLog('启动数据提取流程');
    Logger.info('用户触发数据提取', tag: 'SettingsPage');

    try {
      _appendLog('📂 正在加载和处理数据文件...');
      final Map<String, List<CharacterInfo>> results =
          await Extractor.processAllData();

      _appendLog('💾 正在写入输出文件...');
      await Extractor.saveToFiles(results);

      final allCount = results['All']?.length ?? 0;
      final animeCount = results['Anime']?.length ?? 0;

      setState(() {
        progress = 1.0;
        statusMessage = '✅ 数据提取完成！';
      });

      _appendLog('✅ 数据提取完成！');
      _appendLog('All.json 角色数: $allCount, Anime.json 角色数: $animeCount');
      Logger.info(
        '数据提取完成: All=$allCount, Anime=$animeCount',
        tag: 'SettingsPage',
      );
    } catch (e, stackTrace) {
      setState(() {
        progress = 1.0;
        statusMessage = '❌ 出现异常,请查看日志';
      });

      final errorMessage = '提取过程中出现异常: $e';
      _appendLog(errorMessage);
      Logger.error(
        errorMessage,
        tag: 'SettingsPage',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      setState(() {
        isExtracting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置'), automaticallyImplyLeading: false),
      body: Column(
        children: [
          _ControlPanel(
            isExtracting: isExtracting,
            progress: progress,
            statusMessage: statusMessage,
            onStart: () => _startExtraction(),
          ),
          Expanded(child: _LogList(logs: _logs)),
        ],
      ),
    );
  }
}

/// 顶部操作面板:负责提示与进度反馈
class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.isExtracting,
    required this.progress,
    required this.statusMessage,
    required this.onStart,
  });

  final bool isExtracting;
  final double progress;
  final String statusMessage;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '数据更新',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(statusMessage, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: isExtracting ? null : onStart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isExtracting ? Colors.grey : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: Text(isExtracting ? '更新中...' : '更新数据'),
              ),
              const SizedBox(width: 16),
              if (isExtracting)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('进度: ${(progress * 100).toStringAsFixed(0)}%'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 底部日志列表,支持状态颜色高亮
class _LogList extends StatelessWidget {
  const _LogList({required this.logs});

  final List<String> logs;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Center(
        child: Text(
          '日志将显示在这里...',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      child: ListView.builder(
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          final isError = log.contains('❌') || log.contains('错误');
          final isSuccess = log.contains('✅');

          Color textColor;
          if (isError) {
            textColor = Colors.red;
          } else if (isSuccess) {
            textColor = Colors.green;
          } else {
            textColor = Colors.black87;
          }

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Text(
              log,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontFamily: 'Monospace',
              ),
            ),
          );
        },
      ),
    );
  }
}
