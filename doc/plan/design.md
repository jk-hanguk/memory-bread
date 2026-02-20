# 기술 설계 문서 (Design) - 암기빵 (Memory Bread)

## 1. 아키텍처
이 앱은 별도의 백엔드 없이 클라이언트 사이드에서 모든 로직을 처리하는 **PWA (Progressive Web App)** 형태입니다.

- **Frontend:** Flutter Web (Dart)
- **Deployment:** GitHub Pages
- **Storage:** Web Storage (LocalStorage)

## 2. 데이터 모델 (Data Model)

### 2.1. 카드 항목 (CardItem)
```dart
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
}
```

### 2.2. 통계 데이터 (CardStats)
```dart
class CardStats {
  int totalAttempts;
  int passCount;
  bool isMastered; // passCount >= 3

  CardStats({
    this.totalAttempts = 0,
    this.passCount = 0,
    this.isMastered = false,
  });
}
```

## 3. UI/UX 설계 방향

### 3.1. 애니메이션
- **카드 뒤집기:** `Tween<double>`을 사용한 180도 Y축 회전 애니메이션.
- **페이지 전환:** Flutter 고유의 부드러운 화면 전환 효과 활용.

### 3.2. 반응형 레이아웃
- `LayoutBuilder`와 `MediaQuery`를 사용하여 모바일/태블릿/데스크탑 최적화.
- 모바일: 세로형 레이아웃, 대형 카드.
- 태블릿 이상: 가로형 또는 그리드 레이아웃 고려.

### 3.3. 테마
- **Seed Color:** `Colors.deepOrange` 또는 `Colors.brown` (암기빵 테마에 어울리는 색상).
- **Material 3:** 최신 디자인 가이드라인 준수.
- **다크 모드:** 사용자 시력 보호를 위한 다크 모드 지원.

## 4. PWA 설정
- `manifest.json` 설정: 아이콘, 앱 이름(암기빵), 테마 색상 등.
- `index.html` 내 서비스 워커 등록.
- 오프라인 캐싱: 정적 리소스(JS, CSS, JSON) 및 데이터 파일.
