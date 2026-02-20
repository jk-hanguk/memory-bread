import 'package:flutter/material.dart';
import 'screens/learning_screen.dart';
import 'screens/test_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/dataset_browser_screen.dart';
import 'services/storage_service.dart';

void main() {
  runApp(const MemoryBreadApp());
}

class MemoryBreadApp extends StatelessWidget {
  const MemoryBreadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '암기빵 (Memory Bread)',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  String? _selectedDatasetPath;
  int _totalCount = 0;
  int _masteredCount = 0;
  bool _isStatsLoading = false;

  void _selectDataset() async {
    final String? result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const DatasetBrowserScreen()),
    );
    if (result != null) {
      setState(() {
        _selectedDatasetPath = result;
      });
      _updateStats();
    }
  }

  // [계획 2.2] 실시간 통계 갱신 로직
  Future<void> _updateStats() async {
    if (_selectedDatasetPath == null) return;
    
    setState(() => _isStatsLoading = true);
    final cards = await _storageService.loadCards(_selectedDatasetPath!);
    setState(() {
      _totalCount = cards.length;
      _masteredCount = cards.where((c) => c.stats.isMastered).length;
      _isStatsLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('암기빵 (Memory Bread)'),
        centerTitle: true,
        actions: [
          if (_selectedDatasetPath != null)
            IconButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DashboardScreen(assetPath: _selectedDatasetPath!),
                  ),
                );
                _updateStats(); // 대시보드 복귀 후 갱신
              },
              icon: const Icon(Icons.bar_chart),
              tooltip: '상세 통계',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.bakery_dining,
                size: 80,
                color: Colors.deepOrange,
              ),
              const SizedBox(height: 10),
              Text(
                '암기를 도와드릴까요?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 30),
              
              // [계획 2.3] 진행 상황 섹션 UI
              if (_selectedDatasetPath != null) ...[
                _buildProgressSection(),
                const SizedBox(height: 30),
              ],
              
              ElevatedButton.icon(
                onPressed: _selectDataset,
                icon: const Icon(Icons.folder_open),
                label: Text(_selectedDatasetPath == null ? '데이터셋 선택하기' : '데이터셋 변경하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _selectedDatasetPath == null ? null : () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LearningScreen(assetPath: _selectedDatasetPath!),
                          ),
                        );
                        _updateStats(); // 학습 후 복귀 시 갱신
                      },
                      icon: const Icon(Icons.school),
                      label: const Text('학습 시작'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectedDatasetPath == null ? null : () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TestScreen(assetPath: _selectedDatasetPath!),
                          ),
                        );
                        _updateStats(); // 테스트 후 복귀 시 갱신
                      },
                      icon: const Icon(Icons.quiz),
                      label: const Text('테스트 시작'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const Text('학습할 데이터셋을 선택하고 암기를 시작하세요! 🍞'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    if (_isStatsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final double progress = _totalCount > 0 ? _masteredCount / _totalCount : 0;
    final String fileName = _selectedDatasetPath!.split('/').last;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  fileName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '전체: $_totalCount개',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '마스터: $_masteredCount개',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
