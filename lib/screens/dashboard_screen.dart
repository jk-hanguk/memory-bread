import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/card_item.dart';
import '../services/storage_service.dart';

class DashboardScreen extends StatefulWidget {
  final String assetPath;
  const DashboardScreen({super.key, required this.assetPath});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final StorageService _storageService = StorageService();
  List<CardItem> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cards = await _storageService.loadCards(widget.assetPath);
    setState(() {
      _cards = cards;
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
        title: const Text('데이터 백업'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('데이터셋: ${widget.assetPath.split('/').last}'),
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
        title: const Text('학습 대시보드'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildStatCard(
              context,
              '전체 진행도',
              total > 0 ? '${((mastered / total) * 100).toStringAsFixed(1)}%' : '0%',
              LinearProgressIndicator(
                value: total > 0 ? mastered / total : 0,
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
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
                _buildSummaryItem(context, '전체 항목', total.toString(), Colors.blue),
                _buildSummaryItem(context, '마스터', mastered.toString(), Colors.green),
                _buildSummaryItem(context, '학습 중', inProgress.toString(), Colors.orange),
                _buildSummaryItem(context, '미시작', notStarted.toString(), Colors.grey),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '분석 중인 데이터셋: ${widget.assetPath}',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('데이터 백업 (JSON)'),
              subtitle: const Text('현재 데이터셋의 진행 상황을 내보냅니다.'),
              onTap: _exportData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, Widget progress) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
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
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 5),
            Text(count, style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            )),
          ],
        ),
      ),
    );
  }
}
