# 🍞 부실빵 검사실 (Wrong Answer Note) - PRD

**날짜:** 2026-03-18
**작업명:** 부실빵 검사실 (Wrong Answer Note) - 학습面包 불균형 관리 및 소화 시간 기반 스케줄 시스템

---

## 1. 개요 (Overview)

현재 '암기빵' 앱은 랜덤 방식으로 문제를 제시하지만, 사용자가 자주 틀리는 문제들을 체계적으로 파악하고 집중 복습할 수 있는 기능이 부족합니다. 이 기능은 **오답 데이터를 수집**하여 약점 보완에 필요한 학습 bread 를 선별하고, **소화 시간 (SRS 기반)**을 고려한 최적의 복습 타이밍을 제안하는 시스템입니다.

**핵심 목표:**
- 오답面包를 자동으로 분류 및 추적
- 소화 불량面包에 대한 집중 복습 유도  
- 불균형한 학습 패턴 해소 및 마스터 속도 향상

---

## 2. 주요 개념 (Core Concepts)

### 2.1 부실빵의 구조 (Reject Structure)
*   **공식 주머니 (Official Collection):** 앱 내부에 포함된 기본 학습面包(`assets/datasets/`)
*   **부실bread (Reject Bread):** 테스트에서 틀린 bread 로 자동 분류된 items
    *   오답횟수, 마지막 오류 시간, 카테고리 정보를 포함
*   **소화불량 로그 (Digestion Log):** 오답 내역을 기록한 타임라인
    *   언제, 어떤 bread 가 소화되지 않았는지 추적

### 2.2 불량bread 관리 및 소유 (Reject Management)
*   **부실bread 검사실 (Inspection Room):** 불량面包들을 확인하고 관리하는 화면
*   **불량bread 분류대 (Reject Station):** 오답 bread 를 카테고리/난이도로 분류하여 표시
*   **재작面包 대기소 (Re-bake Queue):** 마스터가 될 때까지 대기 중인 bread 들 순서
*   **소화 시간 알림 (Digestion Timer):** 최적의 복습 타이밍 제안
    *   마지막 오답 기준으로 간격 반복 적용
*   **완벽한 소화 (Perfect Digestion):** 3 회 이상 정답 시 마스터 완료 상태

---

## 3. 기능 상세 (Functional Requirements)

### 3.1 오답 수집 및 기록 시스템

#### FR-001: 자동 오답 수집
- **설명:** 테스트 모드에서 틀린 bread 에 대해 자동으로 정보를 기록
- **입력:** 
  - `cardId`:bread 의 고유 ID
  - `keyword`, `explanation`:bread 내용
  - `wrongCount`:오답 횟수 초기값 1
  - `lastWrongTime`:오답 발생 Timestamp
- **출력:** `WrongAnswerItem` 객체 생성 및 저장

#### FR-002: 수동 오답 추가
- **설명:** 사용자가 학습 후 직접 특정 bread 를 부실bread 로 추가할 수 있음
- **사용 흐름:** 학습/테스트 완료 → "+ 추가하기" 버튼 → 정보 입력 → 저장

#### FR-003: 마스터 상태 자동 전환
- **조건:** 통과 횟수 ≥ 3 회 또는 오답횟수 = 0
- **동작:** `isMastered = true`로 변경 및 부실bread 리스트에서 제거 (또는 완료 상태로 표시)

### 3.2 부실bread 검사실 화면

#### FR-010: 오답bread 목록 표시
- **정렬 기준:** 오답횟수 내림순, 최근 오답시간 내림순
- **표시 정보:**
  - bread 카테고리 (카테고리 아이콘)
  - 키워드 + 설명 (Latex 렌더링 지원)
  - 오답횟수 (🔥 🔥 🔥 등 시각적 표현)
  - 마지막 오류 시간 ("2 일 전", "10 분 전" 등)
  - 마스터 상태 (✅ 표시)

#### FR-011: 카테고리 필터링 및 검색
- **필터:** 전체/카테고리별/난이도별 보기
- **검색:** 키워드나 bread 이름으로 텍스트 검색
- **기간 필터:** 최근 일주일/한 달/전체 기간 선택

#### FR-012: 항목 상세 조회 및 수정
- **상세 보기:** 해당 bread 의 전체 학습 이력 (올린 날짜, 통과율 등)
- **수정:** 키워드/설명 편집 가능 (선택 사항)
- **삭제:** 더 이상 필요 없음을 표시 → `wrong_answers` 목록에서 제거

### 3.3 소화 시간 기반 복습 제안 시스템

#### FR-020: 우선순위 계산
- **우선도 공식:** 
  ```dart
  priority = (wrongCount * 10) + (daysSinceLastWrong * -5) + (categoryDifficultyMultiplier)
  ```
  - 오답횟수 ↑ = 우선순위 ↑
  - 최근 오류 → 시간이 지남 = 우선순위 ↓
- **결과:** 매일 최우선 복습 bread N 개 추천

#### FR-021: 소화 시간 알림 타이머
- **알림 주기:** 마지막 오답 후 N 일째 (N = 오답횟수에 따라 조정)
- **사용자 경험:** 
  - 홈 화면에 "오늘 복습할 빵" 섹션 추가
  - 푸시 알림 또는 로컬 알림 (선택 사항, 브라우저 알림 API 활용)

#### FR-022: 재학습 유도
- **유도 방법:** 
  - 부실bread 검사실 → 해당 bread → 다시 테스트 모드 진입
  - 학습 bread → 다시 학습 완료 후 추가 테스트 진행

### 3.4 통계 및 분석 기능

#### FR-030: 불균형面包 비율 확인
- **표시 항목:**
  - 총bread 수 vs 오답bread 수
  - 카테고리별 분포 (예: 수학 70%, 과학 20%, 영어 10%)
  - 마스터되지 않은 bread 리스트

#### FR-031: 학습 패턴 분석
- **일별/주간/월간 트렌드:** 
  - 오답 발생 빈도 그래프
  - 카테고리별 취약점 시각화
- **대응 제안:** 
  - "수학 문제를 더 많이 복습하세요" (빈번한 오답 카테고리 감지)

---

## 4. 기술 요구사항 (Technical Requirements)

### 4.1 데이터 모델링

#### WrongAnswerItem 클래스
```dart
class WrongAnswerItem {
  final String id;              // 고유 ID (cardId + timestamp 조합)
  final String cardId;          // 해당하는 카드의 ID
  final String category;        // 카테고리명
  final Keyword keyword;        // 키워드 정보 (LaTeX 포함)
  final Explanation explanation; // 설명 정보
  final int wrongCount;         // 오답 횟수
  final DateTime firstWrongTime; // 최초 오답 시간
  final DateTime lastWrongTime;  // 마지막 오답 시간
  final DateTime masteryTime;    // 마스터 완료 시간 (선택)
  final String? notes;          // 사용자 메모 (선택 사항)
  
  // 계산된 속성
  int get daysSinceLastError => 
    DateTime.now().difference(lastWrongTime).inDays + 1;
    
  double get priorityScore => 
    (wrongCount * 10.0) / (daysSinceLastError + 1);
}
```

### 4.2 서비스 계층 구조

#### WrongAnswerService 인터페이스
```dart
class WrongAnswerService {
  // 저장/수집
  Future<void> recordWrongAnswer(String cardId, KeywordItem keyword, String category);
  
  // 조회/검색
  Future<List<WrongAnswerItem>> getRecentWrongAnswers(
    int limit, 
    String? sortBy, // wrongCount DESC, lastWrongTime DESC
    List<String>? categories
  );
  
  // 마스터 처리
  Future<void> markAsMastered(String id);
  
  // 삭제/관리
  Future<void> removeProblem(String id);
  Future<void> deleteRejectedItems(DateTime olderThan); // 오래된 bread 자동 정리
  
  // 통계 제공
  WrongAnswerStats getStats();
  Map<String, int> getCategoryDistribution();
}

// 데이터 클래스
class WrongAnswerStats {
  final int totalWrongCount;         // 총오답횟수
  final int pendingMasterCount;      // 마스터 대기 중 bread 수 (wrongCount > 0)
  final List<WrongAnswerItem> topWrongAnswers; // 우선순위 상위 N 개
  final Map<String, WrongAnswerCategoryStats> byCategory; // 카테고리별 통계
  
  class WrongAnswerCategoryStats {
    final String categoryName;
    final int totalCount;
    final int wrongCount;
    final double masterRate;         // 마스터 비율
  }
}
```

### 4.3 스토리지 설계

#### SharedPreferences 키 구조
```dart
const String _wrongAnswersKey = 'wrong_answers';  // JSON 형태로 저장
const String _digestionLogKey = 'digestion_log';  // 오답 타임라인 (선택)
const String _wrongStatsKey = 'wrong_stats';      // 통계 데이터
```

#### JSON 저장 포맷 예시
```json
{
  "items": [
    {
      "id": "math_integration_01_20260318",
      "cardId": "math_integration_01",
      "category": "수학",
      "keyword": {"content": "∫x²dx = x³/3 + C"},
      "explanation": {"content": "..."},
      "wrongCount": 5,
      "firstWrongTime": "2026-03-18T10:30:00",
      "lastWrongTime": "2026-03-19T14:15:00",
      "masteryTime": null,
      "notes": null
    }
  ],
  "meta": {
    "version": "1.0",
    "lastUpdated": "2026-03-18T15:00:00"
  }
}
```

### 4.4 성능 고려사항

#### 데이터 크기 관리
- **최대 항목 수:** 500 개 (초과 시 가장 오래된bread 자동 정리 또는 알림)
- **로딩 전략:** 처음 N 개만 메모리에 로드 (페이징 처리)
- **메모리 최적화:** `ListView.builder` 와 지연 로딩 활용

#### 백업 및 복구
- **백업 주기:** 매일 자정 기준 SharedPreferences 내 데이터 자동 백업
- **복구:** 앱 재설치 시 Google Drive 또는 GitHub 에서 백업 복원 (선택 사항)

---

## 5. 개발 단계 (Development Phases)

### Phase 1: 핵심 기능 구축 [우선순위 1] - **2 일**

| 작업 항목 | 우선순위 | 소요 시간 | 담당자 |
|-----------|----------|------------|--------|
| WrongAnswerItem 모델 정의 및 테스트 데이터 생성 | 🔴 고 | 0.5 일 | 백엔드 |
| WrongAnswerService 구현 (저장, 조회, 통계 로직) | 🔴 고 | 1.0 일 | 백엔드 |
| storage_service.dart 확장 (_wrongAnswersKey 추가) | 🟡 중 | 0.25 일 | 인프래 |
| 부실bread 검사실 화면 skeleton (`WrongAnswerNoteScreen`) | 🟡 중 | 0.25 일 | 프론트엔드 |

**출력:** 기본적인 오답 수집, 목록 조회, 화면 표시 가능

---

### Phase 2: UI/UX 완성 및 기능 고도화 [우선순위 2] - **1.5 일**

| 작업 항목 | 우선순위 | 소요 시간 | 담당자 |
|-----------|----------|------------|--------|
| 부실bread 카드 위젯 (`WrongAnswerCardWidget`) 디자인 | 🟡 중 | 0.75 일 | 프론트엔드 |
| 소화 시간 기반 우선순위 계산 로직 구현 | 🔴 고 | 0.25 일 | 백엔드 |
| 카테고리 필터링 및 검색 기능 추가 | 🟢 저 | 0.5 일 | 프론트엔드 |
| 화면 레이아웃 반응형 최적화 (모바일/데스크톱) | 🟢 저 | 0.25 일 | 프론트엔드 |

**출력:** 완성도 높은 UI, 필터링 및 검색 기능 동작

---

### Phase 3: 테스트 및 리팩토링 [우선순위 3] - **1 일**

| 작업 항목 | 우선순위 | 소요 시간 | 담당자 |
|-----------|----------|------------|--------|
| 단위 테스트 작성 (모델, 서비스, 위젯) | 🔴 고 | 0.5 일 | 테스터/백엔드 |
| 통합 테스트 및 버그 수정 (테스트→저장→조회 플로우) | 🔴 고 | 0.25 일 | 테스터/전체 |
| 성능 테스트 (대용량 데이터, 100+ bread 처리) | 🟡 중 | 0.25 일 | 백엔드 |
| 문서화 및 코드 리뷰 완료 | 🟢 저 | 0.25 일 | 모든 사람 |

**출력:** 버그 없는 기능, 문서를 포함한 프로덕션 준비 버전

---

### Phase 4: 추가 기능 (선택 사항) - **향후 계획**

| 작업 항목 | 우선순위 | 소요 시간 | 담당자 |
|-----------|----------|------------|--------|
| 푸시 알림 시스템 (복습 타이밍 알림) | 🟡 중 | 1.0 일 | 백엔드/프론트엔드 |
| 오답bread 삭제 자동화 (오래된 데이터 정리) | 🟢 저 | 0.5 일 | 백엔드 |
| 음성/이미지 설명 추가 옵션 | 🟢 저 | 1.0 일 | 전체 |

---

## 6. 연관 아이디어 및 개선사항

### 6.1 스마트 복습 스케줄링 (SRS 통합)
- **간격 반복 알고리즘:** Leitner 시스템 기반의 간격 시간 적용
  - 첫 오답: 다음 학습 1 일 후
  - 2 차 오답: 다음 학습 3 일 후  
  - 3 차 이상: 7 일, 14 일, 30 일 등 점진적 증가
- **마스터 상태 기준:** 
  - 통과 횟수 ≥ 3 회 → `isMastered = true`
  - 30 일 연속 정답 → 골드 bread 🏆

### 6.2 커뮤니티 및 공유 기능 (장기 계획)
- **나만의 부실bread 공유:** 사용자가 자신의 취약점 빵을 다른 사용자와 공유
- **랭킹 시스템:** 가장 빠른 소화 속도 (마스터 시간) 경쟁
- **레시피 공유:** 효과 좋은 학습 방법/팁 공유

### 6.3 AI 기반 패턴 분석 (장기 계획)
- **머신러닝 활용:** 
  - 사용자별 오답 패턴 분석
  - 예측: 어떤 bread 를 먼저 복습하면 더 빠른 마스터 여부
- **추천 시스템:** 
  - 개인화된 학습 경로 제시
  - 약점 보완을 위한 bread 추천

### 6.4 모바일 포팅 대응
- **서버 연동 옵션:** 로컬 스토리지 → 서버 DB (Firebase 등) 마이그레이션 고려
- **실시간 동기화:** 여러 기기에서 동일한 오답 데이터 공유
- **오프라인 지원:** 기본 PWA 로직 유지

---

## 7. 성공 기준 (Success Metrics)

| 지표 | 목표 | 측정 방법 |
|------|-------|------------|
| 오답bread 수집 정확도 | 100% | 테스트 모드에서 모든 오답 자동 기록 확인 |
| 소화 시간 알림 클릭율 | ≥ 30% | 푸시 알림/홈 섹션 클릭 추적 (선택) |
| 마스터 속도 향상률 | 2 배 이상 | 기존 학습 vs 부실bread 기능 사용 시 평균 마스터 시간 비교 |
| 사용자 만족도 | ≥ 4.5/5 | 앱 스토어 리뷰, 피드백 형식 |

---

## 8. 연관 문서

- [시스템 설계서 (`doc/plan/design.md`)](/memory-bread/doc/plan/design.md)
- [기능 요구사항 (`doc/plan/requirements.md`)](/memory-bread/doc/plan/requirements.md)  
- [마일스톤 계획 (`doc/plan/milestones.md`)](/memory-bread/doc/plan/milestones.md)

---

## 9. 승인 요청

이 PRD 문서 내용이 타당하다면 다음 단계를 진행하겠습니다:

1. **코드 생성:** Phase 1 작업 시작 (모델, 서비스, 기본 화면)
2. **PR 등록:** Pull Request 로 코드 리뷰 요청
3. **테스트 및 배포:** 통합 테스트 후 Production 브랜치에 머지

**승인:** [ ] 승인됨 | 수정 필요: __________ | 기각 사유: __________

---

*마지막 업데이트: 2026-03-18*