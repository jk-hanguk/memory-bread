import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class BakeryService {
  // 기본 데이터 저장소 (추후 사용자 설정 가능하게 확장)
  final String owner = 'memory-bread';
  final String repo = 'bakery';
  final String branch = 'main';

  static const String _purchasedBreadsKey = 'memory_bread_purchased_list';
  static const String _breadDataPrefix = 'memory_bread_data_';
  static const String _breadMetadataKey = 'memory_bread_metadata';

  /// GitHub API를 통해 특정 경로의 파일/폴더 목록을 가져옵니다.
  Future<List<dynamic>> fetchContents(String path) async {
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$path?ref=$branch');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        developer.log('Failed to fetch contents: ${response.statusCode}', name: 'BakeryService');
        return [];
      }
    } catch (e) {
      developer.log('Error fetching contents: $e', name: 'BakeryService');
      return [];
    }
  }

  /// 빵(JSON)을 다운로드하여 로컬에 저장합니다.
  Future<bool> downloadBread(String remotePath, String breadId, String breadName) async {
    final url = Uri.parse('https://raw.githubusercontent.com/$owner/$repo/$branch/$remotePath');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        
        // 1. 실제 데이터 저장
        await prefs.setString(_breadDataPrefix + breadId, response.body);
        
        // 2. 메타데이터(이름 등) 저장
        Map<String, dynamic> metadata = {};
        final String? metadataStr = prefs.getString(_breadMetadataKey);
        if (metadataStr != null) {
          metadata = json.decode(metadataStr);
        }
        metadata[breadId] = {'name': breadName, 'path': remotePath, 'downloadedAt': DateTime.now().toIso8601String()};
        await prefs.setString(_breadMetadataKey, json.encode(metadata));

        // 3. 구매 목록에 추가
        List<String> purchased = prefs.getStringList(_purchasedBreadsKey) ?? [];
        if (!purchased.contains(breadId)) {
          purchased.add(breadId);
          await prefs.setStringList(_purchasedBreadsKey, purchased);
        }
        
        return true;
      }
      return false;
    } catch (e) {
      developer.log('Error downloading bread: $e', name: 'BakeryService');
      return false;
    }
  }

  /// 빵 이름 가져오기
  Future<String> getBreadName(String breadId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? metadataStr = prefs.getString(_breadMetadataKey);
    if (metadataStr != null) {
      final Map<String, dynamic> metadata = json.decode(metadataStr);
      return metadata[breadId]?['name'] ?? breadId;
    }
    return breadId;
  }

  /// 구매한 빵의 목록을 가져옵니다.
  Future<List<String>> getPurchasedBreadIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_purchasedBreadsKey) ?? [];
  }

  /// 특정 빵의 데이터를 가져옵니다.
  Future<String?> getBreadData(String breadId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_breadDataPrefix + breadId);
  }

  /// 빵 삭제
  Future<void> removeBread(String breadId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_breadDataPrefix + breadId);
    
    // 메타데이터 삭제
    final String? metadataStr = prefs.getString(_breadMetadataKey);
    if (metadataStr != null) {
      final Map<String, dynamic> metadata = json.decode(metadataStr);
      metadata.remove(breadId);
      await prefs.setString(_breadMetadataKey, json.encode(metadata));
    }

    List<String> purchased = prefs.getStringList(_purchasedBreadsKey) ?? [];
    purchased.remove(breadId);
    await prefs.setStringList(_purchasedBreadsKey, purchased);
  }
}
