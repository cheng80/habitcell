# MySQL Workbench 사용 가이드

MySQL Workbench를 사용하여 Table Now 데이터베이스의 EER(Enhanced Entity-Relationship) 다이어그램을 생성하고 관리하는 방법을 안내합니다.

## 목차

1. [SQL 스크립트에서 EER 다이어그램 생성 (리버스 엔지니어링)](#1-sql-스크립트에서-eer-다이어그램-생성)
2. [기존 DB에서 EER 다이어그램 생성](#2-기존-db에서-eer-다이어그램-생성)
3. [EER 다이어그램에서 SQL 내보내기 (포워드 엔지니어링)](#3-eer-다이어그램에서-sql-내보내기)

---

## 1. SQL 스크립트에서 EER 다이어그램 생성

DDL SQL 파일(`table_now_db_init_v2.sql`)에서 EER 다이어그램을 생성합니다.

### 단계

1. MySQL Workbench 실행
2. 메뉴: **File** → **Open Model...** 또는 새 모델 생성
3. 메뉴: **File** → **Import** → **Reverse Engineer MySQL Create Script...**
4. `../table_now_db_init_v2.sql` 파일 선택
5. **Place imported objects on a diagram** 체크
6. **Execute** 클릭

### 결과

- 9개 테이블의 EER 다이어그램이 자동 생성됩니다
- 외래키 관계선이 자동으로 연결됩니다

---

## 2. 기존 DB에서 EER 다이어그램 생성

운영 중인 데이터베이스에서 직접 EER 다이어그램을 생성합니다.

### 단계

1. MySQL Workbench 실행
2. 메뉴: **Database** → **Reverse Engineer...**
3. 데이터베이스 연결 정보 입력:
   - **Hostname**: `localhost` 또는 Cloud SQL 주소
   - **Port**: `3306`
   - **Username**: DB 사용자명
   - **Password**: DB 비밀번호
4. **Next** → 스키마 선택 (`table_now_db`)
5. **Next** → **Execute**

### 결과

- 현재 DB 상태 그대로 EER 다이어그램이 생성됩니다
- 인덱스, 외래키, 제약조건이 모두 포함됩니다

---

## 3. EER 다이어그램에서 SQL 내보내기

EER 다이어그램을 수정한 후 SQL 스크립트로 내보냅니다.

### 단계

1. EER 다이어그램에서 테이블 수정
2. 메뉴: **File** → **Export** → **Forward Engineer SQL CREATE Script...**
3. 옵션 설정:
   - ✅ Generate DROP Statements Before Each CREATE Statement
   - ✅ Generate Separate CREATE INDEX Statements
   - ✅ Generate INSERT Statements for Tables
4. 저장 위치 선택 후 **Finish**

---

## 테이블 구조 (v2)

| 번호 | 테이블명 | 설명 |
|------|----------|------|
| 1 | `customer` | 고객 정보 (소셜 로그인 지원) |
| 2 | `store` | 식당 정보 |
| 3 | `store_table` | 테이블 정보 |
| 4 | `password_reset_auth` | 비밀번호 변경 인증 |
| 5 | `device_token` | FCM 기기 토큰 |
| 6 | `reserve` | 예약 정보 |
| 7 | `menu` | 메뉴 정보 |
| 8 | `option` | 추가 메뉴(옵션) |
| 9 | `pay` | 결제 정보 |

---

## 테이블 관계도 (텍스트)

```
customer (1) ──< (N) reserve
customer (1) ──< (N) password_reset_auth
customer (1) ──< (N) device_token

store (1) ──< (N) store_table
store (1) ──< (N) reserve
store (1) ──< (N) menu
store (1) ──< (N) option
store (1) ──< (N) pay

menu (1) ──< (N) option
menu (1) ──< (N) pay

reserve (1) ──< (N) pay

option (1) ──< (N) pay
```

---

## 파일 구조

```
Workbench/
├── README.md                    # 이 파일
└── table_now_db_v2.mwb         # MySQL Workbench 모델 (생성 후 저장)
```

---

## 참고 자료

- [MySQL Workbench 공식 문서](https://dev.mysql.com/doc/workbench/en/)
- [Reverse Engineering 가이드](https://dev.mysql.com/doc/workbench/en/wb-reverse-engineer-create-script.html)
- [Forward Engineering 가이드](https://dev.mysql.com/doc/workbench/en/wb-forward-engineering.html)

---

## 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-01-21 | v2 기준 초기 생성 (weather 테이블 제거됨) |
