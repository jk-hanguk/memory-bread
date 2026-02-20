import 'dart:math';
import 'package:flutter/material.dart';
import '../models/card_item.dart';
import '../services/storage_service.dart';
import '../widgets/flash_card.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  final StorageService _storageService = StorageService();
  List<CardItem> _learningCards = [];
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final allCards = await _storageService.loadCards();

    // 3단계 핵심: 청킹 전략 (5~10개 항목씩 세트 구성)
    // 현재는 단순 무작위 10개 선택으로 구현 (나중에는 마스터 안된 것 우선순위 가능)
    final random = Random();
    allCards.shuffle(random);

    setState(() {
      _learningCards = allCards.take(10).toList();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_learningCards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('학습')),
        body: const Center(child: Text('학습할 카드가 없습니다.')),
      );
    }

    final currentCard = _learningCards[_currentIndex];

    // 양방향 학습 로직 (나중에는 설정으로 변경 가능)
    // 현재는 키워드가 앞면, 설명이 뒷면으로 기본 고정
    final String front = currentCard.keyword;
    final String back = currentCard.description;

    return Scaffold(
      appBar: AppBar(
        title: Text('학습 (${_currentIndex + 1}/${_learningCards.length})'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FlashCard(
              key: ValueKey(currentCard.id), // 인덱스 변경 시 위젯 초기화
              frontText: front,
              backText: back,
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
                  onPressed: _currentIndex < _learningCards.length - 1
                      ? _nextCard
                      : null,
                  icon: const Icon(Icons.arrow_forward_ios),
                  iconSize: 40,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('카드를 터치하면 정답을 확인할 수 있어요! 🍞'),
          ],
        ),
      ),
    );
  }
}
