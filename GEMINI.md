# 암기빵 (Memory Bread) 🍞 - 프로젝트 컨텍스트

이 문서는 '암기빵' 프로젝트의 아키텍처, 기능 요구사항 및 개발 가이드를 제공합니다. 이 프로젝트는 도라에몽의 에피소드에서 착안하여, 사용자가 효율적으로 정보를 암기할 수 있도록 돕는 PWA 앱입니다.

## 1. 프로젝트 개요

- **목적:** 플래시카드와 퀴즈를 통한 기억력 훈련 (인출 연습, 간격 반복, 청킹 전략 활용).
- **타겟 플랫폼:** Web (PWA 지원), GitHub Pages 배포.
- **주요 기능:**
    - **학습 모드 (빵 먹기):** 5~10개 단위(청킹)의 플래시카드 뒤집기 학습.
    - **테스트 모드 (소화 확인):** 4지 선다형 객관식 퀴즈 (양방향 테스트 지원).
    - **통계 대시보드 (빵빵한 주머니):** 학습 진행도 및 마스터 여부(3회 이상 테스트 통과) 확인.
    - **데이터 관리:** `assets/datasets/` 내의 다중 JSON 데이터셋 지원 및 `SharedPreferences` 기반 진행 상황 저장.

## 2. 기술 스택 및 아키텍처

- **Framework:** Flutter 3.41.2 (Web/PWA)
- **Asset Management:** Flutter 3.10+ 표준인 `AssetManifest` API를 사용하여 `assets/datasets/` 하위의 JSON 파일을 동적으로 탐색합니다.
- **State Management:** 기본 `StatefulWidget` 및 `ValueNotifier`를 활용한 상태 관리.
- **Data Model:** 
    - `CardItem`: 키워드, 설명, ID 등 정보를 포함.
    - `CardStats`: 시도 횟수, 통과 횟수, 마스터 상태(3회 통과 시)를 관리.
- **Storage:** `shared_preferences`를 사용하여 LocalStorage에 사용자 학습 데이터를 저장.
- **Deployment:** GitHub Actions를 통한 GitHub Pages 자동 배포 (`.github/workflows/deploy.yml`).

## 3. 주요 파일 및 디렉토리 구조

- `lib/main.dart`: 애플리케이션 진입점 및 홈 화면.
- `lib/screens/`: 각 기능별 화면 (학습, 테스트, 대시보드, 데이터셋 브라우저).
- `lib/services/storage_service.dart`: 자산 로드 및 진행 상황 저장 로직.
- `lib/models/card_item.dart`: 데이터 모델 정의.
- `assets/datasets/`: 학습용 JSON 데이터 파일들이 카테고리별로 저장됨.
- `doc/plan/`: 상세 설계 및 계획 문서.

## 4. 빌드 및 실행 가이드

- **의존성 설치:** `flutter pub get`
- **로컬 실행 (크롬):** `flutter run -d chrome`
- **웹 빌드:** `flutter build web`
- **배포:** `main` 브랜치 푸시 시 GitHub Actions를 통해 자동 배포됨.

## 5. 개발 컨벤션

- **UI 스타일:** Material 3 기반, `Color(0xFF8D6E63)`(갈색) 및 `Color(0xFFFFF8E1)`(베이지)를 주축으로 하는 따뜻한 '암기빵' 테마.
- **다크모드 미지원:** 본 앱은 암기빵 테마의 따뜻한 감성을 유지하기 위해 **라이트 모드 전용**으로 설계되었습니다. 다크모드는 지원하지 않으며, 관련 디자인 수정 시에도 라이트 모드 기준을 따릅니다.
- **반응형:** 모바일 최적화를 최우선으로 하며, `LayoutBuilder`를 사용하여 웹 환경에서도 적절한 레이아웃을 제공.
- **용어 컨셉:** 학습은 '빵 먹기', 테스트는 '소화 확인', 통계는 '빵빵한 주머니' 등 테마에 어울리는 용어 사용.

## 6. TODO (진행 현황)

- [x] `lib/main.dart`를 설계된 데이터 모델과 홈 화면으로 교체.
- [x] `assets/datasets/`를 탐색하고 로드하는 데이터 레이어 구현.
- [x] `shared_preferences`를 이용한 진행 상황 저장/로드 로직 구현.
- [x] 플래시카드 뒤집기 애니메이션을 포함한 학습 화면 구현.
- [x] 4지 선다형 테스트 화면 및 결과 반영 로직 구현.
- [x] PWA 설정 및 GitHub Actions 배포 자동화.
- [x] 빵가게 (Bread Shop) - 외부 GitHub 데이터셋 연동 및 다운로드 기능 구현.
- [ ] 오답 노트 (잘 안 외워지는 빵들 모아보기) 기능 추가.
- [ ] 간격 반복(SRS) 알고리즘 기반 복습 알림 로직 (선택 사항).
- [ ] 다국어 지원 (현재 한국어 위주).
