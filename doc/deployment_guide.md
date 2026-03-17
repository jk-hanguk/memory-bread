# 🍞 암기빵 배포 가이드 (Deployment Guide)

이 문서는 '암기빵' 프로젝트를 GitHub Pages에 배포하는 방법과 관련 설정에 대해 설명합니다.

## 1. 자동 배포 (CI/CD)

본 프로젝트는 GitHub Actions를 통해 자동 배포되도록 설정되어 있습니다.

### 🚀 배포 절차
1. `main` 브랜치로 코드를 푸시하거나 Pull Request를 머지(Merge)합니다.
2. GitHub 저장소의 **Actions** 탭에서 `Deploy to GitHub Pages` 워크플로우가 실행되는지 확인합니다.
3. 빌드 및 배포가 완료되면 약 1~3분 후 배포된 사이트에 반영됩니다.

### ⚙️ CI/CD 설정 상세 (`.github/workflows/deploy.yml`)
- **트리거:** `main` 브랜치에 대한 `push` 이벤트.
- **빌드 환경:** `ubuntu-latest`.
- **Flutter 버전:** `stable` 채널의 최신 버전.
- **빌드 옵션:** `flutter build web --release --base-href "/memory-bread/"`
    - `--base-href` 옵션은 GitHub Pages의 하위 경로(레포지토리 이름)에 맞춰 설정되어 있습니다.

---

## 2. GitHub 저장소 설정 (중요)

배포가 정상적으로 작동하려면 GitHub 저장소에서 다음 설정을 확인해야 합니다.

1. **GitHub Pages 설정:**
    - 저장소 상단 메뉴의 **Settings** -> **Pages**로 이동합니다.
    - **Build and deployment** -> **Source**가 `Deploy from a branch`로 되어 있어야 합니다.
    - **Branch**는 `gh-pages` 브랜치(또는 워크플로우에서 생성한 브랜치)의 `/ (root)`를 선택합니다.
2. **워크플로우 권한:**
    - **Settings** -> **Actions** -> **General**로 이동합니다.
    - 하단의 **Workflow permissions**에서 `Read and write permissions`가 체크되어 있어야 합니다. (GitHub Actions가 `gh-pages` 브랜치에 파일을 쓸 수 있어야 함)

---

## 3. 로컬 테스트 및 수동 빌드

배포 전 로컬 환경에서 웹 빌드를 확인하고 싶다면 다음 명령어를 사용하세요.

### 🛠️ 로컬 웹 실행
```bash
flutter run -d chrome
```

### 📦 수동 웹 빌드
```bash
flutter build web --release --base-href "/memory-bread/"
```
*빌드 결과물은 `build/web` 폴더에 생성됩니다.*

---

## 4. 주의사항

- **Base Href:** 만약 저장소 이름을 변경하거나 개인 도메인을 연결하는 경우, `deploy.yml` 파일의 `--base-href` 값과 `web/index.html` 내의 설정을 그에 맞춰 수정해야 합니다.
- **에셋 경로:** Flutter 웹 배포 시 이미지나 폰트 에셋이 로드되지 않는다면, 상대 경로 설정을 확인하세요.
