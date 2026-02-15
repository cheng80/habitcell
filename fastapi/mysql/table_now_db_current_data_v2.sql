-- ===========================================================
-- 시드 데이터 v2 (weather 테이블 제거 버전)
-- 기존 table_now_db_current_data.sql에서 마이그레이션
-- 생성일: 2026-01-21
-- 작성자: 김택권
-- 변경사항: weather 테이블 데이터 제거, reserve에서 weather_datetime 컬럼 제거
-- ===========================================================

USE `table_now_db`;

START TRANSACTION;

SET FOREIGN_KEY_CHECKS = 0;


-- customer 테이블 데이터 (변경 없음)
INSERT INTO `customer` (`customer_seq`, `customer_name`, `customer_phone`, `customer_email`, `customer_pw`, `created_at`, `provider`, `provider_subject`)
VALUES
  (1, '테스트유저01', '010-0000-0001', 'user001@gmail.com', 'qwer1234', '2026-01-15 09:00:00', 'local', NULL),
  (2, '테스트유저02', '010-0000-0002', 'user002@gmail.com', 'qwer1234', '2026-01-15 09:00:00', 'local', NULL),
  (3, '테스트유저03', '010-0000-0003', 'user003@gmail.com', 'qwer1234', '2026-01-15 09:00:00', 'local', NULL),
  (4, '김택권', '010-2626-2131', 'cheng80@naver.com', 'qwer1234', '2026-01-15 12:30:36', 'local', NULL),
  (5, '조조', '010-1234-0000', 'jojo@han.com', 'qwer1234', '2026-01-15 12:41:23', 'local', NULL),
  (6, 'son2', '010-1111-1111', 'son@han.com', 'qwer4321', '2026-01-15 12:45:41', 'local', NULL),
  (8, '김택권', '010-2626-2131', 'cheng80@gmail.com', NULL, '2026-01-15 15:27:26', 'google', '112839999546210025745'),
  (9, 'son3', NULL, 'son3@han.com', 'qwer1234', '2026-01-15 18:35:37', 'local', NULL),
  (10, '임소연', NULL, 'qwerty147704@gmail.com', NULL, '2026-01-16 02:52:25', 'google', '106247753715742105186'),
  (11, 'GT', '01087351340', 'lambda2003@gmail.com', 'qwer1234', '2026-01-19 03:32:23', 'local', NULL)
ON DUPLICATE KEY UPDATE `customer_seq` = VALUES(`customer_seq`), `customer_name` = VALUES(`customer_name`), `customer_phone` = VALUES(`customer_phone`), `customer_email` = VALUES(`customer_email`), `customer_pw` = VALUES(`customer_pw`), `created_at` = VALUES(`created_at`), `provider` = VALUES(`provider`), `provider_subject` = VALUES(`provider_subject`);

-- store 테이블 데이터 (변경 없음)
INSERT INTO `store` (`store_seq`, `store_address`, `store_lat`, `store_lng`, `store_phone`, `store_opentime`, `store_closetime`, `store_description`, `store_image`, `store_placement`, `created_at`)
VALUES
  (1, '서울 마포구 양화로 45 (메세나폴리스 2층)', 37.5577, 126.924, '02-820-7042', '11:00', '21:30', '코코이찌방야 합정 메세나폴리스점', 'coco_hapjeong.jpg', '{"tables": [{"seq": 1, "pos_x": 150.0, "pos_y": 200.0}, {"seq": 38, "pos_x": 300.0, "pos_y": 300.0}]}', '2026-01-15 10:00:00'),
  (2, '서울 마포구 홍익로 25', 37.5563, 126.9236, '02-323-0129', '11:30', '21:30', '아비꼬 홍대1호점', 'abiko_hongdae.jpg', '배치 v1', '2026-01-15 10:00:00'),
  (3, '서울 마포구 와우산로29길 27 1층', 37.5524, 126.9238, '0507-1403-4200', '11:30', '21:00', '토모토 카레 홍대점', 'tomoto_hongdae.jpg', '배치 v1', '2026-01-15 10:00:00')
ON DUPLICATE KEY UPDATE `store_seq` = VALUES(`store_seq`), `store_address` = VALUES(`store_address`), `store_lat` = VALUES(`store_lat`), `store_lng` = VALUES(`store_lng`), `store_phone` = VALUES(`store_phone`), `store_opentime` = VALUES(`store_opentime`), `store_closetime` = VALUES(`store_closetime`), `store_description` = VALUES(`store_description`), `store_image` = VALUES(`store_image`), `store_placement` = VALUES(`store_placement`), `created_at` = VALUES(`created_at`);

-- store_table 테이블 데이터 (변경 없음)
INSERT INTO `store_table` (`store_table_seq`, `store_seq`, `store_table_name`, `store_table_capacity`, `store_table_inuse`, `created_at`)
VALUES
  (1, 1, 1, 2, 0, '2026-01-15 10:05:00'),
  (2, 1, 2, 2, 0, '2026-01-15 10:05:00'),
  (3, 1, 3, 2, 0, '2026-01-15 10:05:00'),
  (4, 1, 4, 2, 0, '2026-01-15 10:05:00'),
  (5, 1, 5, 2, 0, '2026-01-15 10:05:00'),
  (6, 1, 6, 2, 0, '2026-01-15 10:05:00'),
  (7, 1, 7, 2, 0, '2026-01-15 10:05:00'),
  (8, 1, 8, 4, 0, '2026-01-15 10:05:00'),
  (9, 1, 9, 4, 0, '2026-01-15 10:05:00'),
  (10, 1, 10, 4, 0, '2026-01-15 10:05:00'),
  (11, 1, 11, 4, 0, '2026-01-15 10:05:00'),
  (12, 1, 12, 4, 0, '2026-01-15 10:05:00'),
  (13, 2, 1, 2, 0, '2026-01-15 10:05:00'),
  (14, 2, 2, 2, 0, '2026-01-15 10:05:00'),
  (15, 2, 3, 2, 0, '2026-01-15 10:05:00'),
  (16, 2, 4, 2, 0, '2026-01-15 10:05:00'),
  (17, 2, 5, 2, 0, '2026-01-15 10:05:00'),
  (18, 2, 6, 2, 0, '2026-01-15 10:05:00'),
  (19, 2, 7, 2, 0, '2026-01-15 10:05:00'),
  (20, 2, 8, 4, 0, '2026-01-15 10:05:00'),
  (21, 2, 9, 4, 0, '2026-01-15 10:05:00'),
  (22, 2, 10, 4, 0, '2026-01-15 10:05:00'),
  (23, 2, 11, 4, 0, '2026-01-15 10:05:00'),
  (24, 2, 12, 4, 0, '2026-01-15 10:05:00'),
  (25, 3, 1, 2, 0, '2026-01-15 10:05:00'),
  (26, 3, 2, 2, 0, '2026-01-15 10:05:00'),
  (27, 3, 3, 2, 0, '2026-01-15 10:05:00'),
  (28, 3, 4, 2, 0, '2026-01-15 10:05:00'),
  (29, 3, 5, 2, 0, '2026-01-15 10:05:00'),
  (30, 3, 6, 2, 0, '2026-01-15 10:05:00'),
  (31, 3, 7, 2, 0, '2026-01-15 10:05:00'),
  (32, 3, 8, 4, 0, '2026-01-15 10:05:00'),
  (33, 3, 9, 4, 0, '2026-01-15 10:05:00'),
  (34, 3, 10, 4, 0, '2026-01-15 10:05:00'),
  (35, 3, 11, 4, 0, '2026-01-15 10:05:00'),
  (36, 3, 12, 4, 0, '2026-01-15 10:05:00'),
  (38, 1, 13, 4, 0, '2026-01-19 16:36:02')
ON DUPLICATE KEY UPDATE `store_table_seq` = VALUES(`store_table_seq`), `store_seq` = VALUES(`store_seq`), `store_table_name` = VALUES(`store_table_name`), `store_table_capacity` = VALUES(`store_table_capacity`), `store_table_inuse` = VALUES(`store_table_inuse`), `created_at` = VALUES(`created_at`);

-- menu 테이블 데이터 (변경 없음)
INSERT INTO `menu` (`menu_seq`, `store_seq`, `menu_name`, `menu_price`, `menu_description`, `menu_image`, `menu_cost`, `created_at`)
VALUES
  (1, 1, '로스까스카레', 11900, '코코이찌방야 대표 돈까스 카레', 'coco_ross.png', 4760, '2026-01-15 10:10:00'),
  (2, 1, '알새우카레', 12900, '새우 토핑 카레', 'coco_shrimp.png', 5160, '2026-01-15 10:10:00'),
  (3, 1, '비프샤브카레', 13500, '비프샤브 토핑 카레', 'coco_beefshabu.jpg', 5400, '2026-01-15 10:10:00'),
  (4, 1, '닭가슴살스테이크카레', 13700, '닭가슴살 스테이크 토핑 카레', 'coco_chickensteak.png', 5480, '2026-01-15 10:10:00'),
  (5, 2, '100시간카레', 7500, '아비꼬 대표 카레', 'abiko_100h.jpg', 3000, '2026-01-15 10:10:00'),
  (6, 2, '버섯카레', 9500, '버섯 토핑 카레', 'abiko_mushroom.jpg', 3800, '2026-01-15 10:10:00'),
  (7, 2, '허브치킨카레', 9800, '허브치킨 토핑 카레', 'abiko_herbchicken.jpg', 3920, '2026-01-15 10:10:00'),
  (8, 2, '쉬림프카레', 11800, '쉬림프 토핑 카레', 'abiko_shrimp.jpg', 4720, '2026-01-15 10:10:00'),
  (9, 3, '오므카레', 9500, '오므 + 카레', 'tomoto_omucurry.jpg', 3800, '2026-01-15 10:10:00'),
  (10, 3, '토모토카레', 8500, '흰밥 + 카레', 'tomoto_basic.jpg', 3400, '2026-01-15 10:10:00'),
  (11, 3, '토모토+치킨가라아게', 12300, '토모토카레 + 치킨가라아게', 'tomoto_karaage.jpg', 4920, '2026-01-15 10:10:00'),
  (12, 3, '토모토+수제생돈카츠', 13000, '토모토카레 + 수제 생돈카츠', 'tomoto_porkcutlet.jpg', 5200, '2026-01-15 10:10:00')
ON DUPLICATE KEY UPDATE `menu_seq` = VALUES(`menu_seq`), `store_seq` = VALUES(`store_seq`), `menu_name` = VALUES(`menu_name`), `menu_price` = VALUES(`menu_price`), `menu_description` = VALUES(`menu_description`), `menu_image` = VALUES(`menu_image`), `menu_cost` = VALUES(`menu_cost`), `created_at` = VALUES(`created_at`);

-- option 테이블 데이터 (변경 없음)
INSERT INTO `option` (`option_seq`, `store_seq`, `menu_seq`, `option_name`, `option_price`, `option_cost`, `created_at`)
VALUES
  (1, 1, 1, '눈꽃치즈 토핑', 2200, 660, '2026-01-15 10:15:00'),
  (2, 1, 1, '감자튀김', 2000, 600, '2026-01-15 10:15:00'),
  (3, 1, 1, '치즈볼', 2000, 600, '2026-01-15 10:15:00'),
  (4, 2, 5, '온천계란', 1500, 450, '2026-01-15 10:15:00'),
  (5, 2, 5, '눈꽃치즈', 1500, 450, '2026-01-15 10:15:00'),
  (6, 2, 5, '치킨가라아게', 5000, 1500, '2026-01-15 10:15:00'),
  (7, 2, 5, '왕새우튀김', 5000, 1500, '2026-01-15 10:15:00'),
  (8, 3, 10, '치킨 가라아게 토핑', 3500, 1050, '2026-01-15 10:15:00'),
  (9, 3, 10, '치즈 함바그 토핑', 4000, 1200, '2026-01-15 10:15:00'),
  (10, 3, 10, '야채스아게 토핑', 3000, 900, '2026-01-15 10:15:00'),
  (11, 3, 10, '고로케 토핑', 2500, 750, '2026-01-15 10:15:00')
ON DUPLICATE KEY UPDATE `option_seq` = VALUES(`option_seq`), `store_seq` = VALUES(`store_seq`), `menu_seq` = VALUES(`menu_seq`), `option_name` = VALUES(`option_name`), `option_price` = VALUES(`option_price`), `option_cost` = VALUES(`option_cost`), `created_at` = VALUES(`created_at`);

-- [삭제됨] weather 테이블 데이터
-- 옵션 A 마이그레이션: weather 테이블이 제거되어 데이터 삽입 불필요
-- 날씨 정보는 OpenWeatherMap API를 통해 실시간으로 조회

-- reserve 테이블 데이터 (weather_datetime 컬럼 제거됨)
INSERT INTO `reserve` (`reserve_seq`, `store_seq`, `customer_seq`, `reserve_tables`, `reserve_capacity`, `reserve_date`, `created_at`, `payment_key`, `payment_status`)
VALUES
  (1, 1, 1, '1,2', 2, '2026-01-23 12:00:00', '2026-01-15 12:20:00', 'paykey_demo_001', 'DONE'),
  (2, 2, 2, '6', 1, '2026-01-23 12:30:00', '2026-01-15 18:25:00', 'paykey_demo_002', 'DONE')
ON DUPLICATE KEY UPDATE `reserve_seq` = VALUES(`reserve_seq`), `store_seq` = VALUES(`store_seq`), `customer_seq` = VALUES(`customer_seq`), `reserve_tables` = VALUES(`reserve_tables`), `reserve_capacity` = VALUES(`reserve_capacity`), `reserve_date` = VALUES(`reserve_date`), `created_at` = VALUES(`created_at`), `payment_key` = VALUES(`payment_key`), `payment_status` = VALUES(`payment_status`);

-- pay 테이블 데이터 (변경 없음)
INSERT INTO `pay` (`pay_id`, `reserve_seq`, `store_seq`, `menu_seq`, `option_seq`, `pay_quantity`, `pay_amount`, `created_at`)
VALUES
  (1, 1, 1, 1, NULL, 1, 11900, '2026-01-15 12:20:10'),
  (2, 1, 1, 1, 1, 1, 2200, '2026-01-15 12:20:10'),
  (3, 1, 1, 1, 2, 1, 2000, '2026-01-15 12:20:10'),
  (6, 1, 1, 1, 4, 5, 6, '2026-01-16 09:53:25'),
  (9, 1, 1, 5, 1, 2, 500, '2026-01-16 09:59:48'),
  (10, 1, 1, 5, 1, 2, 500, '2026-01-16 10:05:16'),
  (11, 1, 1, 5, 1, 2, 500, '2026-01-16 10:06:33'),
  (12, 1, 1, 5, 1, 2, 500, '2026-01-16 10:06:33')
ON DUPLICATE KEY UPDATE `pay_id` = VALUES(`pay_id`), `reserve_seq` = VALUES(`reserve_seq`), `store_seq` = VALUES(`store_seq`), `menu_seq` = VALUES(`menu_seq`), `option_seq` = VALUES(`option_seq`), `pay_quantity` = VALUES(`pay_quantity`), `pay_amount` = VALUES(`pay_amount`), `created_at` = VALUES(`created_at`);

-- device_token 테이블 데이터 (변경 없음)
INSERT INTO `device_token` (`device_token_seq`, `customer_seq`, `fcm_token`, `device_type`, `device_id`, `created_at`, `updated_at`)
VALUES
  (1, 8, 'eSZyqPunRrSpD-ZMsy5pn0:APA91bHDkOOqLSWDa48x6mUWwjWCf5z2FasUwaV1oqYmOVDaFiMWtE3MbPDyYpBilXVGOI-d5jdGk1WcQIu26S1Jlf2oFIJYKzJnhNGcOymD3f8O9dZWeCM', 'android', 'BE2A.250530.026.D1', '2026-01-18 15:03:57', '2026-01-21 01:36:52'),
  (2, 9, 'f_fDcWneSTeH0QtPgDqViF:APA91bGGxOmcX9RAMIEfcj5KoQdyde9eisnRUXgrfb-WJw-VDS4-QxUkl570zDJlD9spOTJaVr2-ivGjaeF81Mwz4cXp4e1_QWhyplte5FTbM98kC65zuXA', 'android', NULL, '2026-01-18 15:06:18', '2026-01-18 15:06:18'),
  (3, 9, 'cgXGHXrrSZS7WtiN1gFxhN:APA91bGMT0z2zNAx6HOKdRkxepdpBSeA7h9-PXyEAFSVUpwJU3SPt9kTKpN8kVut7PgLGh5PgBw-gtBp8-pjsrJKTlPP2kE5gXeZOevtzcOUko6AK-kEOIw', 'android', 'BE2A.250530.026.D1', '2026-01-19 01:02:08', '2026-01-19 03:24:32'),
  (5, 11, 'cqxGjbawRXuCsJ8bVUiUyG:APA91bF_jMq8X8TRXV3SDEtoO3zSW9E9aOE9Vv3gpmkJOkSQ8iwQaOY--VpzTAHkE26CZM6_7bjOg5PxMzjxBdK92YO0-mKkolERlN9B8ewxmB0cTAcHLoA', 'android', 'BE2A.250530.026.D1', '2026-01-19 04:33:17', '2026-01-20 02:33:17'),
  (6, 2, 'fIzrwiAEQQODwV-kRigEtK:APA91bHSes2GPV-b6-ROWaJdlFhATtMU0FACogRYtPLHbC-xfxcg7tmEEkgOtuFlB37iyyBYERs0bmxfyjrmhmHxR9SMmHHfto5FCwwSeQaeWeZSVQAELiQ', 'android', 'BE2A.250530.026.D1', '2026-01-19 14:16:10', '2026-01-20 03:33:03'),
  (7, 1, 'cwi8ZFrcT5OlYZlbKl49Mk:APA91bH_3NUcebqaISkUNF_lFUXrWsTzku0kZQ2H-oY6VUL1mZWQfbbboYw7UZz_Ux8ep7bfeVuZfmM716p1SO8nt6StVFuDIWHAnndNFKlDXQD-cZjX6dk', 'android', 'BE2A.250530.026.D1', '2026-01-19 14:27:09', '2026-01-19 14:43:38'),
  (8, 4, 'espqKf2dTb6pT_W_fKkg1o:APA91bGuGP_xTVGoB7hSFLxSwHjHbIhsfog4J2uZl5yzdS49T1X4aWVVBrVa1wsS265kzWLd2lIjJL3-7mvl5fLqjHS1lRvYJOb3TInBrBhxNx6XwSZxXMc', 'android', 'BE2A.250530.026.D1', '2026-01-19 15:17:18', '2026-01-19 15:21:00')
ON DUPLICATE KEY UPDATE `device_token_seq` = VALUES(`device_token_seq`), `customer_seq` = VALUES(`customer_seq`), `fcm_token` = VALUES(`fcm_token`), `device_type` = VALUES(`device_type`), `device_id` = VALUES(`device_id`), `created_at` = VALUES(`created_at`), `updated_at` = VALUES(`updated_at`);

-- password_reset_auth 테이블 데이터 (변경 없음)
INSERT INTO `password_reset_auth` (`auth_seq`, `customer_seq`, `auth_token`, `auth_code`, `expires_at`, `is_verified`, `created_at`)
VALUES
  (1, 4, '7a9f84cd-a573-46e3-8a06-00b2e54fb7a4', '538164', '2026-01-16 01:14:30', 1, '2026-01-15 16:04:29')
ON DUPLICATE KEY UPDATE `auth_seq` = VALUES(`auth_seq`), `customer_seq` = VALUES(`customer_seq`), `auth_token` = VALUES(`auth_token`), `auth_code` = VALUES(`auth_code`), `expires_at` = VALUES(`expires_at`), `is_verified` = VALUES(`is_verified`), `created_at` = VALUES(`created_at`);

SET FOREIGN_KEY_CHECKS = 1;

COMMIT;

-- ===========================================================
-- 마이그레이션 요약
-- ===========================================================
-- 변경 사항:
--   1. weather 테이블 INSERT 제거 (7건 삭제)
--   2. reserve 테이블에서 weather_datetime 컬럼 제거
--
-- 데이터 보존:
--   - customer: 10건 ✅
--   - store: 3건 ✅
--   - store_table: 37건 ✅
--   - menu: 12건 ✅
--   - option: 11건 ✅
--   - reserve: 2건 ✅ (weather_datetime만 제거)
--   - pay: 8건 ✅
--   - device_token: 8건 ✅
--   - password_reset_auth: 1건 ✅
--
-- 삭제된 데이터:
--   - weather: 7건 ❌ (테이블 제거됨)
-- ===========================================================
