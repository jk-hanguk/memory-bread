# 암기빵 (Memory Bread) 🍞

기억력 훈련을 위한 PWA 앱입니다. 도라에몽의 에피소드에서 착안하여, 먹으면 외워지는 '암기빵'처럼 효율적인 학습을 돕습니다.

## 주요 기능
- **플래시카드 학습:** 키워드와 설명을 뒤집어가며 반복 학습.
- **객관식 테스트:** 학습한 내용을 기반으로 한 4지 선다형 퀴즈.
- **진행 상황 추적:** 학습 및 테스트 결과를 로컬에 저장하여 마스터 여부 확인.
- **PWA 지원:** 설치 없이 브라우저에서 바로 사용하며 오프라인 환경 지원.

## 기술 스택
- **Framework:** Flutter (Web/PWA)
- **Deployment:** GitHub Pages
- **Storage:** Web LocalStorage

## 개발 문서
- [기능 요구사항 정의서](doc/plan/requirements.md)
- [개발 단계별 계획](doc/plan/milestones.md)
- [기술 설계 문서](doc/plan/design.md)
- [원본 대화 기록](doc/memory-training-conversation.md)

## 실행 방법
1. Flutter 환경 구축
2. 의존성 설치: `flutter pub get`
3. 웹 실행: `flutter run -d chrome`
4. 빌드: `flutter build web`
