# 암기빵 (Memory Bread) 🍞 - 프로젝트 컨텍스트

이 문서는 '암기빵' 프로젝트의 아키텍처, 기능 요구사항 및 개발 가이드를 제공합니다. 이 프로젝트는 도라에몽의 에피소드에서 착안하여, 사용자가 효율적으로 정보를 암기할 수 있도록 돕는 PWA 앱입니다.

## 1. 프로젝트 개요

- **목적:** 플래시카드와 퀴즈를 통한 기억력 훈련 (인출 연습, 간격 반복, 청킹 전략 활용).
- **타겟 플랫폼:** Web (PWA 지원), GitHub Pages 배포.
- **주요 기능:**
    - **학습 모드:** 5~10개 단위(청킹)의 플래시카드 뒤집기 학습.
    - **테스트 모드:** 4지 선다형 객관식 퀴즈 (양방향 테스트 지원).
    - **통계 대시보드:** 학습 진행도 및 마스터 여부(3회 이상 테스트 통과) 확인.
    - **데이터 관리:** JSON 기반 정적 데이터 및 LocalStorage 기반 사용자 진행 상황 저장.

## 2. 기술 스택 및 아키텍처

- **Framework:** Flutter (Web/PWA)
- **State Management:** (필요 시 도입 예정, 현재는 기본 State 활용 가능)
- **Data Model:** 
    - `CardItem`: 키워드, 설명, ID 등 정보를 포함.
    - `CardStats`: 시도 횟수, 통과 횟수, 마스터 상태 등을 관리.
- **Storage:** 브라우저의 `LocalStorage`를 사용하여 오프라인에서도 진행 상황 유지.
- **Deployment:** GitHub Pages.

## 3. 주요 파일 및 디렉토리 구조

- `lib/main.dart`: 애플리케이션의 진입점 (현재 기본 카운터 앱 상태로, 설계에 맞게 교체 필요).
- `assets/data.json`: 학습용 키워드 및 설명 데이터 (화학 원소 등 예시 데이터 포함).
- `doc/plan/`: 상세 설계 및 계획 문서.
    - `requirements.md`: 기능 및 기술적 요구사항.
    - `design.md`: 데이터 모델 및 UI/UX 설계 방향.
    - `milestones.md`: 단계별 개발 로드맵.
- `analysis_options.yaml`: Dart 린트 및 코딩 스타일 설정.

## 4. 빌드 및 실행 가이드

- **의존성 설치:** `flutter pub get`
- **로컬 실행 (크롬):** `flutter run -d chrome`
- **웹 빌드:** `flutter build web`
- **배포 (GitHub Pages):** `flutter build web` 후 `build/web` 폴더의 내용을 배포 브랜치에 업로드.

## 5. 개발 컨벤션

- **UI 스타일:** Material 3를 준수하며, `Colors.deepOrange` 또는 `Colors.brown` 계열의 따뜻한 암기빵 테마를 사용합니다.
- **반응형:** `LayoutBuilder`와 `MediaQuery`를 사용하여 모바일 최적화를 우선하되 태블릿/데스크탑에서도 사용 가능하도록 설계합니다.
- **애니메이션:** 카드 뒤집기 등 학습 경험을 향상시키는 부드러운 애니메이션을 적용합니다.
- **코드 품질:** `flutter_lints` 규칙을 준수하며, `dart_format`을 적용합니다.

## 6. TODO (우선순위 순)

1. [ ] `lib/main.dart`를 설계된 데이터 모델과 홈 화면으로 교체.
2. [ ] `assets/data.json`을 로드하는 데이터 레이어 구현.
3. [ ] `LocalStorage`를 이용한 진행 상황 저장/로드 로직 구현.
4. [ ] 플래시카드 뒤집기 애니메이션을 포함한 학습 화면 구현.
5. [ ] 4지 선다형 테스트 화면 및 결과 반영 로직 구현.
6. [ ] PWA 설정 및 GitHub Pages 배포 자동화.
