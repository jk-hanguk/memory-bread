import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_item.dart';
import 'bakery_service.dart';
import 'dart:developer' as developer;

class StorageService {
  static const String _progressKeyPrefix = 'memory_bread_progress_';
  final BakeryService _bakeryService = BakeryService();

  Future<List<CardItem>> loadCards(String assetPath) async {
    try {
      String jsonString;
      
      // Bakery 데이터인 경우 로컬에서 로드
      if (assetPath.startsWith('bakery://')) {
        final breadId = assetPath.replaceFirst('bakery://', '');
        jsonString = await _bakeryService.getBreadData(breadId) ?? '[]';
      } else {
        // 기존 Asset 로드
        jsonString = await rootBundle.loadString(assetPath);
      }

      final List<dynamic> jsonList = json.decode(jsonString);

      final prefs = await SharedPreferences.getInstance();
      final String progressKey = _progressKeyPrefix + assetPath;
      final String? progressString = prefs.getString(progressKey);
      final Map<String, dynamic> progressMap = progressString != null 
          ? json.decode(progressString) 
          : {};

      return jsonList.map((json) {
        final String id = json['id'];
        return CardItem.fromJson(json, progressMap[id]);
      }).toList();
    } catch (e) {
      developer.log('Error loading cards: $e', name: 'StorageService');
      return [];
    }
  }

  Future<void> saveProgress(String assetPath, List<CardItem> cards) async {
    final Map<String, dynamic> progressMap = {};
    for (var card in cards) {
      progressMap[card.id] = card.toProgressJson();
    }

    final prefs = await SharedPreferences.getInstance();
    final String progressKey = _progressKeyPrefix + assetPath;
    await prefs.setString(progressKey, json.encode(progressMap));
  }

  // 최신 Flutter 3.10+ 공식 AssetManifest API 사용 + Bakery 구매 목록 추가
  Future<List<String>> listDatasets() async {
    try {
      // 1. AssetManifest 라이브러리를 사용하여 안전하게 자산 목록 로드
      final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final List<String> allAssets = manifest.listAssets();
      
      final List<String> datasets = allAssets
          .where((String key) {
            final lowerKey = key.toLowerCase();
            return lowerKey.contains('datasets/') && lowerKey.endsWith('.json');
          })
          .toList();

      // 2. Bakery에서 구매한 빵 목록 추가
      final List<String> purchasedBreadIds = await _bakeryService.getPurchasedBreadIds();
      for (var id in purchasedBreadIds) {
        datasets.add('bakery://$id');
      }

      developer.log('Total Datasets Found: ${datasets.length} (Assets: ${datasets.length - purchasedBreadIds.length}, Bakery: ${purchasedBreadIds.length})', name: 'StorageService');
      
      return datasets;
    } catch (e) {
      developer.log('Critical Error using AssetManifest API: $e', name: 'StorageService');
      return [];
    }
  }
}
