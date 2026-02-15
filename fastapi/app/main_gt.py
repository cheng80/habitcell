"""
Table Now FastAPI 메인 애플리케이션
기본 구조만 포함하며, 엔드포인트는 나중에 추가할 수 있도록 설계
작성일: 2026-01-15
작성자: 김택권
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
import os

# .env 파일에서 환경변수 로드
# fastapi 폴더의 .env 파일을 읽습니다
env_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), '.env')
load_dotenv(dotenv_path=env_path)

# 데이터베이스 연결 (필요시 주석 해제)
# from app.database.connection import connect_db

app = FastAPI(
    title="Table Now API",
    description="Table Now 애플리케이션을 위한 REST API",
    version="1.0.0"
)

# CORS 설정 (Flutter 앱과 통신을 위해 필요)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 개발 환경용, 프로덕션에서는 특정 도메인으로 제한
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================
# 라우터 등록
# ============================================
# 엔드포인트를 추가할 때 아래와 같이 라우터를 등록하세요:
#
# from app.api import example_router
# app.include_router(example_router.router, prefix="/api/example", tags=["example"])

# API 라우터 import 및 등록
from app.api import customer, weather, menu, option, store, reserve, store_table, payment

# Customer API 라우터 등록
app.include_router(customer.router, prefix="/api/customer", tags=["customer"])

# Weather API 라우터 등록
app.include_router(weather.router, prefix="/api/weather", tags=["weather"])

# Menu API 라우터 등록 : 임소연
app.include_router(menu.router, prefix="/api/menu", tags=["menu"])

# Option API 라우터 등록 : 임소연
app.include_router(option.router, prefix="/api/option", tags=["option"])

# Pay API 라우터 등록 : 이광태
app.include_router(payment.router, prefix="/api/pay", tags=["pay"])

# Store API 라우터 등록 : 유다원
app.include_router(store.router, prefix="/api/store", tags=["store"])

# Reserve API 라우터 등록 : 유다원
app.include_router(reserve.router, prefix="/api/reserve", tags=["reserve"])

# StoreTable API 라우터 등록 : 이예은
app.include_router(store_table.router, prefix="/api/store_table", tags=["store_table"])

@app.get("/")
async def root():
    """루트 엔드포인트 - API 정보 반환"""
    return {
        "message": "Table Now API",
        "status": "running",
        "version": "1.0.0",
        "endpoints": {
            "health": "/health",
            "docs": "/docs",
            "redoc": "/redoc"
        }
    }


@app.get("/health")
async def health_check():
    """헬스 체크 엔드포인트"""
    # 데이터베이스 연결이 필요할 때 주석 해제
    # try:
    #     conn = connect_db()
    #     conn.close()
    #     return {"status": "healthy", "database": "connected"}
    # except Exception as e:
    #     return {"status": "unhealthy", "error": str(e)}
    
    return {
        "status": "healthy",
        "message": "API is running"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)


# ============================================================
# 생성 이력
# ============================================================
# 작성일: 2026-01-15
# 작성자: 김택권
# 설명: Table Now FastAPI 메인 애플리케이션 - FastAPI 앱 초기화 및 라우터 등록
#
# ============================================================
# 수정 이력
# ============================================================
# 2026-01-15 김택권: 초기 생성
#   - FastAPI 앱 초기화 및 기본 설정
#   - CORS 미들웨어 설정 (Flutter 앱과 통신을 위해)
#   - .env 파일에서 환경변수 로드 (dotenv)
#   - Customer API 라우터 등록 (/api/customer)
#   - 루트 엔드포인트 및 헬스 체크 엔드포인트 구현
#
# 2026-01-15 김택권: Weather API 라우터 등록
#   - Weather API 라우터 등록 (/api/weather)
#   - 날씨 데이터 조회 및 OpenWeatherMap API 연동 기능 추가
#
# 2026-01-15 임소연: Menu 및 Option API 라우터 등록
#   - Menu API 라우터 등록 (/api/menu)
#   - Option API 라우터 등록 (/api/option)
#
# 2026-01-15 유다원: Store 및 Reserve API 라우터 등록
#   - Store API 라우터 등록 (/api/store)
#   - Reserve API 라우터 등록 (/api/reserve)
#
# 2026-01-16 이예은: StoreTable API 라우터 등록
#   - StoreTable API 라우터 등록 (/api/store_table)