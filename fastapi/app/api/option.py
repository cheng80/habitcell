"""
option API - 옵션 CRUD
개별 실행: python option.py

작성자: 임소연
작성일: 2026-01-15

수정 이력:
| 날짜 | 작성자 | 내용 |
|------|--------|------|
| 2026-01-15 | 임소연 | 최초 생성 |
| 2026-01-16 | 임소연 | 상대경로 |
"""

from fastapi import APIRouter, Form, UploadFile, File, Response
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from ..database.connection import connect_db

router = APIRouter()
ipAddress = "127.0.0.1"
port = 8000


# ============================================
# 전체 조회 (Read All)
# ============================================
# TODO: 전체 목록 조회 API 구현
# - 이미지 BLOB 컬럼은 제외하고 조회
# - ORDER BY id 정렬
@router.get("/select_option")
async def select_all():
    conn = connect_db()
    curs = conn.cursor()
    
    # TODO: SQL 작성
    curs.execute("""
        SELECT option_seq, store_seq, menu_seq, option_name, option_price, option_cost, created_at 
        FROM table_now_db.option 
        ORDER BY option_seq
    """)
    
    rows = curs.fetchall()
    conn.close()
    
    # TODO: 결과 매핑
    result = [{
        'option_seq': row[0],
        'store_seq': row[1],
        'menu_seq': row[2],
        'option_name': row[3],
        'option_price': row[4],
        'option_cost': row[5],
        'created_at': row[6]
    } for row in rows]
    
    return {"results": result}


# ============================================
# 단일 조회 (Read One)
# ============================================
# TODO: ID로 단일 조회 API 구현
# - 존재하지 않으면 에러 응답
@router.get("/select_option/{store_seq}/{menu_seq}")
async def select_one(store_seq: int, menu_seq: int):
    conn = connect_db()
    curs = conn.cursor()
    
    # TODO: SQL 작성
    curs.execute("""
        SELECT option_seq, store_seq, menu_seq, option_name, option_price, option_cost, created_at 
        FROM table_now_db.option 
        WHERE store_seq = %s and menu_seq = %s
        ORDER BY option_seq
    """, (store_seq, menu_seq))
    
    rows = curs.fetchall()
    conn.close()
    
    # TODO: 결과 매핑
    result = [{
        'option_seq': row[0],
        'store_seq': row[1],
        'menu_seq': row[2],
        'option_name': row[3],
        'option_price': row[4],
        'option_cost': row[5],
        'created_at': row[6]
    } for row in rows]
    return {"result": result}


# ============================================
# 추가 (Create)
# ============================================
# TODO: 새 레코드 추가 API 구현
# - Form 데이터로 받기: 파라미터 = Form(...)
# - 성공 시 생성된 ID 반환
# - 에러 처리 필수
@router.post("/insert_option")
async def insert_one(
    store_seq: int = Form(...),
    menu_seq: int = Form(...),
    option_name: str = Form(...),
    option_price: int = Form(...),
    option_cost: int = Form(...),
    created_at: str = Form(...), # ISO format string
):
    try:
        created_at_dt = None
        if created_at:
            created_at_dt = datetime.fromisoformat(created_at.replace('Z', '+00:00'))

        conn = connect_db()
        curs = conn.cursor()
        
        # TODO: SQL 작성
        sql = """
            INSERT INTO table_now_db.option (store_seq, menu_seq, option_name, option_price, option_cost, created_at) 
            VALUES (%s, %s, %s, %s, %s, %s)
        """
        curs.execute(sql, (store_seq, menu_seq, option_name, option_price, option_cost, created_at_dt))
        
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
@router.post("/update_option")
async def update_one(
    option_seq: int = Form(...),
    store_seq: int = Form(...),
    menu_seq: int = Form(...),
    option_name: str = Form(...),
    option_price: int = Form(...),
    option_cost: int = Form(...),
    created_at: str = Form(...), # ISO format string
):
    try:
        created_at_dt = None
        if created_at:
            created_at_dt = datetime.fromisoformat(created_at.replace('Z', '+00:00'))

        conn = connect_db()
        curs = conn.cursor()
        
        # TODO: SQL 작성
        sql = """
            UPDATE table_now_db.option 
            SET store_seq=%s, menu_seq=%s, option_name=%s, option_price=%s, option_cost=%s, created_at=%s 
            WHERE option_seq=%s
        """
        curs.execute(sql, (store_seq, menu_seq, option_name, option_price, option_cost, created_at_dt, option_seq))
        
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
@router.delete("/delete_option/{item_id}")
async def delete_one(item_id: int):
    try:
        conn = connect_db()
        curs = conn.cursor()
        
        sql = "DELETE FROM table_now_db.option WHERE id=%s"
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
    print(f"🚀 option API 서버 시작")
    print(f"   서버 주소: http://{ipAddress}:{port}")
    print(f"   Swagger UI: http://{ipAddress}:{port}/docs")
    uvicorn.run(router, host=ipAddress, port=port)