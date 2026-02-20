import 'package:flutter/material.dart';
import '../services/storage_service.dart';

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
  List<String> _allDatasetPaths = [];
  String _currentPath = ''; // 공통 접두사를 찾기 위해 비워둠
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAllDatasets();
  }

  Future<void> _loadAllDatasets() async {
    try {
      final paths = await _storageService.listDatasets();
      setState(() {
        _allDatasetPaths = paths;
        _isLoading = false;
        if (paths.isEmpty) {
          _errorMessage = '데이터셋 파일을 찾을 수 없습니다.\npubspec.yaml 설정을 다시 확인해 주세요.';
        } else {
          // 탐색 시작 경로 설정 (모든 경로의 공통 시작 부분 찾기)
          // 보통 'assets/datasets/' 임
          if (paths.isNotEmpty) {
            String firstPath = paths.first;
            int idx = firstPath.indexOf('datasets/');
            if (idx != -1) {
              _currentPath = firstPath.substring(0, idx + 9);
            } else {
              _currentPath = firstPath.substring(0, firstPath.lastIndexOf('/') + 1);
            }
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
    // datasets/ 최상위보다 더 뒤로 갈 수 없도록 제한
    if (!_currentPath.contains('datasets/') || _currentPath.endsWith('datasets/')) return;
    
    String temp = _currentPath.substring(0, _currentPath.length - 1);
    int lastSlash = temp.lastIndexOf('/');
    setState(() {
      _currentPath = _currentPath.substring(0, lastSlash + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('데이터셋 탐색'),
        leading: _currentPath.contains('datasets/') && !_currentPath.endsWith('datasets/')
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
                        '경로: $_currentPath',
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
      return const Center(child: Text('이 폴더에는 데이터셋이 없습니다.'));
    }

    return ListView(
      children: [
        ...folders.map((folder) => ListTile(
              leading: const Icon(Icons.folder, color: Colors.amber),
              title: Text(folder),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                setState(() {
                  _currentPath = '$_currentPath$folder/';
                });
              },
            )),
        ...files.map((file) {
          final fileName = file.split('/').last;
          return ListTile(
            leading: const Icon(Icons.description, color: Colors.blue),
            title: Text(fileName),
            subtitle: Text(file, style: const TextStyle(fontSize: 10)),
            onTap: () {
              Navigator.of(context).pop(file);
            },
          );
        }),
      ],
    );
  }
}
