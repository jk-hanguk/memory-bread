import 'dart:math';
import 'package:flutter/material.dart';
import '../models/card_item.dart';
import '../services/storage_service.dart';
import '../widgets/flash_card.dart';
import 'test_screen.dart';

class LearningScreen extends StatefulWidget {
  final String assetPath;
  const LearningScreen({super.key, required this.assetPath});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  final StorageService _storageService = StorageService();
  List<CardItem> _learningCards = [];
  List<bool> _isFlippedList = []; // 각 카드가 뒤집혔는지(설명->키워드) 여부
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _allMastered = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
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
    setState(() {
      if (_currentIndex < _learningCards.length - 1) {
        _currentIndex++;
      }
    });
  }

  void _prevCard() {
    setState(() {
      if (_currentIndex > 0) {
        _currentIndex--;
      }
    });
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

    return Scaffold(
      appBar: AppBar(
        title: Text('빵 먹기 (${_currentIndex + 1}/${_learningCards.length})'),
        centerTitle: true,
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
              FlashCard(
                key: ValueKey('${widget.assetPath}_${currentCard.id}_$isFlipped'),
                frontText: frontText,
                backText: backText,
              ),
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentIndex > 0 ? _prevCard : null,
                    icon: const Icon(Icons.arrow_back_ios_rounded),
                    iconSize: 48,
                    color: const Color(0xFF8D6E63),
                  ),
                  const SizedBox(width: 60),
                  IconButton(
                    onPressed: _currentIndex < _learningCards.length - 1 ? _nextCard : null,
                    icon: const Icon(Icons.arrow_forward_ios_rounded),
                    iconSize: 48,
                    color: const Color(0xFF8D6E63),
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
    );
  }
}
