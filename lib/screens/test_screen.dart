import 'dart:math';
import 'package:flutter/material.dart';
import '../models/card_item.dart';
import '../services/storage_service.dart';

enum TestDirection { keywordToDescription, descriptionToKeyword }

class TestScreen extends StatefulWidget {
  final String assetPath;
  final List<CardItem>? customCards;

  const TestScreen({
    super.key,
    required this.assetPath,
    this.customCards,
  });

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
    // 오답 보기를 만들기 위해 전체 카드는 항상 필요
    _allCards = await _storageService.loadCards(widget.assetPath);
    if (_allCards.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    if (widget.customCards != null && widget.customCards!.isNotEmpty) {
      // [계획 2.1] 주입된 카드가 있으면 해당 카드들로 테스트 진행
      _testCards = List.from(widget.customCards!);
      _testCards.shuffle(_random);
    } else {
      // 기존 방식: 무작위 추출
      int totalCount = _allCards.length;
      int targetCount = (totalCount * 0.25).floor();
      if (targetCount < 5) targetCount = 5;
      if (targetCount > 10) targetCount = 10;
      targetCount = min(targetCount, totalCount);

      _allCards.shuffle(_random);
      _testCards = _allCards.take(targetCount).toList();
    }

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
    _currentDirection = _random.nextBool()
        ? TestDirection.keywordToDescription
        : TestDirection.descriptionToKeyword;

    int optionsCount = _random.nextInt(3) + 4;

    if (_currentDirection == TestDirection.keywordToDescription) {
      _correctAnswer = currentCard.description;
      List<String> others = _allCards
          .where((c) => c.id != currentCard.id)
          .map((c) => c.description)
          .toList();
      others.shuffle(_random);
      _currentOptions = [_correctAnswer, ...others.take(optionsCount - 1)];
    } else {
      _correctAnswer = currentCard.keyword;
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
    await _storageService.saveProgress(widget.assetPath, updatedAllCards);
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
