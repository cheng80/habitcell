# Table Now FastAPI 서버

Table Now 애플리케이션을 위한 FastAPI 백엔드 서버입니다.

## 프로젝트 구조

```
fastapi/
├── app/
│   ├── api/              # API 엔드포인트 라우터
│   │   ├── __init__.py
│   │   ├── customer.py   # 고객 API (회원가입, 로그인, 소셜 로그인, FCM 토큰 등)
│   │   ├── menu.py       # 메뉴 API
│   │   ├── option.py     # 옵션 API
│   │   ├── payment.py    # 결제 API
│   │   ├── push_debug.py # FCM 푸시 디버그 API (테스트용)
│   │   ├── reserve.py    # 예약 API
│   │   ├── store.py      # 식당 API
│   │   ├── store_table.py # 테이블 API
│   │   └── weather.py    # 날씨 API (OpenWeatherMap 연동)
│   ├── database/         # 데이터베이스 연결 설정
│   │   ├── __init__.py
│   │   └── connection.py
│   ├── utils/            # 유틸리티 함수
│   │   ├── email_service.py      # 이메일 서비스 (비밀번호 변경 인증)
│   │   ├── fcm_service.py        # FCM 푸시 알림 발송 서비스
│   │   ├── weather_mapping.py    # 날씨 타입 매핑
│   │   └── weather_service.py    # 날씨 데이터 처리 서비스
│   ├── main.py           # FastAPI 애플리케이션 진입점
│   └── main_gt.py        # (백업 파일)
├── mysql/                # 데이터베이스 스키마 및 시드 데이터
│   ├── DATABASE_GUIDE.md
│   ├── table_now_db_init_v1.sql  # 데이터베이스 초기화 스키마 (DDL)
│   ├── table_now_db_seed_v2.sql  # 시드 데이터 (DML)
│   ├── table_now_db_schema.dbml  # DBML 스키마 파일
│   └── Workbench/        # MySQL Workbench 관련 파일
├── php_upload/            # PHP 이미지 업로드 관련 파일
├── requirements.txt       # Python 의존성
└── API_GUIDE.md          # 이 파일
```

## 설치 및 실행

### 1. 가상 환경 생성 및 활성화

```bash
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
```

### 2. 의존성 설치

```bash
pip install -r requirements.txt
```

### 3. 서버 실행

```bash
# fastapi 디렉터리에서 실행 (필수)
cd fastapi
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 또는 main.py 직접 실행
cd fastapi
python app/main.py
```

### 4. API 문서 확인

서버 실행 후 다음 URL에서 API 문서를 확인할 수 있습니다:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## 현재 엔드포인트

### 기본 엔드포인트
- `GET /` - API 정보
- `GET /health` - 헬스 체크

### Customer API (`/api/customer`)
- `GET /api/customer` - 전체 고객 목록 조회
- `GET /api/customer/with-fcm-token` - FCM 토큰이 등록된 고객 목록 조회 (기기 수 포함)
- `GET /api/customer/{customer_seq}` - 고객 상세 조회
- `POST /api/customer/register` - 회원가입
- `POST /api/customer/login` - 로그인
- `POST /api/customer/social-login` - 소셜 로그인 (구글)
- `POST /api/customer/link-social` - 소셜 계정 연결
- `PUT /api/customer/change-password` - 비밀번호 변경
- `PUT /api/customer/{customer_seq}` - 고객 정보 수정
- `DELETE /api/customer/{customer_seq}` - 고객 삭제
- `POST /api/customer/password-reset-request` - 비밀번호 변경 요청
- `POST /api/customer/password-reset-verify` - 비밀번호 변경 인증 코드 확인
- `POST /api/customer/password-reset` - 비밀번호 변경
- `POST /api/customer/{customer_seq}/fcm-token` - FCM 토큰 등록/업데이트 (기기 식별자 포함)
- `POST /api/customer/{customer_seq}/push` - 고객의 모든 기기에 푸시 알림 발송

### Weather API (`/api/weather`)
- `GET /api/weather` - 날씨 데이터 조회 (store_seq 필수, 날짜 범위 선택 가능)
- `GET /api/weather/{store_seq}/{weather_datetime}` - 특정 날씨 데이터 조회
- `GET /api/weather/direct` - OpenWeatherMap API 직접 조회 (DB 저장 없음)
- `GET /api/weather/direct/single` - 단일 식당 날씨 직접 조회
- `POST /api/weather` - 날씨 데이터 추가
- `POST /api/weather/fetch-from-api` - OpenWeatherMap API에서 날씨 데이터 가져오기 (DB 저장)
- `PUT /api/weather/{store_seq}/{weather_datetime}` - 날씨 데이터 수정
- `DELETE /api/weather/{store_seq}/{weather_datetime}` - 날씨 데이터 삭제

### Menu API (`/api/menu`)
- `GET /api/menu/select_menu` - 메뉴 목록 조회
- `GET /api/menu/select_menu/{store_seq}` - 특정 식당의 메뉴 조회
- `GET /api/menu/view_menu_image/{menu_seq}` - 메뉴 이미지 조회
- `POST /api/menu/insert_menu` - 메뉴 추가
- `POST /api/menu/update_menu` - 메뉴 수정
- `DELETE /api/menu/delete_menu/{item_id}` - 메뉴 삭제

### Option API (`/api/option`)
- `GET /api/option/select_options` - 옵션 목록 조회
- `GET /api/option/select_option/{store_seq}/{menu_seq}` - 특정 메뉴의 옵션 조회
- `POST /api/option/insert_option` - 옵션 추가
- `POST /api/option/update_option` - 옵션 수정
- `DELETE /api/option/delete_option/{item_id}` - 옵션 삭제

### Store API (`/api/store`)
- `GET /api/store/select_stores` - 식당 목록 조회
- `GET /api/store/select_store/{item_id}` - 식당 상세 조회
- `POST /api/store/insert_store` - 식당 추가
- `POST /api/store/update_store` - 식당 수정
- `DELETE /api/store/delete_store/{item_id}` - 식당 삭제

### Reserve API (`/api/reserve`)
- `GET /api/reserve/select_reserves` - 예약 목록 조회
- `GET /api/reserve/select_reserve/{item_id}` - 예약 상세 조회
- `POST /api/reserve/insert_reserve` - 예약 생성
- `POST /api/reserve/update_reserve` - 예약 수정
- `DELETE /api/reserve/delete_reserve/{item_id}` - 예약 삭제

### StoreTable API (`/api/store_table`)
- `GET /api/store_table/select_StoreTables` - 테이블 목록 조회
- `GET /api/store_table/select_StoreTable/{store_table_seq}` - 테이블 상세 조회
- `POST /api/store_table/insert_StoreTable` - 테이블 추가
- `POST /api/store_table/update_StoreTable` - 테이블 수정
- `DELETE /api/store_table/delete_StoreTable/{store_table_seq}` - 테이블 삭제

### Payment API (`/api/payment`)
- `GET /api/payment` - 결제 목록 조회
- `GET /api/payment/select_group_by_reserve/{reserve_seq}` - 예약별 결제 그룹 조회
- `GET /api/payment/select_by_reserve/{reserve_seq}` - 예약별 결제 목록 조회
- `GET /api/payment/{id}` - 결제 상세 조회
- `POST /api/payment/insert` - 결제 정보 추가
- `PUT /api/payment/{id}` - 결제 정보 수정
- `DELETE /api/payment/{id}` - 결제 정보 삭제

### Push Debug API (`/api/debug`)
- `POST /api/debug/push` - FCM 단발 푸시 테스트 (DB·예약 로직 없이 푸시 발송만 테스트)

## 엔드포인트 추가 방법

### 1. 라우터 파일 생성

`app/api/` 폴더에 새로운 라우터 파일을 생성합니다.

예시: `app/api/users.py`

```python
from fastapi import APIRouter
from app.database.connection import connect_db

router = APIRouter()

@router.get("/")
async def get_users():
    conn = connect_db()
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM users")
        results = cursor.fetchall()
        return {"users": results}
    finally:
        conn.close()
```

### 2. main.py에 라우터 등록

`app/main.py` 파일에서 라우터를 import하고 등록합니다.

```python
from app.api import users

app.include_router(users.router, prefix="/api/users", tags=["users"])
```

### 3. 데이터베이스 사용

데이터베이스 연결이 필요한 경우:

1. `app/database/connection.py`에서 DB 설정 확인 (환경변수 사용)
2. 라우터에서 `connect_db()` 함수 사용

```python
from app.database.connection import connect_db

@router.get("/")
async def get_users():
    conn = connect_db()
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM users")
        results = cursor.fetchall()
        return {"users": results}
    finally:
        conn.close()
```

## 데이터베이스 설정

### 1. 환경변수 설정

프로젝트 루트에 `.env` 파일을 생성하고 다음 환경변수를 설정하세요:

```env
DB_HOST=localhost
DB_USER=your_user
DB_PASSWORD=your_password
DB_NAME=table_now_db
DB_PORT=3306
```

### 2. 데이터베이스 초기화

`mysql/` 폴더의 SQL 스크립트를 실행하여 데이터베이스를 초기화하세요:

```bash
# 데이터베이스 스키마 생성
mysql -u your_user -p < mysql/table_now_db_init_v1.sql

# 시드 데이터 삽입
mysql -u your_user -p < mysql/table_now_db_seed_v2.sql
```

자세한 내용은 `mysql/DATABASE_GUIDE.md`를 참고하세요.

### 3. 데이터베이스 연결

`app/database/connection.py` 파일에서 환경변수를 읽어 데이터베이스에 연결합니다.

## CORS 설정

현재 모든 origin을 허용하도록 설정되어 있습니다. 프로덕션 환경에서는 특정 도메인으로 제한하세요.

`app/main.py`에서 CORS 설정을 수정할 수 있습니다:

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "https://yourdomain.com"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## 주요 기능

### FCM 푸시 알림
- Firebase Cloud Messaging을 사용하여 푸시 알림을 발송합니다
- `app/utils/fcm_service.py`에서 FCM 발송 로직을 관리합니다
- 고객별 FCM 토큰은 `device_token` 테이블에 저장되며, 기기 식별자(`device_id`)를 포함합니다
- 동일 기기에서 여러 사용자가 로그인할 수 있도록 설계되었습니다
- 고객의 모든 기기에 일괄 발송하거나 특정 토큰에 단발 발송 가능합니다
- 자세한 내용은 `docs/구현 및 설정 가이드/FCM_백엔드_푸시_알림_발송_가이드.md`를 참고하세요

### 날씨 API 연동
- OpenWeatherMap API를 사용하여 식당별 날씨 정보를 가져옵니다
- `app/utils/weather_service.py`에서 날씨 데이터 처리 로직을 관리합니다
- 날씨 데이터는 `weather` 테이블에 저장되며, 각 식당별로 관리됩니다
- 복합키(`store_seq`, `weather_datetime`)를 사용하여 식당별 시점별 날씨 정보를 저장합니다

### 이메일 인증
- 비밀번호 변경 시 이메일 인증 코드를 발송합니다
- `app/utils/email_service.py`에서 이메일 발송 로직을 관리합니다
- 환경변수에 이메일 서버 설정이 필요합니다
- 인증 코드는 `password_reset_auth` 테이블에 저장되며, 10분간 유효합니다

### 소셜 로그인
- 구글 소셜 로그인을 지원합니다
- `customer` 테이블의 `provider` 및 `provider_subject` 컬럼을 사용합니다
- 일반 로그인과 소셜 로그인을 동시에 지원하며, 소셜 계정 연결 기능도 제공합니다

## 데이터베이스 스키마

자세한 스키마 정보는 `mysql/DATABASE_GUIDE.md` 및 `docs/테이블_스펙시트_v_5_erd_02_반영.md`를 참고하세요.

주요 테이블:
- `customer` - 고객 정보 (소셜 로그인 지원)
- `store` - 식당 정보
- `store_table` - 테이블 정보
- `weather` - 날씨 정보 (식당별, 복합 PK, 연관 엔티티)
- `reserve` - 예약 정보
- `menu` - 메뉴 정보
- `option` - 옵션 정보
- `pay` - 결제 정보 (연관 엔티티 - N:M 관계 해소)
- `password_reset_auth` - 비밀번호 변경 인증
- `device_token` - FCM 기기 토큰 (기기 식별자 포함)

## 참고사항

- API 문서는 자동으로 생성됩니다 (Swagger UI: `/docs`, ReDoc: `/redoc`)
- 데이터베이스 연결은 `app/database/connection.py`에서 환경변수를 읽어 설정됩니다
- 각 API 라우터는 `app/main.py`에 등록되어 있습니다
- MySQL 8.0을 사용하며, UTF-8 인코딩(utf8mb4)을 사용합니다
- FCM 푸시 알림 발송 시 유효하지 않은 토큰은 자동으로 데이터베이스에서 삭제됩니다
- `device_token` 테이블의 `device_id`는 동일 기기에서 여러 사용자가 로그인할 수 있도록 UNIQUE 제약조건이 없습니다
