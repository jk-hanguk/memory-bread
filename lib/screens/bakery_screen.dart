import 'package:flutter/material.dart';
import '../services/bakery_service.dart';
import 'dart:developer' as developer;

class BakeryScreen extends StatefulWidget {
  const BakeryScreen({super.key});

  @override
  State<BakeryScreen> createState() => _BakeryScreenState();
}

class _BakeryScreenState extends State<BakeryScreen> {
  final BakeryService _bakeryService = BakeryService();
  bool _isLoading = true;
  List<dynamic> _corners = [];
  List<String> _purchasedIds = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBakeryData();
  }

  Future<void> _loadBakeryData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. 루트 경로의 콘텐츠(코너들) 가져오기
      final contents = await _bakeryService.fetchContents('');
      
      // 2. 이미 구매한 목록 가져오기
      final purchased = await _bakeryService.getPurchasedBreadIds();

      setState(() {
        _corners = contents.where((c) => c['type'] == 'dir').toList();
        _purchasedIds = purchased;
        _isLoading = false;
      });

      if (_corners.isEmpty) {
        setState(() {
          _errorMessage = '빵집에 진열된 코너가 아직 없습니다.\n(GitHub 저장소 설정을 확인해 주세요)';
        });
      }
    } catch (e) {
      developer.log('Error loading bakery: $e', name: 'BakeryScreen');
      setState(() {
        _isLoading = false;
        _errorMessage = '빵집 문을 여는 데 실패했습니다.\n네트워크 상태를 확인해 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('동네 빵가게 (Bakery)'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildCornerList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadBakeryData,
              child: const Text('다시 방문하기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _corners.length,
      itemBuilder: (context, index) {
        final corner = _corners[index];
        final name = corner['name'];
        final path = corner['path'];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: const Icon(Icons.category),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: const Text('새로운 빵들이 기다리고 있어요!'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CornerDetailScreen(
                    cornerName: name,
                    path: path,
                    purchasedIds: _purchasedIds,
                    onUpdate: _loadBakeryData,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class CornerDetailScreen extends StatefulWidget {
  final String cornerName;
  final String path;
  final List<String> purchasedIds;
  final VoidCallback onUpdate;

  const CornerDetailScreen({
    super.key,
    required this.cornerName,
    required this.path,
    required this.purchasedIds,
    required this.onUpdate,
  });

  @override
  State<CornerDetailScreen> createState() => _CornerDetailScreenState();
}

class _CornerDetailScreenState extends State<CornerDetailScreen> {
  final BakeryService _bakeryService = BakeryService();
  bool _isLoading = true;
  List<dynamic> _breads = [];
  late List<String> _purchasedIds;

  @override
  void initState() {
    super.initState();
    _purchasedIds = List.from(widget.purchasedIds);
    _loadBreads();
  }

  Future<void> _loadBreads() async {
    setState(() => _isLoading = true);
    final contents = await _bakeryService.fetchContents(widget.path);
    setState(() {
      _breads = contents.where((c) => c['type'] == 'file' && c['name'].endsWith('.json')).toList();
      _isLoading = false;
    });
  }

  Future<void> _purchaseBread(dynamic bread) async {
    final breadName = bread['name'];
    final breadId = bread['sha']; // GitHub SHA를 ID로 사용하거나 파일명 사용
    final path = bread['path'];

    setState(() => _isLoading = true);
    final success = await _bakeryService.downloadBread(path, breadId, breadName);
    
    if (success) {
      setState(() {
        _purchasedIds.add(breadId);
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🍞 $breadName 빵을 주머니에 넣었습니다!')),
        );
        widget.onUpdate();
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('빵을 가져오는 데 실패했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.cornerName} 코너'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _breads.length,
              itemBuilder: (context, index) {
                final bread = _breads[index];
                final name = bread['name'];
                final id = bread['sha'];
                final isPurchased = _purchasedIds.contains(id);

                return ListTile(
                  leading: const Icon(Icons.breakfast_dining),
                  title: Text(name),
                  trailing: isPurchased
                      ? const Chip(label: Text('가진 빵'), backgroundColor: Colors.greenAccent)
                      : ElevatedButton(
                          onPressed: () => _purchaseBread(bread),
                          child: const Text('담기'),
                        ),
                );
              },
            ),
    );
  }
}
