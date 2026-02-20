import 'package:flutter/material.dart';
import 'screens/learning_screen.dart';
import 'screens/test_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/dataset_browser_screen.dart';

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
  String? _selectedDatasetPath;

  void _selectDataset() async {
    final String? result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const DatasetBrowserScreen()),
    );
    if (result != null) {
      setState(() {
        _selectedDatasetPath = result;
      });
    }
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
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DashboardScreen(assetPath: _selectedDatasetPath!),
                  ),
                );
              },
              icon: const Icon(Icons.dashboard),
              tooltip: '대시보드',
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bakery_dining,
              size: 100,
              color: Colors.deepOrange,
            ),
            const SizedBox(height: 20),
            Text(
              '암기를 도와드릴까요?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            if (_selectedDatasetPath != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '선택됨: ${_selectedDatasetPath!.split('/').last}',
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
              ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _selectDataset,
              icon: const Icon(Icons.folder_open),
              label: Text(_selectedDatasetPath == null ? '데이터셋 선택하기' : '데이터셋 변경하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _selectedDatasetPath == null ? null : () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LearningScreen(assetPath: _selectedDatasetPath!),
                  ),
                );
              },
              icon: const Icon(Icons.school),
              label: const Text('학습 시작'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _selectedDatasetPath == null ? null : () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TestScreen(assetPath: _selectedDatasetPath!),
                  ),
                );
              },
              icon: const Icon(Icons.quiz),
              label: const Text('테스트 시작'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 40),
            const Text('학습할 데이터셋을 먼저 선택해 주세요! 🍞'),
          ],
        ),
      ),
    );
  }
}
