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

    // [수정] 동적 학습 문항 수 산출 (전체의 약 20% ~ 25% 수준)
    // 청킹 전략을 고려하여 최소 5개, 최대 15개로 제한
    int totalCount = allCards.length;
    int targetCount = (totalCount * 0.25).floor();
    if (targetCount < 5) targetCount = 5;
    if (targetCount > 15) targetCount = 15;
    targetCount = min(targetCount, totalCount);

    final random = Random();
    
    // 마스터되지 않은 카드만 필터링
    final unmasteredCards = allCards.where((c) => !c.stats.isMastered).toList();
    
    if (unmasteredCards.isEmpty) {
      // 모든 카드를 마스터한 경우 (복습 모드)
      allCards.shuffle(random);
      setState(() {
        _allMastered = true;
        _learningCards = allCards.take(targetCount).toList();
        _isLoading = false;
      });
    } else {
      // 마스터되지 않은 카드 중 동적으로 산출된 개수만큼 무작위 선택
      unmasteredCards.shuffle(random);
      setState(() {
        _allMastered = false;
        _learningCards = unmasteredCards.take(targetCount).toList();
        _isLoading = false;
      });
    }
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
        appBar: AppBar(title: const Text('학습')),
        body: const Center(child: Text('학습할 카드가 없습니다.')),
      );
    }

    final currentCard = _learningCards[_currentIndex];
    final bool isLastCard = _currentIndex == _learningCards.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('학습 (${_currentIndex + 1}/${_learningCards.length})'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_allMastered)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Chip(
                    label: const Text('모든 카드를 마스터했습니다! (복습 모드)'),
                    backgroundColor: Colors.green.withOpacity(0.1),
                    labelStyle: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    '마스터하지 않은 카드 ${_learningCards.length}개를 학습합니다. 🍞',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              FlashCard(
                key: ValueKey('${widget.assetPath}_${currentCard.id}'),
                frontText: currentCard.keyword,
                backText: currentCard.description,
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentIndex > 0 ? _prevCard : null,
                    icon: const Icon(Icons.arrow_back_ios),
                    iconSize: 40,
                  ),
                  const SizedBox(width: 40),
                  IconButton(
                    onPressed: _currentIndex < _learningCards.length - 1 ? _nextCard : null,
                    icon: const Icon(Icons.arrow_forward_ios),
                    iconSize: 40,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              if (isLastCard)
                ElevatedButton.icon(
                  onPressed: _startTestWithCurrentCards,
                  icon: const Icon(Icons.quiz),
                  label: const Text('방금 학습한 내용 테스트하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: _startTestWithCurrentCards,
                  icon: const Icon(Icons.quiz),
                  label: const Text('테스트 바로 시작 (중간 점검)'),
                ),
              const SizedBox(height: 20),
              Text(
                '데이터셋: ${widget.assetPath.split('/').last}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
