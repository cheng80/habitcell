# Table Now 데이터베이스 스키마

Table Now 프로젝트의 MySQL 데이터베이스 스키마 및 관련 파일을 관리하는 폴더입니다.

## 폴더 구조

```
mysql/
├── DATABASE_GUIDE.md                 # 이 파일
├── table_now_db_init_v2.sql          # 데이터베이스 초기화 스키마 (DDL)
├── table_now_db_current_data_v2.sql  # 시드 데이터 (DML)
├── table_now_db_schema.dbml          # DBML 스키마 파일 (dbdiagram.io 등에서 사용)
└── Workbench/                        # MySQL Workbench 관련 파일
    └── README.md                     # Workbench 사용 가이드
```

## 사용 방법

### 1. 데이터베이스 초기화

`table_now_db_init_v2.sql` 파일을 실행하여 데이터베이스 스키마를 생성합니다:

```bash
mysql -u your_user -p < table_now_db_init_v2.sql
```

또는 MySQL 클라이언트에서:

```sql
source table_now_db_init_v2.sql;
```

**주의사항:**

- 이 스크립트는 기존 데이터베이스를 **완전히 삭제(DROP)**하고 새로 생성합니다
- 기존 데이터가 있다면 백업 후 실행하세요
- `SET FOREIGN_KEY_CHECKS = 0`으로 외래키 제약조건을 일시적으로 비활성화하여 안전하게 삭제합니다

### 2. 시드 데이터 삽입

`table_now_db_current_data_v2.sql` 파일을 실행하여 개발 및 테스트용 초기 데이터를 삽입합니다:

```bash
mysql -u your_user -p < table_now_db_current_data_v2.sql
```

또는 MySQL 클라이언트에서:

```sql
source table_now_db_current_data_v2.sql;
```

**특징:**

- `ON DUPLICATE KEY UPDATE`를 사용하여 중복 실행 시에도 안전합니다
- 테스트용 고객, 식당, 메뉴, 옵션, 예약, 결제 데이터가 포함되어 있습니다

### 3. 데이터베이스 구조

주요 테이블 (9개):

- `customer` - 고객 정보 (소셜 로그인 지원)
- `store` - 식당 정보
- `store_table` - 테이블 정보
- `reserve` - 예약 정보
- `menu` - 메뉴 정보
- `option` - 옵션 정보
- `pay` - 결제 정보 (AUTO_INCREMENT PK, 연관 엔티티 - N:M 관계 해소)
- `password_reset_auth` - 비밀번호 변경 인증
- `device_token` - FCM 기기 토큰 (기기 식별자 포함)

자세한 스키마 정보는 `docs/테이블_스펙시트_v_5_erd_02_반영.md`를 참고하세요.

### 4. MySQL Workbench 사용 (선택사항)

`Workbench/` 폴더에서 자세한 가이드를 참고하세요.

**리버스 엔지니어링 (SQL → EER 다이어그램):**
```
File → Import → Reverse Engineer MySQL Create Script...
→ table_now_db_init_v2.sql 선택
```

**포워드 엔지니어링 (EER 다이어그램 → SQL):**
```
File → Export → Forward Engineer SQL CREATE Script...
```

자세한 내용: `Workbench/README.md`

## 파일 설명

### table_now_db_init_v2.sql

- **기능**: 데이터베이스 초기화 스키마 (DDL)
- **특징**:
  - 모든 테이블을 DROP 후 CREATE
  - 외래키 제약조건 설정
  - 인덱스 설정
  - UTF-8 인코딩 (utf8mb4)
  - 소셜 로그인 지원 (customer 테이블)
  - 비밀번호 변경 인증 (password_reset_auth 테이블)
  - FCM 푸시 알림 (device_token 테이블, device_id 포함)

### table_now_db_current_data_v2.sql

- **기능**: 개발 및 테스트용 초기 데이터 삽입 (DML)
- **포함 데이터**:
  - 테스트 고객 10명 (local/google provider)
  - 식당 3개 (코코이찌방야, 아비꼬, 토모토 카레)
  - 각 식당별 테이블 12개+
  - 각 식당별 메뉴 및 옵션
  - 예약 및 결제 데이터
  - FCM 토큰 데이터
- **특징**: `ON DUPLICATE KEY UPDATE`를 사용하여 중복 실행 시에도 안전

### table_now_db_schema.dbml

- **기능**: DBML 형식의 스키마 파일
- **용도**: 
  - dbdiagram.io 등에서 시각화
  - 문서화 및 스키마 공유
  - 데이터베이스 설계 도구와 연동
- **특징**: 테이블 구조, 관계, 인덱스, 제약조건을 DBML 형식으로 표현

## 테이블 관계

- **1:N 관계**: 대부분의 테이블이 1:N 관계로 연결됨
- **N:M 관계 해소**: `pay` 테이블이 `reserve`와 `menu`/`option`의 N:M 관계를 해소

자세한 관계 정보는 `docs/테이블_스펙시트_v_5_erd_02_반영.md`의 "테이블 간 관계" 섹션을 참고하세요.

## 날씨 정보

- ~~weather 테이블~~ (v2에서 삭제됨)
- 날씨 정보는 **OpenWeatherMap API**를 통해 실시간으로 조회합니다
- API 엔드포인트: `GET /api/weather/direct`, `GET /api/weather/direct/single`

## 주의사항

- 프로덕션 환경에서는 시드 데이터를 사용하지 마세요
- 데이터베이스 초기화 스크립트 실행 시 기존 데이터가 모두 삭제됩니다
- 외래키 제약조건으로 인해 테이블 삭제 순서가 중요합니다 (스크립트에 반영됨)
- `device_token` 테이블의 `device_id`는 동일 기기에서 여러 사용자가 로그인할 수 있도록 UNIQUE 제약조건이 없습니다

## 변경 이력

| 날짜 | 버전 | 변경 내용 |
|------|------|----------|
| 2026-01-15 | v1 | 초기 생성 |
| 2026-01-21 | v2 | weather 테이블 제거, reserve에서 weather_datetime 컬럼 삭제 |
