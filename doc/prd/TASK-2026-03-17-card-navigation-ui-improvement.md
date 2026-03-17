# TASK-2026-03-17-card-navigation-ui-improvement

## 1. Objective (작업 목표)
`lib/screens/learning_screen.dart`의 카드 내비게이션 UI를 리팩토링하여 모바일 제스처와 PC 키보드 접근성을 강화한다. 향후 다양한 제스처(상하 스와이프 등)를 쉽게 추가할 수 있도록 **확장 가능한 제스처 래퍼(Wrapper) 아키텍처**를 도입한다.

## 2. Target Files (수정 대상)
- `lib/screens/learning_screen.dart`
- `lib/widgets/flash_card.dart`

## 3. Technical Requirements (상세 기술 요구사항)

### A. Extensible Gesture Architecture (확장 가능한 제스처 구조 및 UI 의존성 분리)
제스처 이벤트를 UI 메인 트리에 하드코딩하지 말고, 독립적이고 확장 가능한 래퍼 위젯(예: `CardGestureHandler`)을 설계하여 적용할 것.
**핵심 제약:** 이 래퍼 위젯은 내부에 들어갈 카드 위젯(`FlashCard`, 혹은 향후 추가될 `BreadCard` 등)의 구체적인 구현에 전혀 의존하지 않아야 한다. 오직 `Widget child`로만 상태를 전달받아 **시각적 UI와 제스처 컨트롤 로직을 완전히 분리(Decoupled)**해야 한다.

**요구되는 이벤트 매핑:**
- `onTap` (단일 터치): 카드 뒤집기 (기존 기능 유지)
- `onDoubleTap` (더블 터치): 다음 카드로 이동
- `onSwipeLeft` (좌측 밀기): 다음 카드로 이동
- `onSwipeRight` (우측 밀기): 이전 카드로 이동
- `onSwipeUp` (상단 밀기): [확장용] 더미 로그 출력 (향후 북마크 기능 등)
- `onSwipeDown` (하단 밀기): [확장용] 더미 로그 출력 (향후 오답 노트 기능 등)

*Architecture Example (Agent 참고용 - 완전한 Decoupling):*
```dart
class CardGestureHandler extends StatelessWidget {
  final Widget child; // 어떠한 모양의 카드 위젯이든 수용 가능해야 함
  final VoidCallback onFlip;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;

  // GestureDetector 내부에서 velocity/distance 임계값을 설정하여
  // Tap과 Swipe가 충돌하지 않도록 이벤트 라우팅 구현
}
```

### B. Visual Cues (시각적 힌트 및 UI 개선)
1. **Navigation Arrows (내비게이션 화살표):**
   - 카드 영역 좌/우측에 반투명한 화살표 버튼(`IconButton` + `Icons.arrow_back_ios` / `arrow_forward_ios`)을 오버레이 혹은 병렬 배치.
   - 클릭 시 스와이프와 동일하게 동작해야 함.
2. **Progress Indicator (진행률 표시):**
   - 기존의 텍스트 기반 `(currentIndex / total)` 표시 외에, 화면 상단(AppBar 하단 등)에 `LinearProgressIndicator`를 배치하여 시각적 진행도를 제공.

### C. Desktop/Web Accessibility (키보드 지원 및 포커스)
마우스 클릭 없이 키보드만으로 완전한 조작이 가능해야 함. `Focus` 노드와 `KeyboardListener` (또는 `Shortcuts` & `Actions`) 조합을 사용할 것.
- `Space` 또는 `Enter`: 카드 뒤집기 (`onFlip`)
- `Arrow Right` (우측 방향키): 다음 카드 (`onNext`)
- `Arrow Left` (좌측 방향키): 이전 카드 (`onPrev`)
- **Focus Auto-Request:** 화면 진입 시점 및 카드 전환 시 해당 노드가 자동으로 포커스를 획득하여 클릭 동선 낭비를 제거해야 함.

### D. UX Enhancements (사용자 경험 강화 - Optional but Recommended)
1. **Haptic Feedback (촉각/진동 피드백):**
   - 모바일 환경에서 스와이프를 통한 카드 전환이 성공했을 때, 또는 첫/마지막 카드에서 범위를 벗어난 스와이프를 시도할 때 `HapticFeedback.lightImpact()` 등을 호출하여 물리적인 조작감을 더한다. (`package:flutter/services.dart` 활용)
2. **Swipe Animation (제스처 애니메이션):**
   - 제스처 시 카드가 뻣뻣하게 바로 교체되는 대신, 손가락을 따라 카드가 살짝 밀리거나 부드럽게 화면 밖으로 슬라이드 되는 시각적 피드백(예: `PageView`의 트랜지션 또는 `AnimatedPositioned` 활용)을 고려할 것.
3. **Keyboard Hint (단축키 안내 툴팁):**
   - 데스크탑/웹 환경을 고려하여, 화면 진입 후 일정 시간 동안 하단 혹은 화면 모서리에 "💡 방향키(←/→)로 이동, Space로 카드 뒤집기" 형태의 스낵바(SnackBar)나 툴팁을 띄워 단축키 존재를 학습시킨다.

## 4. Implementation Constraints (구현 제약 사항)
- **제스처 감도 (Thresholds):** `onHorizontalDragEnd` 및 `onVerticalDragEnd` 처리 시 `details.primaryVelocity` 또는 이동 거리에 임계값(예: 300 이상)을 주어 살짝 터치한 것을 스와이프로 오인하지 않도록 방지.
- **애니메이션 충돌 방지:** 스와이프 제스처가 `FlashCard` 내부의 3D 회전 애니메이션 상태를 오염시키지 않도록, 이벤트 버블링과 `HitTestBehavior`를 명확히 제어할 것.

## 5. Acceptance Criteria (검증 지표 - AC)
| ID | Requirement (요구사항) | Verification (검증 방법) |
|:---|:---|:---|
| AC-1 | 스와이프 이동 | 모바일/웹 시뮬레이터에서 좌/우 스와이프 시 카드가 즉시 전환되는가? |
| AC-2 | 제스처 확장성 | 상/하 스와이프 시 미리 정의된 Debug Print 로그가 콘솔에 정상 출력되는가? |
| AC-3 | 제스처 간섭 방지 | 짧은 터치 시 카드가 뒤집히고, 밀기 시 카드가 뒤집히지 않고 전환 이벤트만 발생하는가? |
| AC-4 | 시각적 힌트 | 화면에 좌/우 화살표 아이콘이 존재하며, 클릭 시 카드가 전환되는가? |
| AC-5 | 키보드 매핑 | PC 환경에서 키보드 방향키(좌/우)와 스페이스바로 완벽한 탐색 및 뒤집기가 가능한가? |
| AC-6 | 오토 포커스 | 화면 진입 직후 마우스 클릭을 한 번도 하지 않은 상태에서 AC-5의 키보드 동작이 작동하는가? |
