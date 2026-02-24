import 'package:flutter/material.dart';
import 'screens/learning_screen.dart';
import 'screens/test_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/dataset_browser_screen.dart';
import 'screens/bakery_screen.dart';
import 'services/storage_service.dart';
import 'services/bakery_service.dart';

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
  final BakeryService _bakeryService = BakeryService();
  String? _selectedDatasetPath;
  String? _selectedDatasetName;
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
    
    // 이름 결정
    String displayName;
    if (_selectedDatasetPath!.startsWith('bakery://')) {
      final id = _selectedDatasetPath!.replaceFirst('bakery://', '');
      displayName = await _bakeryService.getBreadName(id);
    } else {
      displayName = _selectedDatasetPath!.split('/').last;
    }

    final cards = await _storageService.loadCards(_selectedDatasetPath!);
    setState(() {
      _selectedDatasetName = displayName;
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
              const SizedBox(height: 12),
              
              // 빵가게 버튼 추가
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BakeryScreen()),
                  );
                  // 빵가게에서 돌아오면 데이터셋 목록이 갱신되었을 수 있으므로 필요시 처리
                },
                icon: const Icon(Icons.storefront),
                label: const Text('새로운 빵 사러 가기 (빵가게)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9575CD), // 보라색으로 차별화
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
              ),
              const SizedBox(height: 20),
              
              // 핵심 기능 버튼 (빵 먹기 / 소화 확인) 강조 디자인
              Column(
                children: [
                  _buildMajorActionButton(
                    context: context,
                    title: '빵 먹기 (학습)',
                    subtitle: '꼭꼭 씹어서 머릿속에 저장해요',
                    icon: Icons.restaurant,
                    color: const Color(0xFF8D6E63),
                    onPressed: _selectedDatasetPath == null ? null : () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LearningScreen(assetPath: _selectedDatasetPath!),
                        ),
                      );
                      _updateStats();
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildMajorActionButton(
                    context: context,
                    title: '소화 확인 (테스트)',
                    subtitle: '얼마나 잘 외웠는지 확인해 볼까요?',
                    icon: Icons.flatware,
                    color: const Color(0xFFE65100),
                    isOutlined: true,
                    onPressed: _selectedDatasetPath == null ? null : () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TestScreen(assetPath: _selectedDatasetPath!),
                        ),
                      );
                      _updateStats();
                    },
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

  Widget _buildMajorActionButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    bool isOutlined = false,
  }) {
    final bool isDisabled = onPressed == null;
    
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(24),
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: isOutlined ? Colors.white : color,
            borderRadius: BorderRadius.circular(24),
            border: isOutlined ? Border.all(color: color, width: 3) : null,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isOutlined ? color.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: isOutlined ? color : Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isOutlined ? color : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isOutlined ? color.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: isOutlined ? color : Colors.white.withValues(alpha: 0.5),
                size: 20,
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
    final String displayName = _selectedDatasetName ?? '알 수 없는 빵';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE0B2)),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withValues(alpha: 0.05),
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
                  '🍞 $displayName',
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
