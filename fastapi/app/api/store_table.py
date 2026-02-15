"""
store_table API - store_table CRUD
개별 실행: python store_table.py

작성자: 이예은     
작성일: 2026.01.15

수정 이력:
| 날짜     | 작성자| 내용 |
|2026.01.15|이예은| 초기 생성 |
|2026.01.16|이예은| APIRouter로 변경, 중복 코드 제거, import 수정 |
|2026.01.19|유다원| 가게별 조회 생성 |
"""

from fastapi import APIRouter, Form
# UploadFile, File, Response는 이미지 기능 구현 시 사용 예정
from pydantic import BaseModel
from typing import Optional
from ..database.connection import connect_db

router = APIRouter()
ipAddress = "127.0.0.1"
port = 8000


# ============================================
# 모델 정의
# ============================================
class StoreTable(BaseModel):
    store_table_seq: Optional[int] = None
    store_seq: Optional[int] = None
    store_table_name: Optional[int] = None  # 스키마상 INT 타입 (주의: 테이블 이름이 INT인 것은 비정상적일 수 있음)
    store_table_capacity: Optional[int] = None
    store_table_inuse: Optional[bool] = None  # 스키마상 BOOLEAN 타입
    created_at: Optional[str] = None


# ============================================
# 전체 조회 (Read All)
# ============================================
@router.get("/select_StoreTables")
async def select_all():
    conn = connect_db()
    curs = conn.cursor()
    
    curs.execute("""
        SELECT store_table_seq, store_seq, store_table_name, store_table_capacity, store_table_inuse, created_at
        FROM store_table 
        ORDER BY store_table_seq
    """)
    
    rows = curs.fetchall()
    conn.close()
    
    result = [{
        'store_table_seq': row[0],
        'store_seq': row[1],
        'store_table_name': row[2],
        'store_table_capacity': row[3], 
        'store_table_inuse': row[4],
        'created_at': row[5]
    } for row in rows]
    
    return {"results": result}


# ============================================
# 가게별 전체 테이블 조회
# ============================================
@router.get("/select_StoreTables_store/{store_seq}")
async def select_all(store_seq:int):
    conn = connect_db()
    curs = conn.cursor()
    
    curs.execute("""
        SELECT store_table_seq, store_seq, store_table_name, store_table_capacity, store_table_inuse, created_at
        FROM store_table
        WHERE store_seq = %s 
        ORDER BY store_table_seq
    """,(store_seq))
    
    rows = curs.fetchall()
    conn.close()
    
    result = [{
        'store_table_seq': row[0],
        'store_seq': row[1],
        'store_table_name': row[2],
        'store_table_capacity': row[3], 
        'store_table_inuse': row[4],
        'created_at': row[5]
    } for row in rows]
    
    return {"results": result}


# ============================================
# 단일 조회 (Read One)
# ============================================
@router.get("/select_StoreTable/{store_table_seq}")
async def select_one(store_table_seq: int):
    conn = connect_db()
    curs = conn.cursor()
    
    curs.execute("""
        SELECT store_table_seq, store_seq, store_table_name, store_table_capacity, store_table_inuse, created_at
        FROM store_table
        WHERE store_table_seq = %s
    """, (store_table_seq,))
    
    row = curs.fetchone()
    conn.close()
    
    if row is None:
        return {"result": "Error", "message": "StoreTable not found"}
    
    result = {
        'store_table_seq': row[0],
        'store_seq': row[1],
        'store_table_name': row[2],
        'store_table_capacity': row[3], 
        'store_table_inuse': row[4],
        'created_at': row[5]
    }
    return {"result": result}


# ============================================
# 추가 (Create)
# ============================================
@router.post("/insert_StoreTable")
async def insert_one(
    store_seq: int = Form(...),
    store_table_name: int = Form(...),  # 스키마상 INT 타입
    store_table_capacity: int = Form(...), 
    store_table_inuse: bool = Form(...),  # 스키마상 BOOLEAN 타입
    # created_at은 DB에서 NOW()로 자동 생성되므로 제거
):
    try:
        conn = connect_db()
        curs = conn.cursor()
        
        sql = """
            INSERT INTO store_table (store_seq, store_table_name, store_table_capacity, store_table_inuse, created_at) 
            VALUES (%s, %s, %s, %s, NOW())
        """
        curs.execute(sql, (store_seq, store_table_name, store_table_capacity, store_table_inuse))
        
        conn.commit()
        inserted_id = curs.lastrowid
        conn.close()
        
        return {"result": "OK", "id": inserted_id}
    except Exception as e:
        return {"result": "Error", "errorMsg": str(e)}


# ============================================
# 수정 (Update)
# ============================================
@router.post("/update_StoreTable")
async def update_one(
    store_table_seq: int = Form(...),
    store_seq: int = Form(...),
    store_table_name: int = Form(...),  # 스키마상 INT 타입
    store_table_capacity: int = Form(...),
    store_table_inuse: Optional[bool] = Form(None),  # 스키마상 BOOLEAN 타입
    # created_at은 일반적으로 수정하지 않으므로 제거
):
    try:
        conn = connect_db()
        curs = conn.cursor()
        
        sql = """
            UPDATE store_table 
            SET store_seq=%s, store_table_name=%s, store_table_capacity=%s, store_table_inuse=%s
            WHERE store_table_seq=%s 
        """
        curs.execute(sql, (store_seq, store_table_name, store_table_capacity, store_table_inuse, store_table_seq))
        
        conn.commit()
        conn.close()
        
        return {"result": "OK"}
    except Exception as e:
        return {"result": "Error", "errorMsg": str(e)}


# ============================================
# 삭제 (Delete)
# ============================================
@router.delete("/delete_StoreTable/{store_table_seq}")
async def delete_one(store_table_seq: int):
    try:
        conn = connect_db()
        curs = conn.cursor()
        
        sql = "DELETE FROM store_table WHERE store_table_seq=%s"
        curs.execute(sql, (store_table_seq,))
        
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
# @router.get("/view_[테이블명]_image/{item_id}")
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
# @router.post("/update_[테이블명]_image")
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
# 개별 실행 (테스트용)
# ============================================
# 주의: router는 main.py에서 등록되므로 개별 실행 시 FastAPI 앱 생성 필요
if __name__ == "__main__":
    from fastapi import FastAPI
    import uvicorn
    
    app = FastAPI()
    app.include_router(router, prefix="/api/store_table", tags=["store_table"])
    
    print(f"🚀 StoreTable API 서버 시작")
    print(f"   서버 주소: http://{ipAddress}:{port}")
    print(f"   Swagger UI: http://{ipAddress}:{port}/docs")
    uvicorn.run(app, host=ipAddress, port=port)
