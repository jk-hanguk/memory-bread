import 'dart:math';
import 'package:flutter/material.dart';
import '../models/card_item.dart';
import '../services/storage_service.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final StorageService _storageService = StorageService();
  final Random _random = Random();

  List<CardItem> _allCards = [];
  List<CardItem> _testCards = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _isLoading = true;
  bool _isFinished = false;

  late List<String> _currentOptions;
  late String _correctAnswer;

  @override
  void initState() {
    super.initState();
    _loadTestData();
  }

  Future<void> _loadTestData() async {
    _allCards = await _storageService.loadCards();
    if (_allCards.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    // 테스트용 10개 항목 무작위 선택
    _allCards.shuffle(_random);
    _testCards = _allCards.take(min(10, _allCards.length)).toList();

    _generateNextQuestion();
    setState(() => _isLoading = false);
  }

  void _generateNextQuestion() {
    if (_currentIndex >= _testCards.length) {
      setState(() => _isFinished = true);
      _saveResults();
      return;
    }

    final currentCard = _testCards[_currentIndex];
    _correctAnswer = currentCard.description;

    // 오답 생성 (다른 카드의 설명을 사용)
    List<String> otherDescriptions = _allCards
        .where((c) => c.id != currentCard.id)
        .map((c) => c.description)
        .toList();
    otherDescriptions.shuffle(_random);

    List<String> options = [_correctAnswer, ...otherDescriptions.take(3)];
    options.shuffle(_random);

    setState(() {
      _currentOptions = options;
    });
  }

  void _handleAnswer(String selectedOption) {
    bool isCorrect = selectedOption == _correctAnswer;
    if (isCorrect) _score++;

    // 개별 카드의 통계 업데이트
    _testCards[_currentIndex].stats.updateResult(isCorrect);

    setState(() {
      _currentIndex++;
    });
    _generateNextQuestion();
  }

  Future<void> _saveResults() async {
    // 업데이트된 카드들의 상태를 반영하여 전체 리스트를 저장
    final Map<String, CardItem> testMap = {for (var c in _testCards) c.id: c};
    final updatedAllCards = _allCards.map((c) => testMap[c.id] ?? c).toList();

    await _storageService.saveProgress(updatedAllCards);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_testCards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('테스트')),
        body: const Center(child: Text('테스트할 데이터가 없습니다.')),
      );
    }

    if (_isFinished) {
      return Scaffold(
        appBar: AppBar(title: const Text('테스트 결과')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
              const SizedBox(height: 20),
              Text(
                '수고하셨습니다!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                '점수: $_score / ${_testCards.length}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('메인으로 돌아가기'),
              ),
            ],
          ),
        ),
      );
    }

    final currentCard = _testCards[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('테스트 (${_currentIndex + 1}/${_testCards.length})'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LinearProgressIndicator(
              value: 0.0, // TODO: 진행 상태 바 구현 가능
            ),
            const Spacer(),
            Text(
              '이 키워드의 설명은 무엇인가요?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                currentCard.keyword,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const Spacer(),
            ..._currentOptions.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _handleAnswer(option),
                  child: Text(
                    option,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
