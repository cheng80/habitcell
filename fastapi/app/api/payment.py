
from fastapi import APIRouter, Form
from pydantic import BaseModel
from typing import Optional
from datetime import datetime, timedelta
import uuid
import random
from ..database.connection import connect_db

# encrypt package
from Crypto.Cipher import AES
from Crypto.Random import get_random_bytes
from Crypto.Util.Padding import pad, unpad
import base64

# 라우터 생성
router = APIRouter()

class Payment(BaseModel):
    pay_id: Optional[int] = None
    reserve_seq: int
    store_seq: int
    menu_seq: int
    option_seq: int
    pay_quantity: int
    pay_amount: int
    created_at: datetime



# ============================================
# Purchase 수정 (Update)
# ============================================
@router.post("/purchase/update")
async def update_one(data:dict):
    try:
        conn = connect_db()
        curs = conn.cursor()
        
        sql = """
            UPDATE reserve 
            SET payment_key=%s, payment_status=%s     
            WHERE reserve_seq=%s
        """
        curs.execute(sql, (data['payment_key'], data['payment_status'], data['reserve_seq']))
        
        conn.commit()
        conn.close()
        
        return {"result": "OK"}
    except Exception as e:
        return {"result": "Error", "errorMsg": str(e)}

@router.post("/insert_reserve")
async def create_reserve(reserve:dict) :
    created_at =  datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    reserveData = (
        reserve['store_seq'],
        reserve['customer_seq'],
        reserve['reserve_tables'],
        reserve['reserve_capacity'],
        reserve['reserve_date'],
        created_at,
        reserve['payment_key'],
        reserve['payment_status']   
    )
    returnData = {"result": "Error"}
    conn = connect_db()
    try:
        curs = conn.cursor()

        ### Reserve 추가하기
        curs.execute("""
        insert into reserve(
            store_seq,customer_seq,
            reserve_tables,
            reserve_capacity,reserve_date,created_at,
            payment_key,payment_status
        ) values (%s,%s,%s,%s,%s,%s,%s,%s)
    """,reserveData)
        inserted_id = curs.lastrowid
        conn.commit()
        returnData = {"result": {"reserve_seq":inserted_id}}
    except Exception as err:
        import traceback
        error_msg = str(err)
        traceback.print_exc()
        returnData = {"result": "Error", "errorMsg": error_msg, "traceback": traceback.format_exc()}
    finally:
        conn.close()

    return returnData

@router.post("/purchase")
async def create_purchase(reserve:dict,items: dict):

    created_at =  datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(items['menus'])
    print('=========')
    print(reserve)
    print(datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    returnData = {"results":"Error"}
    if reserve == None or items == None or 'store_seq' not in reserve:
        return returnData
    
    data = []
     
    reserveData = (
        reserve['reserve_seq'],
        reserve['store_seq'],
        reserve['customer_seq'],
        reserve['reserve_tables'],
        reserve['reserve_capacity'],
        reserve['reserve_date'],
        created_at,
        reserve['payment_key'],
        reserve['payment_status']
       
    )
    #  store_table_capacity, store_table_inuse,created_at
    storeTableData=[]
    if reserve['reserve_tables'] != None and reserve['reserve_tables'] != '':
        for v in reserve['reserve_tables'].split(','):
            storeTableData.append((
            reserve['store_seq'],
            v,
            reserve['reserve_capacity'],
            0,
            created_at
        ))

    conn = connect_db()
    try:
        curs = conn.cursor()

        ### Reserve 추가하기
    #     curs.execute("""
    #     insert into reserve(
    #         store_seq,customer_seq,
    #         reserve_tables,
    #         reserve_capacity,reserve_date,created_at,
    #         payment_key,payment_status
    #     ) values (%s,%s,%s,%s,%s,%s,%s,%s)
    # """,reserveData)
    #     inserted_id = curs.lastrowid
        
        ### menu 추가하기전 데이터 만들기
        inserted_id = reserveData[0]
        for m_id, value in items['menus'].items():        
            data.append((inserted_id,reserve['store_seq'],m_id,None,value['count'],value['price'],value['date']))
            if len(value['options']) > 0:
                for k, v in value['options'].items():
                    data.append((inserted_id,reserve['store_seq'],m_id,k,v['count'],v['price'],value['date']))


        ### store table 추가
        if len(storeTableData) > 0 :
            curs.executemany("""
                insert into store_table(
                    store_seq,store_table_name,
                    store_table_capacity, store_table_inuse,
                    created_at
                ) values (%s,%s,%s,%s,%s)
            """,storeTableData)

        ### pay table 추가
        curs.executemany("""
           insert into pay(reserve_seq,store_seq,menu_seq,option_seq,pay_quantity,pay_amount,created_at) 
                    values (%s,%s,%s,%s,%s,%s,%s)
        """,data)

        conn.commit()
        returnData = {"results": {"reserve_seq":inserted_id}}
    
    except Exception as e:
        ### commit실패시 rollback
        conn.rollback()

        import traceback
        error_msg = str(e)
        traceback.print_exc()
        returnData = {"results": "Error", "errorMsg": error_msg, "traceback": traceback.format_exc()}
    finally:
        conn.close()
    
    return returnData

@router.get("/")
async def select_pays():


    try:
        conn = connect_db()
        curs = conn.cursor()
        curs.execute("""
        select pay_id,reserve_seq,store_seq,menu_seq,option_seq,pay_quantity,pay_amount,created_at
        from pay
    """)
        rows = curs.fetchall()
        conn.close()
        
        results = []
        for row in rows:
            try:
                created_at = None
                if row[7]:
                    if hasattr(row[7], 'isoformat'):
                        created_at = row[7].isoformat()
                    else:
                        created_at = str(row[7])
                
                results.append({
                    'pay_id': row[0],
                    'reserve_seq': row[1],
                    'store_seq': row[2],
                    'menu_seq': row[3],
                    'option_seq': row[4],
                    'pay_quantity': row[5],
                    'pay_amount': row[6],
                    'created_at' : created_at
                })
            except Exception as e:
                print(f"Error processing row: {e}, row: {row}")
                continue
        
        return {"results": results}
    except Exception as e:
        import traceback
        error_msg = str(e)
        traceback.print_exc()
        return {"results": "Error", "errorMsg": error_msg, "traceback": traceback.format_exc()}


def _encrypt_pay_toss_key():
    try:
        # todo: need to get the KEY and IV from database
        privateKey:bytes = base64.b16encode(b'\xfa\xf9\x8c\x06\xefL9XIdu\x0c-\xe6p\x06')
        # get_random_bytes(16)
        iv = 'This is an IV456'


        # encrypt을 위한 chiper생성 
        cipher = AES.new(privateKey, AES.MODE_CBC,iv.encode('utf8'))
        
        # =========================================
        # todo: this part must hided from here
        # original text to bytes
        # ==========================================
        textBytes =  bytes('test_ck_D5GePWvyJnrK0W0k6q8gLzN97Eoq','utf-8')

        # encryption 
        ciphertext =  base64.b64encode(cipher.encrypt(pad(textBytes,AES.block_size)))       
        return ciphertext
    except Exception as e:
        print(f'ERROR: {e}')
        return ''

def _decrypt_toss_pay_key(key,iv,encrtypedData):
    try:
        decipher = AES.new(key, AES.MODE_CBC, iv)
        decrypted_data = unpad(decipher.decrypt(
            base64.b64decode(encrtypedData)
        ),AES.block_size) 
        return decrypted_data
    except Exception as e:
        print(f'ERROR: {e}')
        return ''


@router.post("/get_toss_client_key")
async def select_pay_toss_key():
    try:
        # todo: need to get the KEY and IV from database
        privateKey:bytes = base64.b16encode(b'\xfa\xf9\x8c\x06\xefL9XIdu\x0c-\xe6p\x06')
        iv = 'This is an IV456'

        return {'result':{'k':privateKey,'iv':base64.b16encode(iv.encode('utf8'))}}
    except Exception as e:
        import traceback
        error_msg = str(e)
        traceback.print_exc()
        return {"result": "Error", "errorMsg": error_msg, "traceback": traceback.format_exc()}



@router.get("/select_group_by_reserve/{reserve_seq}")
async def select_pays_group_by_reserve(reserve_seq: int):
    # if qry['reserve_seq'] == None:
    #     raise Exception("401 Unauthorized: 인증에 실패했습니다.")

    try:
        conn = connect_db()
        curs = conn.cursor()
        curs.execute("""
            select pp.*,m.menu_name ,s.store_description,o.option_name,m.menu_image from 
   (
   select count(p.pay_id) as total_row_count,
                     p.reserve_seq,
                     p.store_seq,
                     p.menu_seq,
                     p.option_seq,
                     sum(p.pay_quantity) as total_quantity,
                     sum(p.pay_amount) as total_amount,
                     sum(p.pay_quantity*p.pay_amount) as total_pay
   from pay p
   where p.reserve_seq =%s
   group by p.reserve_seq, p.store_seq, p.menu_seq, p.option_seq
   order by p.reserve_seq desc
   ) as pp
   inner join menu m on pp.menu_seq=m.menu_seq
   inner join store s on pp.store_seq=s.store_seq
   left join `option` o on pp.option_seq = o.option_seq
    """,[reserve_seq])
        
        rows = curs.fetchall()
        print(len(rows))
        conn.close()
        
        results = []
        for row in rows:
            try:
                
                
                results.append({
                    'total_count': row[0],
                    'reserve_seq': row[1],
                    'store_seq': row[2],
                    'menu_seq': row[3],
                    'option_seq': row[4],
                    'total_quantity': row[5],
                    'total_pay': row[6],
                    'menu_name' : row[8],
                    'store_description': row[9],
                    'option_name': row[10],
                    'menu_image': row[11]
                })
            except Exception as e:
                print(f"Error processing row: {e}, row: {row}")
                continue
        
        return {"results": results}
    except Exception as e:
        import traceback
        error_msg = str(e)
        traceback.print_exc()
        return {"results": "Error", "errorMsg": error_msg, "traceback": traceback.format_exc()}




@router.get("/select_by_reserve/{reserve_seq}")
async def select_pays_by_reserve(reserve_seq:int):
    # if qry['customer_seq'] == None or qry['reserve_seq'] == None:
    #     raise Exception("401 Unauthorized: 인증에 실패했습니다.")

    try:
        conn = connect_db()
        curs = conn.cursor()
        curs.execute("""
        select pay_id,reserve_seq,store_seq,menu_seq,option_seq,pay_quantity,pay_amount,created_at
        from pay where reserve_seq=%s
    """,[reserve_seq])
        rows = curs.fetchall()
        conn.close()
        
        results = []
        for row in rows:
            try:
                created_at = None
                if row[7]:
                    if hasattr(row[7], 'isoformat'):
                        created_at = row[7].isoformat()
                    else:
                        created_at = str(row[7])
                
                results.append({
                    'pay_id': row[0],
                    'reserve_seq': row[1],
                    'store_seq': row[2],
                    'menu_seq': row[3],
                    'option_seq': row[4],
                    'pay_quantity': row[5],
                    'pay_amount': row[6],
                    'created_at' : created_at
                })
            except Exception as e:
                print(f"Error processing row: {e}, row: {row}")
                continue
        
        return {"results": results}
    except Exception as e:
        import traceback
        error_msg = str(e)
        traceback.print_exc()
        return {"results": "Error", "errorMsg": error_msg, "traceback": traceback.format_exc()}





@router.get("/{id}")
async def get_pay_by_id(id: int):
    
    
    """
    select pay_id,reserve_seq,store_seq,menu_seq,option_seq,pay_quantity,pay_amount,created_at
    from pay where pay.pay_id=?
    [id]
    """
    return {
        "id": id,
        "message": f"Example item with id {id}",
        "status": "success"
    }









@router.post("/insert")
async def create_pay(items: list[dict]):
    conn = connect_db()
    try:
               
        curs = conn.cursor()
        for item in items:
            # print("insert into pay(reserve_seq,store_seq,menu_seq,option_seq,pay_quantity,pay_amount,created_at) values(?,?,?,?,?,?,current_timestamp)",[item['reserve_seq'],item['store_seq'],item['menu_seq'],1,item['pay_quantity'],item['pay_amount']])
            curs.execute("insert into pay(reserve_seq,store_seq,menu_seq,option_seq,pay_quantity,pay_amount,created_at) values(%s,%s,%s,%s,%s,%s,current_timestamp)",(item['reserve_seq'],item['store_seq'],item['menu_seq'],1,item['pay_quantity'],item['pay_amount']))
        conn.commit()

        return {"result": "OK"}
    except Exception as e:
        conn.rollback()
        import traceback
        error_msg = str(e)
        traceback.print_exc()
        return {"results": "Error", "errorMsg": error_msg, "traceback": traceback.format_exc()}
    finally:
        conn.close()


@router.put("/{id}")
async def update_pay(id: int, data: dict):
    """예시 PUT 엔드포인트"""
    return {
        "id": id,
        "message": f"Example item {id} updated",
        "data": data,
        "status": "success"
    }


@router.delete("/{id}")
async def delete_pay(id: int):
    """예시 DELETE 엔드포인트"""
    return {
        "id": id,
        "message": f"Example item {id} deleted",
        "status": "success"
    }

# ============================================================
# 생성 이력
# ============================================================
# 작성일: 2026-01-15
# 작성자: 이광태
# 설명: Pay table CRUD + ecrypt toss client key
#
# ============================================================
# 수정 이력
# ============================================================
# 2026-01-15 이광태: 초기 생성
#   - 기본 CRUD
#   - 에러 처리 및 응답 형식 정의
# 2026-01-17 이광태: ecrypt decrypt 펑션 생성. 
#   - 중복 초기화 코드 제거
#   - application에서 ecrypt된 키를 풀기 위한 decrypt요청 작성
# 2026-01-20
#   - ecrypt/decrypt 관련 소스 정리
#   - flutter에 키/IV를 통해 decrypt되게 설정. 
#   - db에서 값들을 받아아야 하나 현재는 하드코딩으로 처리
#   - purchase 추가 : 데이터를 받아서 각 테이블에 insert