import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/card_item.dart';
import '../services/storage_service.dart';
import '../widgets/latex_text.dart';

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
  final List<CardItem> _wrongCards = [];
  int _currentIndex = 0;
  int _score = 0;
  bool _isLoading = true;
  bool _isFinished = false;

  String? _selectedOption;
  bool _isShowingFeedback = false;
  bool _isCorrectAnswer = false;
  String _feedbackEmoji = '';

  static const List<String> _correctEmojis = ['🍞', '🥖', '🥐', '🥯', '🥪'];
  static const List<String> _incorrectEmojis = ['⬛', '🐀', '🐦', '💥', '💦'];
  
  static const Duration _feedbackDuration = Duration(milliseconds: 800);
  static const Duration _shakeDuration = Duration(milliseconds: 400);

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

  Future<void> _handleAnswer(String selectedOption) async {
    if (_isShowingFeedback) return;

    bool isCorrect = selectedOption == _correctAnswer;
    
    setState(() {
      _selectedOption = selectedOption;
      _isCorrectAnswer = isCorrect;
      _isShowingFeedback = true;
      _feedbackEmoji = isCorrect 
          ? _correctEmojis[_random.nextInt(_correctEmojis.length)]
          : _incorrectEmojis[_random.nextInt(_incorrectEmojis.length)];
    });

    if (isCorrect) {
      HapticFeedback.lightImpact();
      _score++;
    } else {
      HapticFeedback.heavyImpact();
      _wrongCards.add(_testCards[_currentIndex]);
    }

    _testCards[_currentIndex].stats.updateResult(isCorrect);

    await Future.delayed(_feedbackDuration);

    if (!mounted) return;

    setState(() {
      _isShowingFeedback = false;
      _selectedOption = null;
      _currentIndex++;
    });
    _generateNextQuestion();
  }

  Future<void> _saveResults() async {
    final Map<String, CardItem> testMap = {for (var c in _testCards) c.id: c};
    final updatedAllCards = _allCards.map((c) => testMap[c.id] ?? c).toList();
    await _storageService.saveProgress(widget.assetPath, updatedAllCards);
  }

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
                              side: BorderSide(color: Colors.red.withValues(alpha: 0.2)),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.close, color: Colors.red),
                              title: LatexText(
                                text: card.keyword, 
                                textAlign: TextAlign.left,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                mathFontSize: 16,
                              ),
                              subtitle: LatexText(
                                text: card.description, 
                                textAlign: TextAlign.left,
                                style: const TextStyle(fontSize: 13),
                                mathFontSize: 14,
                              ),
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
      body: Stack(
        children: [
          Padding(
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
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: LatexText(
                            text: displayValue,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF5D4037),
                                ),
                            mathFontSize: 24,
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
                      children: _currentOptions.map((option) {
                        bool isSelected = option == _selectedOption;
                        bool shouldShake = _isShowingFeedback && isSelected && !_isCorrectAnswer;
                        
                        Color backgroundColor = Colors.white;
                        Color borderColor = const Color(0xFFFFE0B2);
                        Color textColor = const Color(0xFF5D4037);
                        
                        if (_isShowingFeedback) {
                          if (isSelected) {
                            backgroundColor = _isCorrectAnswer ? Colors.green.shade100 : Colors.red.shade100;
                            borderColor = _isCorrectAnswer ? Colors.green : Colors.red;
                            textColor = _isCorrectAnswer ? Colors.green.shade900 : Colors.red.shade900;
                          } else if (option == _correctAnswer && !_isCorrectAnswer) {
                            backgroundColor = Colors.green.shade50;
                            borderColor = Colors.green.shade300;
                            textColor = Colors.green.shade900;
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: ShakeWidget(
                            shouldShake: shouldShake,
                            duration: _shakeDuration,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                backgroundColor: backgroundColor,
                                foregroundColor: textColor,
                                elevation: _isShowingFeedback && isSelected ? 4 : 1,
                                side: BorderSide(color: borderColor, width: _isShowingFeedback && isSelected ? 2 : 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () => _handleAnswer(option),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: LatexText(
                                  text: option,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 16),
                                  mathFontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isShowingFeedback)
            Positioned.fill(
              child: Center(
                child: IgnorePointer(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: _shakeDuration,
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Opacity(
                          opacity: value.clamp(0.0, 1.0),
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                )
                              ],
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _feedbackEmoji,
                                style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.25),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ShakeWidget extends StatefulWidget {
  final Widget child;
  final bool shouldShake;
  final Duration duration;

  const ShakeWidget({
    super.key, 
    required this.child, 
    required this.shouldShake,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(ShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldShake && !oldWidget.shouldShake) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
