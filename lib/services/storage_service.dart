import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_item.dart';

class StorageService {
  static const String _progressKey = 'memory_bread_progress';

  // 정적 데이터(assets/data.json)와 저장된 진행 상황을 결합하여 로드
  Future<List<CardItem>> loadCards() async {
    // 1. JSON 파일 로드
    final String jsonString = await rootBundle.loadString('assets/data.json');
    final List<dynamic> jsonList = json.decode(jsonString);

    // 2. LocalStorage에서 진행 상황 로드
    final prefs = await SharedPreferences.getInstance();
    final String? progressString = prefs.getString(_progressKey);
    final Map<String, dynamic> progressMap = progressString != null 
        ? json.decode(progressString) 
        : {};

    // 3. 결합하여 CardItem 리스트 생성
    return jsonList.map((json) {
      final String id = json['id'];
      return CardItem.fromJson(json, progressMap[id]);
    }).toList();
  }

  // 진행 상황 저장
  Future<void> saveProgress(List<CardItem> cards) async {
    final Map<String, dynamic> progressMap = {};
    for (var card in cards) {
      progressMap[card.id] = card.toProgressJson();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_progressKey, json.encode(progressMap));
  }
}
