import 'dart:math';
import 'package:flutter/material.dart';
import '../models/card_item.dart';
import '../services/storage_service.dart';
import '../widgets/flash_card.dart';

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

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final allCards = await _storageService.loadCards(widget.assetPath);
    
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
              key: ValueKey('${widget.assetPath}_${currentCard.id}'),
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
                  onPressed: _currentIndex < _learningCards.length - 1 ? _nextCard : null,
                  icon: const Icon(Icons.arrow_forward_ios),
                  iconSize: 40,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '데이터셋: ${widget.assetPath.split('/').last}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
