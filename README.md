# Blunux Installer

Blunux / Arch Linux 용 GUI 패키지 설치 도구입니다.
GitHub에 있는 설치 스크립트를 클릭 한 번으로 실행할 수 있습니다.

## 기능

- sudo 비밀번호를 **한 번만** 입력하면 세션 전체에 유지
- 패키지 카드를 클릭해서 선택 → Install 버튼으로 일괄 설치
- 오른쪽 패널에 실시간 설치 로그 출력
- 순차 설치 큐 지원
- 카드별 상태 표시 (설치 중 / 완료 / 실패)

## 설치 방법

### 1. 패키지 파일 다운로드

[Releases](https://github.com/nidoit/appinstaller/releases) 페이지에서
`blunux-installer-*.pkg.tar.zst` 파일을 다운로드합니다.

### 2. pacman 으로 설치

```bash
sudo pacman -U blunux-installer-*.pkg.tar.zst
```

### 3. 실행

```bash
blunux-installer
```

또는 앱 런처에서 **Blunux Installer** 검색 후 실행

---

## 사용 방법

1. 앱 실행 후 **sudo 비밀번호** 입력
2. 설치할 패키지 카드 클릭 (여러 개 선택 가능)
3. **Install** 버튼 클릭
4. 오른쪽 로그 패널에서 설치 진행 상황 확인

## 포함된 패키지 목록

| 분류 | 패키지 |
|------|--------|
| 브라우저 & 커뮤니케이션 | Chrome, Firefox, MS Teams, Zoom |
| 생산성 & 오피스 | LibreOffice, Obsidian, VLC, GIMP |
| 개발 & 시스템 | VS Code, Docker, Julia, yay |
| 입력기 & 한국어 | KIME (한국어 입력기), KR Fonts, Nerd Fonts |

## 제거 방법

```bash
sudo pacman -R blunux-installer
```

## 요구 사항

- Arch Linux / Blunux
- webkit2gtk-4.1 (pacman으로 자동 설치됨)
- libayatana-appindicator, librsvg (pacman으로 자동 설치됨)
