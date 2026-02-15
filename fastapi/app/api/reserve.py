"""
reserve API - reserve CRUD
개별 실행: python [파일명].py

작성자: 유다원
작성일: 2026.01.15

수정 이력:
| 날짜 | 작성자 | 내용 |
|———--|———---|———--|
|2026.01.15|유다원|생성|
|2026.01.21|김택권|weather_datetime 컬럼 제거 (weather 테이블 마이그레이션)|
"""

from datetime import datetime, timedelta
from fastapi import APIRouter, FastAPI, Form, UploadFile, File, Response
from pydantic import BaseModel
from typing import Optional
from ..database.connection import connect_db

router = APIRouter()
ipAddress = "127.0.0.1"
port = 8000


# ============================================
# 모델 정의
# ============================================
# TODO: 테이블 컬럼에 맞게 모델 정의
# - id는 Optional[int] = None 으로 정의 (자동 생성)
# - 필수 컬럼은 타입만 지정 (예: cEmail: str)
# - 선택 컬럼은 Optional로 지정 (예: cProfileImage: Optional[bytes] = None)
class YourModel(BaseModel):
    id: Optional[int] = None
    # TODO: 컬럼 추가


# ============================================
# 전체 조회 (Read All)
# ============================================
# TODO: 전체 목록 조회 API 구현
# - 이미지 BLOB 컬럼은 제외하고 조회
# - ORDER BY id 정렬
@router.get("/select_reserves")
async def select_all():
    conn = connect_db()
    curs = conn.cursor()
    
    # TODO: SQL 작성
    curs.execute("""
        SELECT reserve_seq, store_seq, customer_seq, reserve_tables, reserve_capacity, reserve_date, created_at, payment_key, payment_status 
        FROM reserve 
        ORDER BY reserve_seq
    """)
    
    rows = curs.fetchall()
    conn.close()
    
    # TODO: 결과 매핑
    result = [{
        'reserve_seq': row[0],
        'store_seq': row[1],
        'customer_seq': row[2],
        'reserve_tables': row[3],
        'reserve_capacity': row[4],
        'reserve_date': row[5],
        'created_at': row[6],
        'payment_key': row[7],
        'payment_status': row[8]
        # …
    } for row in rows]
    
    return {"results": result}


# ============================================
# 8일 조회
# ============================================
# TODO: 전체 목록 조회 API 구현
# - 이미지 BLOB 컬럼은 제외하고 조회
# - ORDER BY id 정렬

@router.get("/select_reserves_8/{date}")
async def select_all_8(date: str):
    conn = connect_db()
    curs = conn.cursor()

    dt = datetime.strptime(date, "%Y-%m-%d")
    dt_plus_7 = dt + timedelta(days=7)

    start_dt = dt.strftime("%Y-%m-%d 00:00:00")
    end_dt = dt_plus_7.strftime("%Y-%m-%d 23:59:59")

    curs.execute("""
        SELECT reserve_seq, store_seq, customer_seq,
               reserve_tables,
               reserve_capacity, reserve_date,
               created_at, payment_key, payment_status
        FROM reserve
        WHERE reserve_date BETWEEN %s AND %s
        ORDER BY reserve_seq
    """, (start_dt, end_dt))

    rows = curs.fetchall()
    conn.close()

    return {
        "results": [
            {
                'reserve_seq': row[0],
                'store_seq': row[1],
                'customer_seq': row[2],
                'reserve_tables': row[3],
                'reserve_capacity': row[4],
                'reserve_date': row[5],
                'created_at': row[6],
                'payment_key': row[7],
                'payment_status': row[8]
            } for row in rows
        ]
    }


# ============================================
# 8일 조회, 가게 한 개만
# ============================================
# TODO: 전체 목록 조회 API 구현
# - 이미지 BLOB 컬럼은 제외하고 조회
# - ORDER BY id 정렬

@router.get("/select_reserves_8_store/{date}/{seq}")
async def select_all_8_store(date: str, seq: int):
    conn = connect_db()
    curs = conn.cursor()

    dt = datetime.strptime(date, "%Y-%m-%d")
    dt_plus_7 = dt + timedelta(days=7)

    start_dt = dt.strftime("%Y-%m-%d 00:00:00")
    end_dt = dt_plus_7.strftime("%Y-%m-%d 23:59:59")

    curs.execute("""
        SELECT reserve_seq, store_seq, customer_seq,
               reserve_tables,
               reserve_capacity, reserve_date,
               created_at, payment_key, payment_status
        FROM reserve
        WHERE store_seq = %s
        AND reserve_date BETWEEN %s AND %s
        ORDER BY reserve_seq
    """, (seq, start_dt, end_dt))

    rows = curs.fetchall()
    conn.close()

    return {
        "results": [
            {
                'reserve_seq': row[0],
                'store_seq': row[1],
                'customer_seq': row[2],
                'reserve_tables': row[3],
                'reserve_capacity': row[4],
                'reserve_date': row[5],
                'created_at': row[6],
                'payment_key': row[7],
                'payment_status': row[8]
            } for row in rows
        ]
    }


# ============================================
# 단일 조회 (Read One)
# ============================================
# TODO: ID로 단일 조회 API 구현
# - 존재하지 않으면 에러 응답
@router.get("/select_reserve/{item_id}")
async def select_one(item_id: int):
    conn = connect_db()
    curs = conn.cursor()
    
    # TODO: SQL 작성
    curs.execute("""
        SELECT reserve_seq, store_seq, customer_seq, reserve_tables, reserve_capacity, reserve_date, created_at, payment_key, payment_status 
        FROM reserve 
        WHERE reserve_seq = %s
    """, (item_id,))
    
    row = curs.fetchone()
    conn.close()
    
    if row is None:
        return {"result": "Error", "message": "reserve not found"}
    
    # TODO: 결과 매핑
    result = {
        'reserve_seq': row[0],
        'store_seq': row[1],
        'customer_seq': row[2],
        'reserve_tables': row[3],
        'reserve_capacity': row[4],
        'reserve_date': row[5],
        'created_at': row[6],
        'payment_key': row[7],
        'payment_status': row[8]
    }
    return {"result": result}


# ============================================
# 추가 (Create)
# ============================================
# TODO: 새 레코드 추가 API 구현
# - Form 데이터로 받기: 파라미터 = Form(...)
# - 성공 시 생성된 ID 반환
# - 에러 처리 필수
@router.post("/insert_reserve")
async def insert_one(
    # TODO: Form 파라미터 정의
    # 예: columnName: str = Form(...)
    store_seq: int = Form(...),
    customer_seq: int = Form(...),
    reserve_tables: str = Form(...),
    reserve_capacity: int = Form(...),
    reserve_date: str = Form(...),
    payment_key: Optional[str] = Form(None),
    payment_status: Optional[str] = Form(None)
):
    try:
        conn = connect_db()
        curs = conn.cursor()
        
        # TODO: SQL 작성
        sql = """
            INSERT INTO reserve (store_seq, customer_seq, reserve_tables, reserve_capacity, reserve_date, created_at, payment_key, payment_status) 
            VALUES (%s, %s, %s, %s, %s, NOW(), %s, %s)
        """
        curs.execute(sql, (store_seq, customer_seq, reserve_tables, reserve_capacity, reserve_date, payment_key, payment_status))
        
        conn.commit()
        inserted_id = curs.lastrowid
        conn.close()
        
        return {"result": "OK", "id": inserted_id}
    except Exception as e:
        return {"result": "Error", "errorMsg": str(e)}


# ============================================
# 수정 (Update)
# ============================================
# TODO: 레코드 수정 API 구현
# - 이미지 BLOB이 있는 경우: 이미지 제외/포함 두 가지 API 구현 권장
@router.post("/update_reserve")
async def update_one(
    reserve_seq: int = Form(...),
    store_seq: int = Form(...),
    customer_seq: int = Form(...),
    reserve_tables: str = Form(...),
    reserve_capacity: int = Form(...),
    reserve_date: str = Form(...),
    payment_key: Optional[str] = Form(None),
    payment_status: Optional[str] = Form(None)
    # TODO: 수정할 Form 파라미터 정의
):
    try:
        conn = connect_db()
        curs = conn.cursor()
        
        # TODO: SQL 작성
        sql = """
            UPDATE reserve 
            SET store_seq=%s, customer_seq=%s, reserve_tables=%s, reserve_capacity=%s, reserve_date=%s, payment_key=%s, payment_status=%s     
            WHERE reserve_seq=%s
        """
        curs.execute(sql, (store_seq, customer_seq, reserve_tables, reserve_capacity, reserve_date, payment_key, payment_status, reserve_seq))
        
        conn.commit()
        conn.close()
        
        return {"result": "OK"}
    except Exception as e:
        return {"result": "Error", "errorMsg": str(e)}


# ============================================
# 삭제 (Delete)
# ============================================
# TODO: 레코드 삭제 API 구현
# - FK 참조 시 삭제 실패할 수 있음 (에러 처리)
@router.delete("/delete_reserve/{item_id}")
async def delete_one(item_id: int):
    try:
        conn = connect_db()
        curs = conn.cursor()
        
        sql = "DELETE FROM reserve WHERE reserve_seq=%s"
        curs.execute(sql, (item_id,))
        
        conn.commit()
        conn.close()
        
        return {"result": "OK"}
    except Exception as e:
        return {"result": "Error", "errorMsg": str(e)}


# ============================================
# [선택] 이미지 조회 (이미지 BLOB 컬럼이 있는 경우)
# ============================================
# TODO: 이미지 바이너리 직접 반환
# - Response 객체 사용
# - media_type: "image/jpeg" 또는 "image/png"
# @app.get("/view_[테이블명]_image/{item_id}")
# async def view_image(item_id: int):
#     try:
#         conn = connect_db()
#         curs = conn.cursor()
#         curs.execute("SELECT [이미지컬럼] FROM [테이블명] WHERE id = %s", (item_id,))
#         row = curs.fetchone()
#         conn.close()
#         
#         if row is None:
#             return {"result": "Error", "message": "Not found"}
#         
#         if row[0] is None:
#             return {"result": "Error", "message": "No image"}
#         
#         return Response(
#             content=row[0],
#             media_type="image/jpeg",
#             headers={"Cache-Control": "no-cache"}
#         )
#     except Exception as e:
#         return {"result": "Error", "errorMsg": str(e)}


# ============================================
# [선택] 이미지 업데이트 (이미지 BLOB 컬럼이 있는 경우)
# ============================================
# TODO: 이미지만 별도로 업데이트
# - UploadFile = File(...) 사용
# @app.post("/update_[테이블명]_image")
# async def update_image(
#     item_id: int = Form(...),
#     file: UploadFile = File(...)
# ):
#     try:
#         image_data = await file.read()
#         
#         conn = connect_db()
#         curs = conn.cursor()
#         sql = "UPDATE [테이블명] SET [이미지컬럼]=%s WHERE id=%s"
#         curs.execute(sql, (image_data, item_id))
#         conn.commit()
#         conn.close()
#         
#         return {"result": "OK"}
#     except Exception as e:
#         return {"result": "Error", "errorMsg": str(e)}


# ============================================
# 개별 실행
# ============================================
if __name__ == "__main__":
    import uvicorn
    print(f"🚀 [테이블명] API 서버 시작")
    print(f"   서버 주소: http://{ipAddress}:{port}")
    print(f"   Swagger UI: http://{ipAddress}:{port}/docs")
    uvicorn.run(router, host=ipAddress, port=port)
