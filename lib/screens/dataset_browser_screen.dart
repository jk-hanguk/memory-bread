import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/bakery_service.dart';

class DatasetBrowserScreen extends StatelessWidget {
  const DatasetBrowserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DatasetBrowserView();
  }
}

class DatasetBrowserView extends StatefulWidget {
  const DatasetBrowserView({super.key});

  @override
  State<DatasetBrowserView> createState() => _DatasetBrowserViewState();
}

class _DatasetBrowserViewState extends State<DatasetBrowserView> {
  final StorageService _storageService = StorageService();
  final BakeryService _bakeryService = BakeryService();
  List<String> _allDatasetPaths = [];
  String _currentPath = ''; 
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, String> _bakeryNames = {};

  @override
  void initState() {
    super.initState();
    _loadAllDatasets();
  }

  Future<void> _loadAllDatasets() async {
    try {
      final paths = await _storageService.listDatasets();
      
      // Bakery 이름 캐싱
      Map<String, String> bakeryNames = {};
      for (var path in paths) {
        if (path.startsWith('bakery://')) {
          final id = path.replaceFirst('bakery://', '');
          bakeryNames[path] = await _bakeryService.getBreadName(id);
        }
      }

      setState(() {
        _allDatasetPaths = paths;
        _bakeryNames = bakeryNames;
        _isLoading = false;
        if (paths.isEmpty) {
          _errorMessage = '데이터셋 파일을 찾을 수 없습니다.\n빵가게에서 새로운 빵을 가져오거나 pubspec.yaml 설정을 확인해 주세요.';
        } else {
          // 탐색 시작 경로 설정
          if (paths.any((p) => p.startsWith('assets/'))) {
            _currentPath = 'assets/datasets/';
          } else if (paths.any((p) => p.startsWith('bakery://'))) {
            _currentPath = 'bakery://';
          } else {
            _currentPath = '';
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '데이터 목록을 불러오는 중 오류가 발생했습니다: $e';
      });
    }
  }

  Map<String, List<String>> _getCurrentItems() {
    final Set<String> folders = {};
    final List<String> files = [];

    // 최상위 루트인 경우 (assets vs bakery 선택)
    if (_currentPath == '') {
       if (_allDatasetPaths.any((p) => p.startsWith('assets/'))) folders.add('기본 빵꾸러미 (Assets)');
       if (_allDatasetPaths.any((p) => p.startsWith('bakery://'))) folders.add('내가 산 빵 (Bakery)');
       return {'folders': folders.toList()..sort(), 'files': []};
    }

    for (var path in _allDatasetPaths) {
      if (path.startsWith(_currentPath)) {
        String relativePath = path.substring(_currentPath.length);
        List<String> parts = relativePath.split('/');
        
        if (parts.length > 1) {
          folders.add(parts[0]);
        } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
          files.add(path);
        }
      }
    }
    return {'folders': folders.toList()..sort(), 'files': files..sort()};
  }

  void _goBack() {
    if (_currentPath == '') return;
    
    if (_currentPath == 'bakery://' || _currentPath == 'assets/datasets/') {
      setState(() => _currentPath = '');
      return;
    }

    String temp = _currentPath.substring(0, _currentPath.length - 1);
    int lastSlash = temp.lastIndexOf('/');
    setState(() {
      _currentPath = lastSlash == -1 ? '' : _currentPath.substring(0, lastSlash + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    String displayPath = _currentPath;
    if (displayPath == 'assets/datasets/') displayPath = '기본 빵꾸러미/';
    if (displayPath == 'bakery://') displayPath = '내가 산 빵/';

    return Scaffold(
      appBar: AppBar(
        title: const Text('데이터셋 탐색'),
        leading: _currentPath != ''
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack)
            : IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                            });
                            _loadAllDatasets();
                          },
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Text(
                        '위치: ${displayPath == '' ? '홈' : displayPath}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: _buildItemList(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildItemList() {
    final items = _getCurrentItems();
    final folders = items['folders']!;
    final files = items['files']!;

    if (folders.isEmpty && files.isEmpty) {
      return const Center(child: Text('이곳에는 빵이 없습니다.'));
    }

    return ListView(
      children: [
        ...folders.map((folder) => ListTile(
              leading: const Icon(Icons.folder, color: Colors.amber),
              title: Text(folder),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                setState(() {
                  if (_currentPath == '' && folder == '기본 빵꾸러미 (Assets)') {
                    _currentPath = 'assets/datasets/';
                  } else if (_currentPath == '' && folder == '내가 산 빵 (Bakery)') {
                    _currentPath = 'bakery://';
                  } else {
                    _currentPath = '$_currentPath$folder/';
                  }
                });
              },
            )),
        ...files.map((file) {
          final isBakery = file.startsWith('bakery://');
          final displayName = isBakery ? _bakeryNames[file] ?? file : file.split('/').last;
          
          return ListTile(
            leading: Icon(
              isBakery ? Icons.breakfast_dining : Icons.description, 
              color: isBakery ? Colors.orange : Colors.blue
            ),
            title: Text(displayName),
            subtitle: Text(isBakery ? '다운로드된 빵' : file, style: const TextStyle(fontSize: 10)),
            onTap: () {
              Navigator.of(context).pop(file);
            },
          );
        }),
      ],
    );
  }
}
