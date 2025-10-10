import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'extract_characters.dart' as extractor;

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  List<String> logs = [];
  bool isExtracting = false;
  double progress = 0.0;

  void _addLog(String message) {
    setState(() {
      logs.add('${DateTime.now().toString().substring(11, 19)} $message');
      // 只保留最近的100条日志
      if (logs.length > 100) {
        logs.removeAt(0);
      }
    });
  }

  void _startExtraction() {
    if (isExtracting) return;
    
    setState(() {
      isExtracting = true;
      logs.clear();
      progress = 0.0;
    });

    _addLog('开始数据提取...');

    // 在后台线程中运行数据提取
    Future.delayed(Duration.zero, () async {
      try {
        // 运行提取过程
        final success = await extractor.extractData();
        
        if (success) {
          _addLog('✅ 数据提取完成！');
        } else {
          _addLog('❌ 数据提取失败');
        }
        
        setState(() {
          isExtracting = false;
          progress = 1.0;
        });
        
      } catch (e) {
        _addLog('❌ 错误: $e');
        setState(() {
          isExtracting = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('角色数据提取工具'),
        ),
        body: Column(
          children: [
            // 控制面板
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                children: [
                  const Text(
                    'CCBFilter 角色数据提取',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '点击下方按钮开始提取角色数据',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: isExtracting ? null : _startExtraction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isExtracting ? Colors.grey : Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: Text(
                      isExtracting ? '提取中...' : '开始提取数据',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  if (isExtracting) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '进度: ${(progress * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
            
            // 日志显示区域
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: logs.isEmpty
                    ? const Center(
                        child: Text(
                          '日志将显示在这里...',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          final isError = log.contains('❌') || log.contains('错误');
                          final isSuccess = log.contains('✅');
                          
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey[300]!),
                              ),
                            ),
                            child: Text(
                              log,
                              style: TextStyle(
                                fontSize: 12,
                                color: isError 
                                    ? Colors.red 
                                    : isSuccess 
                                      ? Colors.green 
                                      : Colors.black87,
                                fontFamily: 'Monospace',
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}