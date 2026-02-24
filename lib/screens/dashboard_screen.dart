import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/card_item.dart';
import '../services/storage_service.dart';
import '../services/bakery_service.dart';

class DashboardScreen extends StatefulWidget {
  final String assetPath;
  const DashboardScreen({super.key, required this.assetPath});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final StorageService _storageService = StorageService();
  final BakeryService _bakeryService = BakeryService();
  List<CardItem> _cards = [];
  String _displayName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cards = await _storageService.loadCards(widget.assetPath);
    
    String name;
    if (widget.assetPath.startsWith('bakery://')) {
      final id = widget.assetPath.replaceFirst('bakery://', '');
      name = await _bakeryService.getBreadName(id);
    } else {
      name = widget.assetPath.split('/').last;
    }

    setState(() {
      _cards = cards;
      _displayName = name;
      _isLoading = false;
    });
  }

  void _exportData() {
    final Map<String, dynamic> progressMap = {};
    for (var card in _cards) {
      progressMap[card.id] = card.toProgressJson();
    }
    final String jsonString = json.encode(progressMap);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('주머니 백업'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('데이터셋: $_displayName'),
            const SizedBox(height: 10),
            const SelectableText('아래 내용을 복사하여 보관하세요:'),
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              padding: const EdgeInsets.all(8),
              color: Colors.grey[200],
              child: SingleChildScrollView(child: SelectableText(jsonString)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final int total = _cards.length;
    final int mastered = _cards.where((c) => c.stats.isMastered).length;
    final int inProgress = _cards.where((c) => c.stats.totalAttempts > 0 && !c.stats.isMastered).length;
    final int notStarted = _cards.where((c) => c.stats.totalAttempts == 0).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('빵빵한 주머니'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildStatCard(
              context,
              '오늘의 포만감',
              total > 0 ? '${((mastered / total) * 100).toStringAsFixed(1)}%' : '0%',
              LinearProgressIndicator(
                value: total > 0 ? mastered / total : 0,
                minHeight: 12,
                backgroundColor: Colors.white,
                color: const Color(0xFFFFB74D),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 1.2,
              children: [
                _buildSummaryItem(context, '총 식량', total.toString(), const Color(0xFF5D4037)),
                _buildSummaryItem(context, '완전 소화', mastered.toString(), const Color(0xFF2E7D32)),
                _buildSummaryItem(context, '냠냠 중', inProgress.toString(), const Color(0xFFE65100)),
                _buildSummaryItem(context, '아직 바구니에', notStarted.toString(), Colors.grey),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '분석 중인 빵: $_displayName',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.backup, color: Color(0xFF8D6E63)),
              title: const Text('주머니 내보내기 (JSON)'),
              subtitle: const Text('현재 소화 상태를 텍스트로 보관하세요.'),
              onTap: _exportData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, Widget progress) {
    return Card(
      color: const Color(0xFFFFF3E0),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF5D4037))),
                Text(value, style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE65100),
                )),
              ],
            ),
            const SizedBox(height: 15),
            progress,
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String count, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFFFE0B2))),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF8D6E63), fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(count, style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            )),
          ],
        ),
      ),
    );
  }
}
