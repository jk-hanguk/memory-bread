class CardItem {
  final String id;
  final String keyword;
  final String description;
  final CardStats stats;
  final DateTime? lastTested;

  CardItem({
    required this.id,
    required this.keyword,
    required this.description,
    required this.stats,
    this.lastTested,
  });

  factory CardItem.fromJson(Map<String, dynamic> json, Map<String, dynamic>? progress) {
    return CardItem(
      id: json['id'],
      keyword: json['keyword'],
      description: json['description'],
      stats: progress != null 
          ? CardStats.fromJson(progress) 
          : CardStats(),
      lastTested: progress?['lastTested'] != null 
          ? DateTime.parse(progress!['lastTested']) 
          : null,
    );
  }

  Map<String, dynamic> toProgressJson() {
    return {
      'lastTested': lastTested?.toIso8601String(),
      ...stats.toJson(),
    };
  }
}

class CardStats {
  int totalAttempts;
  int passCount;
  bool isMastered;

  CardStats({
    this.totalAttempts = 0,
    this.passCount = 0,
    this.isMastered = false,
  });

  factory CardStats.fromJson(Map<String, dynamic> json) {
    return CardStats(
      totalAttempts: json['totalAttempts'] ?? 0,
      passCount: json['passCount'] ?? 0,
      isMastered: json['isMastered'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAttempts': totalAttempts,
      'passCount': passCount,
      'isMastered': isMastered,
    };
  }

  void updateResult(bool passed) {
    totalAttempts++;
    if (passed) {
      passCount++;
    } else {
      // 선택 사항: 오답 시 passCount를 줄이거나 그대로 둘 수 있음
    }
    isMastered = passCount >= 3;
  }
}
