"""
store API - store CRUD
개별 실행: python store.py

작성자: 유다원
작성일: 2026.01.15

수정 이력:
| 날짜 | 작성자 | 내용 |
|———--|———---|———--|
|2026.01.15|유다원|생성|
"""

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
@router.get("/select_stores")
async def select_all():
    conn = connect_db()
    curs = conn.cursor()
    
    # TODO: SQL 작성
    curs.execute("""
        SELECT store_seq, store_address, store_lat, store_lng, store_phone, store_opentime, store_closetime, store_description, store_image, store_placement, created_at
        FROM store
        ORDER BY store_seq
    """)
    
    rows = curs.fetchall()
    conn.close()
    
    # TODO: 결과 매핑
    result = [{
        'store_seq': row[0],
        'store_address': row[1],
        'store_lat': row[2],
        'store_lng': row[3],
        'store_phone': row[4],
        'store_opentime': row[5],
        'store_closetime': row[6],
        'store_description': row[7],
        'store_image': row[8],
        'store_placement': row[9],
        'created_at': row[10]
        # …
    } for row in rows]
    
    return {"results": result}


# ============================================
# 단일 조회 (Read One)
# ============================================
# TODO: ID로 단일 조회 API 구현
# - 존재하지 않으면 에러 응답
@router.get("/select_store/{item_id}")
async def select_one(item_id: int):
    conn = connect_db()
    curs = conn.cursor()
    
    # TODO: SQL 작성
    curs.execute("""
        SELECT store_seq, store_address, store_lat, store_lng, store_phone, store_opentime, store_closetime, store_description, store_image, store_placement, created_at
        FROM store 
        WHERE store_seq = %s
    """, (item_id,))
    
    row = curs.fetchone()
    conn.close()
    
    if row is None:
        return {"result": "Error", "message": "store not found"}
    
    # TODO: 결과 매핑
    result = {
        'store_seq': row[0],
        'store_address': row[1],
        'store_lat': row[2],
        'store_lng': row[3],
        'store_phone': row[4],
        'store_opentime': row[5],
        'store_closetime': row[6],
        'store_description': row[7],
        'store_image': row[8],
        'store_placement': row[9],
        'created_at': row[10]
    }
    return {"result": result}


# ============================================
# 추가 (Create)
# ============================================
# TODO: 새 레코드 추가 API 구현
# - Form 데이터로 받기: 파라미터 = Form(...)
# - 성공 시 생성된 ID 반환
# - 에러 처리 필수
@router.post("/insert_store")
async def insert_one(
    # TODO: Form 파라미터 정의
    # 예: columnName: str = Form(...)
    store_address: str = Form(...),
    store_lat: float = Form(...),
    store_lng: float = Form(...),
    store_phone: str = Form(...),
    store_opentime: Optional[str] = Form(None),
    store_closetime: Optional[str] = Form(None),
    store_description: Optional[str] = Form(None),
    store_image: Optional[str] = Form(None),
    store_placement: str = Form(...)
):
    try:
        conn = connect_db()
        curs = conn.cursor()
        
        # TODO: SQL 작성
        sql = """
            INSERT INTO store (store_address, store_lat, store_lng, store_phone, store_opentime, store_closetime, store_description, store_image, store_placement, created_at) 
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, NOW())
        """
        curs.execute(sql, (store_address, store_lat, store_lng, store_phone, store_opentime, store_closetime, store_description, store_image, store_placement))
        
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
@router.post("/update_store")
async def update_one(
    store_seq: int = Form(...),
    store_address: str = Form(...),
    store_lat: float = Form(...),
    store_lng: float = Form(...),
    store_phone: str = Form(...),
    store_opentime: Optional[str] = Form(None),
    store_closetime: Optional[str] = Form(None),
    store_description: Optional[str] = Form(None),
    store_image: Optional[str] = Form(None),
    store_placement: str = Form(...)
    # TODO: 수정할 Form 파라미터 정의
):
    try:
        conn = connect_db()
        curs = conn.cursor()
        
        # TODO: SQL 작성
        sql = """
            UPDATE store 
            SET store_address=%s, store_lat=%s, store_lng=%s, store_phone=%s, store_opentime=%s, store_closetime=%s, store_description=%s, store_image=%s, store_placement=%s
            WHERE store_seq=%s
        """
        curs.execute(sql, (store_address, store_lat, store_lng, store_phone, store_opentime, store_closetime, store_description, store_image, store_placement, store_seq))
        
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
@router.delete("/delete_store/{item_id}")
async def delete_one(item_id: int):
    try:
        conn = connect_db()
        curs = conn.cursor()
        
        sql = "DELETE FROM store WHERE store_seq=%s"
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