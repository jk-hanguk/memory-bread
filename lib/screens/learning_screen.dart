import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/card_item.dart';
import '../services/storage_service.dart';
import '../widgets/flash_card.dart';
import '../widgets/card_gesture_handler.dart';
import 'test_screen.dart';

class LearningScreen extends StatefulWidget {
  final String assetPath;
  const LearningScreen({super.key, required this.assetPath});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  final StorageService _storageService = StorageService();
  final FlashCardController _flashCardController = FlashCardController();
  final FocusNode _focusNode = FocusNode();

  List<CardItem> _learningCards = [];
  List<bool> _isFlippedList = []; // 각 카드가 뒤집혔는지(설명->키워드) 여부
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _allMastered = false;
  bool _isNext = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💡 방향키(←/→)로 이동, Space/Enter로 카드 뒤집기'),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final allCards = await _storageService.loadCards(widget.assetPath);
    if (allCards.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    int totalCount = allCards.length;
    int targetCount = (totalCount * 0.25).floor();
    if (targetCount < 5) targetCount = 5;
    if (targetCount > 15) targetCount = 15;
    targetCount = min(targetCount, totalCount);

    final random = Random();
    final unmasteredCards = allCards.where((c) => !c.stats.isMastered).toList();
    
    List<CardItem> selectedCards;
    if (unmasteredCards.isEmpty) {
      allCards.shuffle(random);
      selectedCards = allCards.take(targetCount).toList();
      setState(() => _allMastered = true);
    } else {
      unmasteredCards.shuffle(random);
      selectedCards = unmasteredCards.take(targetCount).toList();
      setState(() => _allMastered = false);
    }

    // 각 카드마다 50% 확률로 앞뒤를 바꿈
    final flippedList = selectedCards.map((_) => random.nextBool()).toList();

    setState(() {
      _learningCards = selectedCards;
      _isFlippedList = flippedList;
      _isLoading = false;
    });
  }

  void _nextCard() {
    if (_currentIndex < _learningCards.length - 1) {
      setState(() {
        _isNext = true;
        _currentIndex++;
      });
    }
  }

  void _prevCard() {
    if (_currentIndex > 0) {
      setState(() {
        _isNext = false;
        _currentIndex--;
      });
    }
  }

  void _flipCard() {
    _flashCardController.toggle?.call();
  }

  void _startTestWithCurrentCards() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TestScreen(
          assetPath: widget.assetPath,
          customCards: _learningCards,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_learningCards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('빵 먹기')),
        body: const Center(child: Text('먹을 빵이 준비되지 않았어요.')),
      );
    }

    final currentCard = _learningCards[_currentIndex];
    final bool isFlipped = _isFlippedList[_currentIndex];
    final bool isLastCard = _currentIndex == _learningCards.length - 1;

    final String frontText = isFlipped ? currentCard.description : currentCard.keyword;
    final String backText = isFlipped ? currentCard.keyword : currentCard.description;
    final String hintText = isFlipped ? '💡 [맛]을 보고 [빵]을 맞춰보세요' : '💡 [빵]을 보고 [맛]을 떠올려보세요';

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _nextCard();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _prevCard();
          } else if (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.enter) {
            _flipCard();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('빵 먹기 (${_currentIndex + 1}/${_learningCards.length})'),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4.0),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _learningCards.length,
              color: const Color(0xFF8D6E63),
              backgroundColor: const Color(0xFFD7CCC8),
            ),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_allMastered)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Chip(
                      label: const Text('모든 빵을 다 소화했어요! 😋'),
                      backgroundColor: const Color(0xFFC8E6C9),
                      labelStyle: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      '꼭꼭 씹어서 맛있게 먹어보자! 🍞',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Text(
                  hintText,
                  style: TextStyle(color: Colors.brown.withValues(alpha: 0.6), fontSize: 13),
                ),
                const SizedBox(height: 16),
                
                // Navigation Arrows & Card
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CardGestureHandler(
                      onFlip: _flipCard,
                      onNext: _currentIndex < _learningCards.length - 1 ? _nextCard : null,
                      onPrev: _currentIndex > 0 ? _prevCard : null,
                      onSwipeUp: () => debugPrint('Swipe Up: Dummy log (Bookmark)'),
                      onSwipeDown: () => debugPrint('Swipe Down: Dummy log (Incorrect Note)'),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          final bool isIncoming = child.key == ValueKey('${widget.assetPath}_${currentCard.id}_$isFlipped');
                          
                          // _isNext가 true이면 다음으로 넘김 (새 카드는 오른쪽에서, 기존 카드는 왼쪽으로)
                          // _isNext가 false이면 이전으로 넘김 (새 카드는 왼쪽에서, 기존 카드는 오른쪽으로)
                          double beginX = 0.0;
                          if (isIncoming) {
                            beginX = _isNext ? 1.0 : -1.0;
                          } else {
                            beginX = _isNext ? -1.0 : 1.0;
                          }

                          final offsetAnimation = Tween<Offset>(
                            begin: Offset(beginX, 0.0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

                          return SlideTransition(
                            position: offsetAnimation,
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
                          );
                        },
                        child: FlashCard(
                          key: ValueKey('${widget.assetPath}_${currentCard.id}_$isFlipped'),
                          frontText: frontText,
                          backText: backText,
                          controller: _flashCardController,
                        ),
                      ),                    ),
                    Positioned(
                      left: 0,
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _currentIndex > 0 ? _prevCard : null,
                          icon: const Icon(Icons.arrow_back_ios_rounded),
                          iconSize: 32,
                          color: const Color(0xFF8D6E63),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _currentIndex < _learningCards.length - 1 ? _nextCard : null,
                          icon: const Icon(Icons.arrow_forward_ios_rounded),
                          iconSize: 32,
                          color: const Color(0xFF8D6E63),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 50),
                if (isLastCard)
                  ElevatedButton.icon(
                    onPressed: _startTestWithCurrentCards,
                    icon: const Icon(Icons.celebration),
                    label: const Text('꿀꺽! 다 먹었다! (소화 확인)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65100),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _startTestWithCurrentCards,
                    icon: const Icon(Icons.flatware),
                    label: const Text('지금 바로 소화 확인'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      side: const BorderSide(color: Color(0xFF8D6E63)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
