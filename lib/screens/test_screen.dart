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
  final List<CardItem> _wrongCards = []; // 오답 리스트 추가
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
    _allCards = await _storageService.loadCards(widget.assetPath);
    if (_allCards.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    if (widget.customCards != null && widget.customCards!.isNotEmpty) {
      _testCards = List.from(widget.customCards!);
      _testCards.shuffle(_random);
    } else {
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
    if (isCorrect) {
      _score++;
    } else {
      // 오답 시 리스트에 추가
      _wrongCards.add(_testCards[_currentIndex]);
    }

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

  // 점수대별 메시지 및 아이콘 가져오기
  Map<String, dynamic> _getResultInfo() {
    double ratio = _testCards.isEmpty ? 0 : _score / _testCards.length;
    if (ratio >= 1.0) {
      return {'msg': '꺼억~ 완벽히 소화!! 🍞✨', 'icon': Icons.sentiment_very_satisfied, 'color': Colors.green};
    } else if (ratio >= 0.8) {
      return {'msg': '기분 좋은 식사! 😋', 'icon': Icons.sentiment_satisfied_alt, 'color': Colors.lightGreen};
    } else if (ratio >= 0.5) {
      return {'msg': '배가 좀 고픈데~ 꼬르륵.. 🥣', 'icon': Icons.sentiment_neutral, 'color': Colors.orange};
    } else if (ratio >= 0.2) {
      return {'msg': '소화불량~ 배가 아프다! 🤢', 'icon': Icons.sentiment_dissatisfied, 'color': Colors.redAccent};
    } else {
      return {'msg': '응급상황! 배탈! 배탈!! 🚑', 'icon': Icons.sentiment_very_dissatisfied, 'color': Colors.red};
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_testCards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('소화 확인')),
        body: const Center(child: Text('소화시킬 빵이 없어요.')),
      );
    }

    if (_isFinished) {
      final info = _getResultInfo();
      return Scaffold(
        appBar: AppBar(title: const Text('소화 결과'), centerTitle: true),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(info['icon'], size: 100, color: info['color']),
                    const SizedBox(height: 20),
                    Text(
                      info['msg'],
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '소화한 빵: $_score / ${_testCards.length} 조각',
                      style: const TextStyle(fontSize: 18, color: Color(0xFF8D6E63)),
                    ),
                    const SizedBox(height: 30),
                    
                    if (_wrongCards.isNotEmpty) ...[
                      const Divider(height: 40),
                      Row(
                        children: const [
                          Icon(Icons.shopping_basket, color: Colors.brown, size: 20),
                          SizedBox(width: 8),
                          Text(
                            '잘못 먹은 빵들 (오답 노트)',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _wrongCards.length,
                        itemBuilder: (context, index) {
                          final card = _wrongCards[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.red.withOpacity(0.2)),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.close, color: Colors.red),
                              title: Text(card.keyword, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(card.description, style: const TextStyle(fontSize: 13)),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8D6E63),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('또 먹으러 가자~', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      );
    }

    final currentCard = _testCards[_currentIndex];
    final String questionText = _currentDirection == TestDirection.keywordToDescription
        ? '이 빵 조각의 맛은 무엇인가요?'
        : '이 맛이 나는 빵 조각은 무엇인가요?';
    final String displayValue = _currentDirection == TestDirection.keywordToDescription
        ? currentCard.keyword
        : currentCard.description;

    return Scaffold(
      appBar: AppBar(
        title: Text('소화 확인 (${_currentIndex + 1}/${_testCards.length})'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: _currentIndex / _testCards.length,
              minHeight: 12,
              backgroundColor: Colors.white,
              color: const Color(0xFFFFB74D),
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 30),
            Text(
              questionText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFCC80), width: 2),
                    ),
                    child: Text(
                      displayValue,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5D4037),
                          ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _currentOptions.map((option) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF5D4037),
                        elevation: 1,
                        side: const BorderSide(color: Color(0xFFFFE0B2)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
