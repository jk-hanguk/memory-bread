import 'dart:math';
import 'package:flutter/material.dart';
import '../models/card_item.dart';
import '../services/storage_service.dart';

enum TestDirection { keywordToDescription, descriptionToKeyword }

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
  late TestDirection _currentDirection;

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

    // [계획 2.1] 동적 문항 수 산출: 전체의 약 25%를 테스트 (5~10개 사이)
    int totalCount = _allCards.length;
    int targetCount = (totalCount * 0.25).floor();
    if (targetCount < 5) targetCount = 5;
    if (targetCount > 10) targetCount = 10;
    targetCount = min(targetCount, totalCount);

    _allCards.shuffle(_random);
    _testCards = _allCards.take(targetCount).toList();

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

    // [계획 2.2] 양방향 테스트: 질문 방향 무작위 결정
    _currentDirection = _random.nextBool()
        ? TestDirection.keywordToDescription
        : TestDirection.descriptionToKeyword;

    // [계획 2.3] 선택지 개수 랜덤화: 4~6개 사이의 랜덤한 선택지 제공
    int optionsCount = _random.nextInt(3) + 4; // 4, 5, 6 중 하나

    if (_currentDirection == TestDirection.keywordToDescription) {
      _correctAnswer = currentCard.description;
      // 다른 카드들의 설명들 중에서 오답 추출
      List<String> others = _allCards
          .where((c) => c.id != currentCard.id)
          .map((c) => c.description)
          .toList();
      others.shuffle(_random);
      _currentOptions = [_correctAnswer, ...others.take(optionsCount - 1)];
    } else {
      _correctAnswer = currentCard.keyword;
      // 다른 카드들의 키워드들 중에서 오답 추출
      List<String> others = _allCards
          .where((c) => c.id != currentCard.id)
          .map((c) => c.keyword)
          .toList();
      others.shuffle(_random);
      _currentOptions = [_correctAnswer, ...others.take(optionsCount - 1)];
    }

    _currentOptions.shuffle(_random);
  }

  void _handleAnswer(String selectedOption) {
    bool isCorrect = selectedOption == _correctAnswer;
    if (isCorrect) _score++;

    _testCards[_currentIndex].stats.updateResult(isCorrect);

    setState(() {
      _currentIndex++;
    });
    _generateNextQuestion();
  }

  Future<void> _saveResults() async {
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
    final String questionText = _currentDirection == TestDirection.keywordToDescription
        ? '이 키워드의 설명은 무엇인가요?'
        : '이 설명이 나타내는 키워드는 무엇인가요?';
    final String displayValue = _currentDirection == TestDirection.keywordToDescription
        ? currentCard.keyword
        : currentCard.description;

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
            LinearProgressIndicator(
              value: _currentIndex / _testCards.length,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 20),
            Text(
              questionText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      displayValue,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 선택지가 많아질 수 있으므로 스크롤 가능하게 처리
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _currentOptions.map((option) => Padding(
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
                  )).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
