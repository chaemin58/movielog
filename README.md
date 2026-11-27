# MovieLog

Flutter로 만드는 영화 조회·평점 기록 앱입니다. UMC Flutter 워크북을 따라 UI 구성, TMDB 연동, 평점 CRUD를 구현하고 있으며, 현재 **9주차 즐겨찾기·검색·페이지네이션 Required Mission**까지 구현했습니다.

> 챌린지는 포함하지 않습니다. 자동 테스트와 실제 서버·기기 수동 검증은 구분합니다.

## 주요 기능

- 인기 영화, 영화 목록·상세 정보 조회 및 장르 필터
- 선택한 장르 로컬 저장
- 평점·코멘트 입력과 등록 응답을 이용한 상세 화면의 내 평점 표시
- 회원가입, JWT 로그인, 앱 재시작 시 세션 복원
- 마이페이지에서 로그인한 회원의 닉네임 표시 및 로그아웃
- 기본 사람 아이콘과 선택적 이미지 URL을 지원하는 프로필 위젯

## 기술 구성

| 영역 | 사용 기술 |
| --- | --- |
| 앱 | Flutter / Dart (SDK 조건: `^3.13.3`) |
| 상태 관리 | Provider, ChangeNotifier 기반 ViewModel |
| 라우팅 | GoRouter, 인증 상태에 따른 redirect |
| HTTP | Dio, 인증 인터셉터 |
| 저장소 | flutter_secure_storage, shared_preferences |
| 환경 설정·이미지 | flutter_dotenv, flutter_svg |

## 실행 방법

1. `pubspec.yaml`의 SDK 조건을 만족하는 Flutter SDK를 준비합니다.
2. 프로젝트 루트에 `.local.env`를 만들고 TMDB Read Access Token을 설정합니다.

   ```dotenv
   TMDB_ACCESS_TOKEN=YOUR_TMDB_READ_ACCESS_TOKEN
   ```

3. 의존성을 설치하고 사용할 기기에서 실행합니다.

   ```bash
   flutter pub get
   flutter run
   ```

`.local.env`는 Git에서 제외되어 있습니다. MovieLog JWT는 로그인 응답으로 받아 보안 저장소에 저장하며 환경 파일에 넣지 않습니다. 비밀번호·JWT·Authorization 헤더 원문을 로그나 스크린샷에 남기지 않습니다. 환경 파일을 Flutter asset으로 포함하는 것은 비밀을 숨기는 수단이 아닙니다.

## 프로젝트 구조

```text
lib/
├── app/             # Provider 구성과 앱 초기화
├── core/            # TMDB 설정, HTTP 클라이언트, 인증 인터셉터
├── data/
│   ├── models/      # API 요청·응답 모델
│   ├── services/    # 로그인, 회원 정보, TMDB API
│   └── storage/     # 토큰 저장소
├── router/          # 화면 경로와 인증 redirect
├── screens/         # 로그인, 영화, 마이페이지 등 화면
├── service/         # 평점·회원가입 API와 로컬 설정
├── view_models/     # 화면 상태와 비동기 처리
├── widgets/         # 공통 UI 및 기능별 위젯
└── theme/           # 색상과 테마
test/                # ViewModel·라우팅·위젯 테스트
assets/              # 폰트, 로고, 아이콘, 실습 이미지
```

## 8주차 인증 흐름

### 로그인과 내 정보

```text
POST /v8/auth/login
→ accessToken 저장
→ signedIn으로 전환
→ MainScreen에서 loadMember() 호출
→ GET /v8/members/me
→ AuthViewModel.member 저장
→ 마이페이지가 member를 구독해 닉네임 표시
```

프로필 화면에서 AuthViewModel을 새로 만들지 않고 Provider가 제공하는 기존 객체를 사용합니다. GET me 응답은 이메일·닉네임·가입일입니다. 소개·통계·선호 장르는 기존 디자인 예시이며 서버의 실제 회원 정보가 아닙니다.

### 재시작·만료·로그아웃

- 재시작 시 스플래시에서 토큰을 읽고 **GET me 성공 후에만** 홈으로 이동합니다.
- 세션 확인 중 네트워크 실패는 토큰 삭제 대신 재시도 화면으로 처리합니다.
- 보호 요청에는 MovieLog JWT를, TMDB 요청에는 TMDB 토큰을 사용하는 별도 클라이언트를 사용합니다.
- 인증 인터셉터는 보호 요청의 HTTP 401과 `AUTH401_2/3/4`를 확인해 세션 정리를 요청합니다.
- 만료 시 로그인 화면에서 일회성 Snackbar를 표시합니다. 직접 로그아웃과 로그인 실패는 만료 안내 대상이 아닙니다.
- 로그아웃은 토큰과 `member`를 지우고 로그인 화면으로 이동합니다. 서버 측 토큰 폐기를 보장하는 기능은 아닙니다.
- `sessionVersion`으로 이전 세션의 늦은 인증 오류와 평점 응답이 현재 세션에 영향을 주지 않도록 검사합니다.

## 평점 API와 이번 주차의 범위

| 동작 | 경로 | 인증 |
| --- | --- | --- |
| 공개 회원별 평점 조회 | `GET /v8/members/{memberId}/ratings` | 없음 |
| 평점 등록 | `POST /v8/ratings` | MovieLog JWT |
| 평점 수정 | `PATCH /v8/ratings/{ratingId}` | MovieLog JWT |
| 평점 삭제 | `DELETE /v8/ratings/{ratingId}` | MovieLog JWT |
| 내 정보 조회·닉네임 수정 | `GET /v8/members/me`, `PATCH /v8/members/me` | MovieLog JWT |

**로그인과 GET me 응답에는 `memberId`가 없으며, 토큰 기반 내 평점 목록 GET도 제공되지 않습니다.** 공개 조회는 별도로 알고 있는 회원 ID가 필요합니다. JWT의 명세에 없는 claim을 추정해 회원 ID로 사용하지 않습니다.

따라서 8주차 기본 범위는 **현재 로그인 세션에서 등록 응답으로 받은 Rating을 표시하고, 그 `ratingId`로 수정·삭제하는 것**입니다. 앱 재시작 후 로그인한 회원의 기존 평점 전체 복원은 지원 완료 기능이 아닙니다.

현재 ‘내가 등록한 평점’ 진입은 기존 `LearningMemberSession.memberId`를 사용하므로, 로그인만 했거나 앱을 재시작한 경우 ‘학습용 회원가입이 필요합니다’가 표시될 수 있습니다. 이는 토큰 오류를 뜻하지 않습니다.

## 8주차 진행 현황

### 코드에 구현된 내용

- 로그인·보안 저장소·GET me 기반 복원·보호 화면 redirect
- 인증 만료 처리, 직접 로그아웃, 만료 Snackbar 구분
- MainScreen의 내 정보 조회 및 마이페이지 닉네임 구독
- 평점 등록 요청에서 memberId 제외, 등록 Rating을 상세 화면에 표시
- 인터셉터와 평점 ViewModel의 이전 세션 응답 검사
- `/my/profile/edit` 화면과 PATCH me 서비스, 성공 시 `member` 교체 로직
- 닉네임 2~12자 검증, `MEMBER409_1` 중복 입력 유지, 네트워크 실패 후 재시도 로직
- 마이페이지 프로필 수정 버튼의 `/my/profile/edit` 연결
- 공개 회원별 평점 조회 경로 및 DELETE 성공 코드 204 적용

### 남은 작업과 검증

- [ ] 프로필 조회 실패와 로딩 상태를 구분해 재시도 안내
- [x] 평점 등록 화면의 기존 학습용 memberId 의존 제거
- [ ] 현재 세션에서 등록한 Rating의 수정·삭제 UI 연결
- [ ] PATCH 결과를 Rating으로 받아 화면 상태 교체
- [ ] 평점 오류 처리를 `RATING403_1`, `RATING404_1`, `RATING409_1` 등 도메인 코드에 맞게 정리
- [ ] 로그인·재시작·프로필 변경·만료·로그아웃을 실제 서버와 선택한 기기에서 검증
- [ ] 403·409·네트워크 실패 시 로그인 유지, 실제 401 만료 안내 검증
- [x] 기존 평점 테스트를 변경된 API 계약에 맞게 정비하고 중복 조회 문제 해결

프로필 이미지 URL은 위젯의 표시 옵션입니다. 현재 GET me에는 사진 URL이 없고, 프로필 사진 업로드·저장 API 연동은 구현되어 있지 않습니다.

## 검증

```bash
flutter analyze
flutter test
flutter test test/rating_session_test.dart
```

9주차 자동 검증은 정적 분석과 전체 테스트로 수행합니다. 실제 서버·기기 수동 검증은 별도이며, 현재 실행 환경에서 MovieLog 호스트 DNS 조회가 실패했습니다. PR 본문과 수동 확인 항목은 [9주차 PR 본문](docs/week9-pr.md)에 정리했습니다.

## 9주차 Required Mission

- 상세 제목 옆 북마크: 서버 여부 조회, 등록·해제, 버튼 로딩, 실패 시 상태 유지, 409/404 재조회
- 마이페이지의 평점 행 아래 내 즐겨찾기: JWT 목록과 TMDB 정보를 결합하고 상세 복귀 시 갱신
- 영화 정보는 최대 5개씩 조회하며 일부 실패는 placeholder와 카드별 재조회로 처리
- 영화 목록: 첫 페이지, 더 보기, 동일 페이지 재시도, 중복 영화 제거, 장르 변경 시 초기화
- 검색: `/movies/search`에서 제출 시 요청, 공백 검색 차단, 별도 페이지 상태와 더 보기
- 검색·즐겨찾기 화면은 하단 탭 없이 뒤로가기를 제공
- 세션별 Provider key와 요청 generation으로 계정 전환·로그아웃·늦은 응답 보호
- 홈의 인기 영화 5개 조회는 유지. debounce·무한 스크롤·평점/즐겨찾기 통합 저장은 제외

## 에셋과 라이선스

기존 1~3주차 실습용 로고·SVG 아이콘·포스터·폰트를 사용합니다.

- Manrope: Google Fonts, SIL Open Font License 1.1
- SVG Icons: Google Material Symbols, Apache License 2.0
- 프로필·영화 이미지: `Remix of MovieLog` Stitch 프로젝트에서 생성된 실습용 이미지
- Manrope에 없는 한글 글리프는 플랫폼 대체 폰트로 표시됩니다.

라이선스 원문은 `licenses/`, 에셋 관련 안내는 [ASSET-NOTICE.md](ASSET-NOTICE.md)를 참고하세요.
