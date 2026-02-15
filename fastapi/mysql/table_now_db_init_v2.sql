# MySQL 8.0 스키마 스크립트 v2 (weather 테이블 제거 버전)

-- > 기준: ERD_02 + 옵션 A 마이그레이션 (weather 테이블 및 reserve.weather_datetime 컬럼 제거)
-- > 목적: **기존 테이블 존재 여부와 무관하게 안정적으로 Drop → Create**
-- > 작성일: 2026-01-21
-- > 작성자: 김택권
-- > 변경사항: weather 테이블 삭제, reserve 테이블에서 weather_datetime 컬럼 및 FK 제거
-- =========================================================
-- MySQL 8.0 DDL
-- Source: ERD_02 (weather 테이블 제거 버전)
-- Engine: InnoDB
-- Charset/Collation: utf8mb4 / utf8mb4_0900_ai_ci
-- =========================================================

-- ---------------------------------------------------------
-- Database 초기화
-- ---------------------------------------------------------
DROP DATABASE IF EXISTS `table_now_db`;

CREATE DATABASE `table_now_db` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

USE `table_now_db`;

SET NAMES utf8mb4;

SET FOREIGN_KEY_CHECKS = 0;

-- Drop tables (reverse dependency order)
DROP TABLE IF EXISTS `pay`;

DROP TABLE IF EXISTS `option`;

DROP TABLE IF EXISTS `menu`;

DROP TABLE IF EXISTS `reserve`;

DROP TABLE IF EXISTS `password_reset_auth`;

DROP TABLE IF EXISTS `device_token`;

DROP TABLE IF EXISTS `store_table`;

DROP TABLE IF EXISTS `store`;

DROP TABLE IF EXISTS `customer`;

SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------
-- 1) customer
-- ---------------------------------------------------------
CREATE TABLE `customer` (
    `customer_seq` INT NOT NULL AUTO_INCREMENT COMMENT '고객 번호',
    `customer_name` VARCHAR(255) NOT NULL COMMENT '고객 이름',
    `customer_phone` VARCHAR(255) NULL COMMENT '고객 전화번호 (소셜 로그인 시 NULL 가능)',
    `customer_email` VARCHAR(255) NOT NULL COMMENT '고객 이메일',
    `customer_pw` VARCHAR(255) NULL COMMENT '비밀번호 (소셜 로그인 시 NULL)',
    `provider` VARCHAR(255) NOT NULL DEFAULT 'local' COMMENT '로그인 제공업체 (local/google)',
    `provider_subject` VARCHAR(255) NULL COMMENT '제공업체 고유 ID (구글 ID 등)',
    `created_at` DATETIME NOT NULL COMMENT '가입 일자',
    PRIMARY KEY (`customer_seq`),
    KEY `idx_provider_subject` (`provider_subject`),
    KEY `idx_provider_subject_combo` (
        `provider`,
        `provider_subject`
    )
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- ---------------------------------------------------------
-- 2) store
-- ---------------------------------------------------------
CREATE TABLE `store` (
    `store_seq` INT NOT NULL AUTO_INCREMENT COMMENT '식당 번호',
    `store_address` VARCHAR(255) NOT NULL COMMENT '주소',
    `store_lat` DOUBLE NOT NULL COMMENT '위도',
    `store_lng` DOUBLE NOT NULL COMMENT '경도',
    `store_phone` VARCHAR(255) NOT NULL COMMENT '전화번호',
    `store_opentime` VARCHAR(255) NULL COMMENT '운영 시작시간 (정보용)',
    `store_closetime` VARCHAR(255) NULL COMMENT '운영 종료시간 (정보용)',
    `store_description` VARCHAR(255) NULL COMMENT '식당 설명',
    `store_image` VARCHAR(255) NULL COMMENT '이미지 URL',
    `store_placement` VARCHAR(255) NOT NULL COMMENT '테이블 배치 정보',
    `created_at` DATETIME NOT NULL COMMENT '생성 일자',
    PRIMARY KEY (`store_seq`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- ---------------------------------------------------------
-- 3) store_table
-- ---------------------------------------------------------
CREATE TABLE `store_table` (
    `store_table_seq` INT NOT NULL AUTO_INCREMENT COMMENT '테이블 번호',
    `store_seq` INT NOT NULL COMMENT '식당 번호',
    `store_table_name` INT NOT NULL COMMENT '테이블 이름(라벨)',
    `store_table_capacity` INT NOT NULL COMMENT '수용 인원',
    `store_table_inuse` BOOLEAN NOT NULL COMMENT '사용 중 여부',
    `created_at` DATETIME NOT NULL COMMENT '생성 일자',
    PRIMARY KEY (`store_table_seq`),
    KEY `idx_store_table_store_seq` (`store_seq`),
    CONSTRAINT `fk_store_table_store_seq` FOREIGN KEY (`store_seq`) REFERENCES `store` (`store_seq`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- ---------------------------------------------------------
-- 4) password_reset_auth (비밀번호 변경 인증)
-- ---------------------------------------------------------
CREATE TABLE `password_reset_auth` (
    `auth_seq` INT NOT NULL AUTO_INCREMENT COMMENT '인증 번호',
    `customer_seq` INT NOT NULL COMMENT '고객 번호',
    `auth_token` VARCHAR(255) NOT NULL COMMENT '인증 토큰 (UUID 또는 랜덤 문자열)',
    `auth_code` VARCHAR(6) NULL COMMENT '인증 코드 (6자리 숫자, 선택사항)',
    `expires_at` DATETIME NOT NULL COMMENT '만료 일시',
    `is_verified` BOOLEAN NOT NULL DEFAULT FALSE COMMENT '인증 완료 여부',
    `created_at` DATETIME NOT NULL COMMENT '생성 일시',
    PRIMARY KEY (`auth_seq`),
    KEY `idx_customer_seq` (`customer_seq`),
    KEY `idx_auth_token` (`auth_token`),
    KEY `idx_expires_at` (`expires_at`),
    CONSTRAINT `fk_password_reset_auth_customer_seq` FOREIGN KEY (`customer_seq`) REFERENCES `customer` (`customer_seq`) ON UPDATE RESTRICT ON DELETE CASCADE
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- ---------------------------------------------------------
-- 5) device_token (FCM 토큰)
-- ---------------------------------------------------------
CREATE TABLE `device_token` (
    `device_token_seq` INT NOT NULL AUTO_INCREMENT COMMENT '기기 토큰 번호',
    `customer_seq` INT NOT NULL COMMENT '고객 번호',
    `fcm_token` VARCHAR(255) NOT NULL COMMENT 'FCM 토큰',
    `device_type` VARCHAR(10) NOT NULL COMMENT '기기 타입 (ios/android)',
    `device_id` VARCHAR(255) NULL COMMENT '기기 고유 식별자 (Android: androidId, iOS: identifierForVendor)',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '생성 일시',
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정 일시',
    PRIMARY KEY (`device_token_seq`),
    KEY `idx_fcm_token` (`fcm_token`),
    KEY `idx_device_id` (`device_id`),
    CONSTRAINT `fk_device_token_customer_seq` FOREIGN KEY (`customer_seq`) REFERENCES `customer` (`customer_seq`) ON UPDATE RESTRICT ON DELETE CASCADE,
    UNIQUE KEY `uk_customer_token` (`customer_seq`, `fcm_token`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- ---------------------------------------------------------
-- 6) reserve (weather 테이블 참조 제거됨)
-- ---------------------------------------------------------
-- 변경사항: weather_datetime 컬럼 및 fk_reserve_weather FK 제거
-- 날씨 정보는 OpenWeatherMap API를 통해 실시간으로 조회
CREATE TABLE `reserve` (
    `reserve_seq` INT NOT NULL AUTO_INCREMENT COMMENT '예약 번호',
    `store_seq` INT NOT NULL COMMENT '식당 번호',
    `customer_seq` INT NOT NULL COMMENT '고객 번호',
    `reserve_tables` VARCHAR(255) NOT NULL COMMENT '테이블 번호 목록 (comma-separated)',
    `reserve_capacity` INT NOT NULL COMMENT '예약 인원',
    `reserve_date` DATETIME NOT NULL COMMENT '예약 일시',
    `created_at` DATETIME NOT NULL COMMENT '생성 일자',
    `payment_key` VARCHAR(255) NULL COMMENT 'Toss Payment Key',
    `payment_status` VARCHAR(255) NULL COMMENT '결제 상태',
    PRIMARY KEY (`reserve_seq`),
    KEY `idx_reserve_store_seq` (`store_seq`),
    KEY `idx_reserve_customer_seq` (`customer_seq`),
    CONSTRAINT `fk_reserve_store_seq` FOREIGN KEY (`store_seq`) REFERENCES `store` (`store_seq`) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT `fk_reserve_customer_seq` FOREIGN KEY (`customer_seq`) REFERENCES `customer` (`customer_seq`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- ---------------------------------------------------------
-- 7) menu
-- ---------------------------------------------------------
CREATE TABLE `menu` (
    `menu_seq` INT NOT NULL AUTO_INCREMENT COMMENT '메뉴 번호',
    `store_seq` INT NOT NULL COMMENT '식당 번호',
    `menu_name` VARCHAR(255) NOT NULL COMMENT '메뉴 이름',
    `menu_price` INT NOT NULL COMMENT '메뉴 가격',
    `menu_description` VARCHAR(255) NOT NULL COMMENT '메뉴 설명',
    `menu_image` VARCHAR(255) NOT NULL COMMENT '메뉴 이미지 URL',
    `menu_cost` INT NOT NULL COMMENT '메뉴 원가',
    `created_at` DATETIME NOT NULL COMMENT '생성 일자',
    PRIMARY KEY (`menu_seq`),
    KEY `idx_menu_store_seq` (`store_seq`),
    CONSTRAINT `fk_menu_store_seq` FOREIGN KEY (`store_seq`) REFERENCES `store` (`store_seq`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- ---------------------------------------------------------
-- 8) option
-- ---------------------------------------------------------
CREATE TABLE `option` (
    `option_seq` INT NOT NULL AUTO_INCREMENT COMMENT '추가 메뉴 번호',
    `store_seq` INT NOT NULL COMMENT '식당 번호',
    `menu_seq` INT NOT NULL COMMENT '메뉴 번호',
    `option_name` VARCHAR(255) NOT NULL COMMENT '추가 메뉴 이름',
    `option_price` INT NOT NULL COMMENT '추가 메뉴 가격',
    `option_cost` INT NOT NULL COMMENT '추가 메뉴 원가',
    `created_at` DATETIME NOT NULL COMMENT '생성 일자',
    PRIMARY KEY (`option_seq`),
    KEY `idx_option_store_seq` (`store_seq`),
    KEY `idx_option_menu_seq` (`menu_seq`),
    CONSTRAINT `fk_option_store_seq` FOREIGN KEY (`store_seq`) REFERENCES `store` (`store_seq`) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT `fk_option_menu_seq` FOREIGN KEY (`menu_seq`) REFERENCES `menu` (`menu_seq`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- ---------------------------------------------------------
-- 9) pay
-- ---------------------------------------------------------
CREATE TABLE `pay` (
    `pay_id` INT NOT NULL AUTO_INCREMENT COMMENT '결제 번호',
    `reserve_seq` INT NOT NULL COMMENT '예약 번호',
    `store_seq` INT NOT NULL COMMENT '식당 번호',
    `menu_seq` INT NOT NULL COMMENT '메뉴 번호',
    `option_seq` INT NULL COMMENT '추가 메뉴 번호',
    `pay_quantity` INT NOT NULL COMMENT '수량',
    `pay_amount` INT NOT NULL COMMENT '결제 금액',
    `created_at` DATETIME NOT NULL COMMENT '생성 일자',
    PRIMARY KEY (`pay_id`),
    KEY `idx_pay_reserve_seq` (`reserve_seq`),
    KEY `idx_pay_store_seq` (`store_seq`),
    KEY `idx_pay_menu_seq` (`menu_seq`),
    KEY `idx_pay_option_seq` (`option_seq`),
    CONSTRAINT `fk_pay_reserve_seq` FOREIGN KEY (`reserve_seq`) REFERENCES `reserve` (`reserve_seq`) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT `fk_pay_store_seq` FOREIGN KEY (`store_seq`) REFERENCES `store` (`store_seq`) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT `fk_pay_menu_seq` FOREIGN KEY (`menu_seq`) REFERENCES `menu` (`menu_seq`) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT `fk_pay_option_seq` FOREIGN KEY (`option_seq`) REFERENCES `option` (`option_seq`) ON UPDATE RESTRICT ON DELETE RESTRICT
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

-- ============================================================
-- 생성 이력
-- ============================================================
-- 작성일: 2026-01-21
-- 작성자: 김택권
-- 설명: MySQL 8.0 데이터베이스 초기화 스크립트 v2
--       옵션 A 마이그레이션 적용 - weather 테이블 및 reserve.weather_datetime 컬럼 제거
--       날씨 정보는 OpenWeatherMap API를 통해 실시간으로 조회하도록 변경
--
-- ============================================================
-- 수정 이력
-- ============================================================
-- 2026-01-21 김택권: v2 생성 (옵션 A 마이그레이션)
--   - weather 테이블 삭제
--   - reserve 테이블에서 weather_datetime 컬럼 제거
--   - reserve 테이블에서 fk_reserve_weather FK 제약조건 제거
--   - 테이블 수: 10개 → 9개
