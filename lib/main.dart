import 'package:flutter/material.dart';
import 'screens/learning_screen.dart';
import 'screens/test_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const MemoryBreadApp());
}

class MemoryBreadApp extends StatelessWidget {
  const MemoryBreadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '암기빵 (Memory Bread)',
      // Material 3 기반의 라이트 테마 설정
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.light,
        ),
      ),
      // 다크 테마 지원
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
      ),
      // 시스템 설정에 따라 테마 모드 변경
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('암기빵 (Memory Bread)'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
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
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LearningScreen()),
                );
              },
              icon: const Icon(Icons.school),
              label: const Text('학습 시작'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const TestScreen()));
              },
              icon: const Icon(Icons.quiz),
              label: const Text('테스트 시작'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 40),
            const Text('학습한 내용을 확인해 보세요! 🍞'),
          ],
        ),
      ),
    );
  }
}
