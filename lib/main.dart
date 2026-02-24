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
      title: '암기빵',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // 식빵과 어울리는 따뜻한 색감 (베이지, 브라운, 오렌지)
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8D6E63), // 부드러운 갈색 (식빵 테두리)
          primary: const Color(0xFF6D4C41),
          secondary: const Color(0xFFFFB74D), // 식빵 노란 빛
          surface: const Color(0xFFFFF8E1), // 연한 베이지 (식빵 속살)
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF8E1),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFF8E1),
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: Color(0xFF5D4037),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      themeMode: ThemeMode.light,
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
        title: const Text('암기빵'),
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
                _updateStats();
              },
              icon: const Icon(Icons.lunch_dining),
              tooltip: '빵빵한 주머니 확인', // 더 귀여운 표현
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
                            Icons.breakfast_dining, // 식빵 모양 아이콘으로 변경
                            size: 100,
                            color: Color(0xFF8D6E63),
                          ),
              
              const SizedBox(height: 10),
              const Text(
                '오늘도 배부르게 먹어보자! 🍞',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5D4037),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              
              if (_selectedDatasetPath != null) ...[
                _buildProgressSection(),
                const SizedBox(height: 30),
              ],
              
              ElevatedButton.icon(
                onPressed: _selectDataset,
                icon: const Icon(Icons.shopping_basket), // 빵 바구니에서 선택
                label: Text(_selectedDatasetPath == null ? '무슨 빵을 먹을까? (데이터셋 선택)' : '다른 빵으로 바꿀래 (데이터셋 변경)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFCC80),
                  foregroundColor: const Color(0xFF5D4037),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
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
                        _updateStats();
                      },
                      icon: const Icon(Icons.restaurant), // 학습 -> 식사 시작
                      label: const Text('빵 먹기'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: const Color(0xFF8D6E63),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
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
                        _updateStats();
                      },
                      icon: const Icon(Icons.flatware), // 테스트 -> 소화 확인
                      label: const Text('소화 확인'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        side: const BorderSide(color: Color(0xFF8D6E63), width: 2),
                        foregroundColor: const Color(0xFF5D4037),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const Text(
                '데이터셋 빵을 선택하고 맛있게 암기해 보세요! 🍞',
                style: TextStyle(color: Color(0xFF8D6E63), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    if (_isStatsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final double progress = _totalCount > 0 ? _masteredCount / _totalCount : 0;
    final String fileName = _selectedDatasetPath!.split('/').last;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE0B2)),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '🍞 $fileName',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(0)}% 소화됨',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE65100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: Colors.white,
            color: const Color(0xFFFFB74D),
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '전체: $_totalCount조각',
                style: const TextStyle(color: Color(0xFF8D6E63), fontSize: 12),
              ),
              Text(
                '소화 완료: $_masteredCount조각',
                style: const TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
