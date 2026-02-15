"""
Customer API - 고객 계정 CRUD 및 인증
회원가입 및 로그인 기능 포함
"""

from fastapi import APIRouter, Form
from pydantic import BaseModel
from typing import Optional
from datetime import datetime, timedelta
import uuid
import random
from ..database.connection import connect_db
try:
    from ..utils.email_service import EmailService
except ImportError:
    # email_service가 없을 경우를 대비한 fallback
    EmailService = None

router = APIRouter()


# ============================================
# 모델 정의
# ============================================
class Customer(BaseModel):
    customer_seq: Optional[int] = None
    customer_name: str
    customer_phone: str
    customer_email: str
    customer_pw: Optional[str] = None  # 조회 시에는 제외
    created_at: Optional[str] = None


class RegisterRequest(BaseModel):
    customer_name: str
    customer_phone: str
    customer_email: str
    customer_pw: str


class LoginRequest(BaseModel):
    customer_email: str
    customer_pw: str


class FCMTokenRequest(BaseModel):
    fcm_token: str
    device_type: str  # "ios" or "android"
    device_id: Optional[str] = None  # 기기 고유 식별자 (Android: androidId, iOS: identifierForVendor)


class PushNotificationRequest(BaseModel):
    """푸시 알림 발송 요청 모델"""
    title: str
    body: str
    data: Optional[dict] = None


# ============================================
# 전체 고객 조회
# ============================================
@router.get("")
async def select_customers():
    """전체 고객 목록을 조회합니다 (비밀번호 제외)."""
    try:
        conn = connect_db()
        curs = conn.cursor()
        curs.execute("""
            SELECT customer_seq, customer_name, customer_phone, customer_email, created_at 
            FROM customer 
            ORDER BY customer_seq
        """)
        rows = curs.fetchall()
        conn.close()
        
        result = []
        for row in rows:
            try:
                created_at = None
                if row[4]:
                    if hasattr(row[4], 'isoformat'):
                        created_at = row[4].isoformat()
                    else:
                        created_at = str(row[4])
                
                result.append({
                    'customer_seq': row[0],
                    'customer_name': row[1],
                    'customer_phone': row[2],
                    'customer_email': row[3],
                    'created_at': created_at
                })
            except Exception as e:
                print(f"Error processing row: {e}, row: {row}")
                continue
        
        return {"results": result}
    except Exception as e:
        import traceback
        error_msg = str(e)
        traceback.print_exc()
        return {"result": "Error", "errorMsg": error_msg, "traceback": traceback.format_exc()}


# ============================================
# FCM 토큰이 등록된 고객 리스트 조회
# ============================================
# 주의: 이 엔드포인트는 /{customer_seq} 보다 앞에 위치해야 합니다
# 그렇지 않으면 FastAPI가 "with-fcm-token"을 customer_seq로 인식하려고 시도합니다
@router.get("/with-fcm-token")
async def get_customers_with_fcm_token():
    """
    FCM 토큰이 등록된 고객 리스트 조회
    - device_token 테이블에 등록된 고객만 반환
    - 고객 정보와 함께 등록된 기기 수도 반환
    """
    conn = connect_db()
    curs = conn.cursor()
    
    try:
        # FCM 토큰이 등록된 고객 조회 (중복 제거, 기기 수 포함)
        # 최근 30일 이내에 업데이트된 토큰만 카운트 (활성 기기만 표시)
        # device_id가 있으면 device_id 기준으로, 없으면 fcm_token 기준으로 카운트
        curs.execute("""
            SELECT DISTINCT
                c.customer_seq,
                c.customer_name,
                c.customer_email,
                c.customer_phone,
                COUNT(DISTINCT COALESCE(dt.device_id, dt.fcm_token)) as device_count
            FROM customer c
            INNER JOIN device_token dt ON c.customer_seq = dt.customer_seq
            WHERE dt.updated_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
            GROUP BY c.customer_seq, c.customer_name, c.customer_email, c.customer_phone
            ORDER BY c.customer_seq
        """)
        
        rows = curs.fetchall()
        
        result = []
        for row in rows:
            result.append({
                'customer_seq': row[0],
                'customer_name': row[1],
                'customer_email': row[2],
                'customer_phone': row[3],
                'device_count': row[4]
            })
        
        return {
            "result": "OK",
            "results": result,
            "total_count": len(result)
        }
        
    except Exception as e:
        import traceback
        error_msg = str(e)
        traceback.print_exc()
        return {
            "result": "Error",
            "errorMsg": error_msg,
            "results": [],
            "total_count": 0
        }
    finally:
        try:
            curs.close()
        except:
            pass
        try:
            conn.close()
        except:
            pass


# ============================================
# ID로 고객 조회
# ============================================
@router.get("/{customer_seq}")
async def select_customer(customer_seq: int):
    """특정 고객을 ID로 조회합니다 (비밀번호 제외)."""
    try:
        conn = connect_db()
        curs = conn.cursor()
        curs.execute("""
            SELECT customer_seq, customer_name, customer_phone, customer_email, 
                   created_at, provider, provider_subject
            FROM customer 
            WHERE customer_seq = %s
        """, (customer_seq,))
        row = curs.fetchone()
        conn.close()
        
        if row is None:
            return {"result": "Error", "message": "Customer not found"}
        
        created_at = None
        if row[4]:
            if hasattr(row[4], 'isoformat'):
                created_at = row[4].isoformat()
            else:
                created_at = str(row[4])
        
        result = {
            'customer_seq': row[0],
            'customer_name': row[1],
            'customer_phone': row[2],
            'customer_email': row[3],
            'created_at': created_at,
            'provider': row[5] if len(row) > 5 else 'local',
            'provider_subject': row[6] if len(row) > 6 else None
        }
        return {"result": result}
    except Exception as e:
        import traceback
        error_msg = str(e)
        traceback.print_exc()
        return {"result": "Error", "errorMsg": error_msg, "traceback": traceback.format_exc()}


# ============================================
# 회원가입
# ============================================
@router.post("/register")
async def register_customer(
    customer_name: str = Form(...),
    customer_phone: Optional[str] = Form(None),  # 선택사항
    customer_email: str = Form(...),
    customer_pw: str = Form(...)
):
    """
    회원가입
    - 이메일 중복 확인
    - 고객 정보 저장
    """
    conn = connect_db()
    curs = conn.cursor()
    
    try:
        # 1. 이메일 중복 확인
        curs.execute("""
            SELECT customer_seq FROM customer WHERE customer_email = %s
        """, (customer_email,))
        existing_customer = curs.fetchone()
        
        if existing_customer:
            return {
                "result": "Error",
                "errorMsg": "이미 사용 중인 이메일입니다."
            }
        
        # 2. 고객 정보 저장
        # TODO: 향후 비밀번호 해시화 필요 (bcrypt 등)
        # 전화번호가 빈 문자열이면 None으로 처리
        phone_value = customer_phone if customer_phone and customer_phone.strip() else None
        curs.execute("""
            INSERT INTO customer (customer_name, customer_phone, customer_email, customer_pw, provider, created_at) 
            VALUES (%s, %s, %s, %s, 'local', NOW())
        """, (customer_name, phone_value, customer_email, customer_pw))
        customer_seq = curs.lastrowid
        
        conn.commit()
        
        return {
            "result": {
                "customer_seq": customer_seq,
                "customer_name": customer_name,
                "customer_phone": customer_phone,
                "customer_email": customer_email,
                "created_at": datetime.now().isoformat()
            },
            "message": "회원가입 성공"
        }
        
    except Exception as e:
        conn.rollback()
        import traceback
        error_msg = str(e)
        traceback.print_exc()
        return {
            "result": "Error",
            "errorMsg": error_msg,
            "traceback": traceback.format_exc()
        }
    finally:
        conn.close()


# ============================================
# 로그인
# ============================================
@router.post("/login")
async def login_customer(
    customer_email: str = Form(...),
    customer_pw: str = Form(...)
):
    """
    로그인
    - 이메일과 비밀번호 확인
    - 로그인 성공 시 고객 정보 반환
    """
    conn = connect_db()
    curs = conn.cursor()
    
    try:
        # 1. 이메일과 비밀번호로 고객 확인 (provider='local'만)
        curs.execute("""
            SELECT customer_seq, customer_name, customer_phone, customer_email, created_at, provider
            FROM customer 
            WHERE customer_email = %s AND customer_pw = %s AND provider = 'local'
        """, (customer_email, customer_pw))
        customer_row = curs.fetchone()
        
        if customer_row is None:
            return {
                "result": "Error",
                "errorMsg": "이메일 또는 비밀번호가 올바르지 않습니다."
            }
        
        # 2. 고객 정보 반환 (비밀번호 제외)
        created_at = None
        if customer_row[4]:
            if hasattr(customer_row[4], 'isoformat'):
                created_at = customer_row[4].isoformat()
            else:
                created_at = str(customer_row[4])
        
        return {
            "result": {
                "customer_seq": customer_row[0],
                "customer_name": customer_row[1],
                "customer_phone": customer_row[2],
                "customer_email": customer_row[3],
                "created_at": created_at,
                "provider": customer_row[5]
            },
            "message": "로그인 성공"
        }
        
    except Exception as e:
        import traceback
        error_msg = str(e)
        traceback.print_exc()
        return {
            "result": "Error",
            "errorMsg": error_msg,
            "traceback": traceback.format_exc()
        }
    finally:
        conn.close()


# ============================================
# 비밀번호 변경 (인증 완료 후)
# ============================================
@router.put("/change-password")
async def change_password(
    customer_seq: int = Form(...),
    new_password: str = Form(...),
    auth_token: str = Form(...)
):
    """
    비밀번호 변경 (인증 완료 후)
    - 인증 토큰 검증
    - 인증 완료 여부 확인
    - 비밀번호 변경
    """
    conn = connect_db()
    curs = conn.cursor()
    
    try:
        # 1. 고객 정보 확인
        curs.execute("""
            SELECT customer_seq, provider FROM customer WHERE customer_seq = %s
        """, (customer_seq,))
        customer = curs.fetchone()
        
        if customer is None:
            return {
                "result": "Error",
                "errorMsg": "고객을 찾을 수 없습니다."
            }
        
        provider = customer[1]
        
        # 2. 구글 계정은 비밀번호 변경 불가
        if provider == 'google':
            return {
                "result": "Error",
                "errorMsg": "구글 로그인 계정은 비밀번호를 변경할 수 없습니다."
            }
        
        # 3. 인증 토큰 검증
        curs.execute("""
            SELECT auth_seq, expires_at, is_verified, customer_seq
            FROM password_reset_auth 
            WHERE auth_token = %s AND customer_seq = %s
            ORDER BY created_at DESC
            LIMIT 1
        """, (auth_token, customer_seq))
        auth_record = curs.fetchone()
        
        if auth_record is None:
            return {
                "result": "Error",
                "errorMsg": "유효하지 않은 인증 토큰입니다."
            }
        
        expires_at = auth_record[1]
        is_verified = auth_record[2]
        
        # 4. 인증 완료 여부 확인
        if not is_verified:
            return {
                "result": "Error",
                "errorMsg": "이메일 인증을 먼저 완료해주세요."
            }
        
        # 5. 만료 시간 확인
        if datetime.now() > expires_at:
            return {
                "result": "Error",
                "errorMsg": "인증이 만료되었습니다. 다시 요청해주세요."
            }
        
        # 6. 현재 비밀번호 확인 (동일한 비밀번호로 변경하는 경우 허용)
        curs.execute("""
            SELECT customer_pw FROM customer WHERE customer_seq = %s
        """, (customer_seq,))
        current_password = curs.fetchone()
        
        if current_password and current_password[0] == new_password:
            # 동일한 비밀번호로 변경하는 경우 허용 (사용자가 원하는 경우)
            # 보안상 경고 메시지는 표시하지 않고 그대로 진행
            pass
        
        # 7. 비밀번호 변경
        # TODO: 향후 비밀번호 해시화 필요 (bcrypt 등)
        curs.execute("""
            UPDATE customer 
            SET customer_pw = %s 
            WHERE customer_seq = %s
        """, (new_password, customer_seq))
        
        # 8. 인증 토큰 삭제 (일회용)
        auth_seq = auth_record[0]
        curs.execute("""
            DELETE FROM password_reset_auth 
            WHERE auth_seq = %s
        """, (auth_seq,))
        
        conn.commit()
        
        return {
            "result": "OK",
            "message": "비밀번호가 성공적으로 변경되었습니다."
        }
        
    except Exception as e:
        conn.rollback()
        import traceback
        error_msg = str(e)
        traceback.print_exc()
        return {
            "result": "Error",
            "errorMsg": error_msg,
            "traceback": traceback.format_exc()
        }
    finally:
        try:
            curs.close()
        except:
            pass
        try:
            conn.close()
        except:
            pass


# ============================================
# 고객 정보 수정
# ============================================
@router.put("/{customer_seq}")
async def update_customer(
    customer_seq: int,
    customer_name: str = Form(...),
    customer_phone: Optional[str] = Form(None),
    customer_email: Optional[str] = Form(None),
    customer_pw: Optional[str] = Form(None)
):
    """
    고객 정보를 수정합니다.
    - 이메일은 선택사항 (제공되지 않으면 기존 이메일 유지)
    - 비밀번호는 선택사항 (변경하지 않으려면 None)
    """
    conn = connect_db()
    curs = conn.cursor()
    
    try:
        # 1. 고객 존재 확인 및 provider 확인
        curs.execute("""
            SELECT customer_seq, provider, customer_email FROM customer WHERE customer_seq = %s
        """, (customer_seq,))
        existing_customer = curs.fetchone()
        
        if existing_customer is None:
            return {
                "result": "Error",
                "errorMsg": "고객을 찾을 수 없습니다."
            }
        
        existing_provider = existing_customer[1]
        existing_email = existing_customer[2]
        
        # 2. 구글 계정은 비밀번호 수정 불가
        if existing_provider == 'google' and customer_pw:
            return {
                "result": "Error",
                "errorMsg": "구글 로그인 계정은 비밀번호를 변경할 수 없습니다."
            }
        
        # 3. 이메일이 제공되지 않으면 기존 이메일 사용
        if customer_email is None or customer_email.strip() == '':
            customer_email = existing_email
        
        # 4. 이메일 중복 확인 (다른 고객이 사용 중인지, 이메일이 변경되는 경우만)
        if customer_email != existing_email:
            curs.execute("""
                SELECT customer_seq FROM customer 
                WHERE customer_email = %s AND customer_seq != %s
            """, (customer_email, customer_seq))
            email_duplicate = curs.fetchone()
            
            if email_duplicate:
                return {
                    "result": "Error",
                    "errorMsg": "이미 사용 중인 이메일입니다."
                }
        
        # 5. 고객 정보 수정 (비밀번호 변경 제외)
        # 비밀번호 변경은 별도 엔드포인트(/change-password) 사용
        curs.execute("""
            UPDATE customer 
            SET customer_name=%s, customer_phone=%s, customer_email=%s 
            WHERE customer_seq=%s
        """, (customer_name, customer_phone, customer_email, customer_seq))
        
        conn.commit()
        
        return {"result": "OK"}
        
    except Exception as e:
        conn.rollback()
        import traceback
        error_msg = str(e)
        traceback.print_exc()
        return {
            "result": "Error",
            "errorMsg": error_msg,
            "traceback": traceback.format_exc()
        }
    finally:
        # 연결 안전하게 닫기
        try:
            curs.close()
        except:
            pass
        try:
            conn.close()
        except:
            pass


# ============================================
# 고객 삭제
# ============================================
@router.delete("/{customer_seq}")
async def delete_customer(customer_seq: int):
    """고객을 삭제합니다."""
    try:
        conn = connect_db()
        curs = conn.cursor()
        
        # 고객 존재 확인
        curs.execute("""
            SELECT customer_seq FROM customer WHERE customer_seq = %s
        """, (customer_seq,))
        existing_customer = curs.fetchone()
        
        if existing_customer is None:
            return {
                "result": "Error",
                "errorMsg": "고객을 찾을 수 없습니다."
            }
        
        # 고객 삭제
        curs.execute("DELETE FROM customer WHERE customer_seq=%s", (customer_seq,))
        conn.commit()
        conn.close()
        
        return {"result": "OK"}
    except Exception as e:
        import traceback
        error_msg = str(e)
        traceback.print_exc()
        return {
            "result": "Error",
            "errorMsg": error_msg,
            "traceback": traceback.format_exc()
        }


# ============================================
# 구글 소셜 로그인
# ============================================
@router.post("/social-login")
async def login_social_customer(
    customer_email: str = Form(...),
    provider_subject: str = Form(...),  # google_id
    customer_name: str = Form(...)
):
    """
    구글 소셜 로그인
    - provider_subject로 기존 구글 계정 조회
    - 없으면 이메일로 local 계정 확인
    - local 계정이 있으면 계정 통합 필요 응답 반환
    - 없으면 신규 구글 계정 생성
    """
    conn = connect_db()
    curs = conn.cursor()
    
    try:
        # 1. provider_subject로 기존 구글 계정 조회
        curs.execute("""
            SELECT customer_seq, customer_name, customer_phone, customer_email, 
                   created_at, provider, provider_subject
            FROM customer 
            WHERE provider_subject = %s AND provider = 'google'
        """, (provider_subject,))
        customer_row = curs.fetchone()
        
        if customer_row:
            # 기존 구글 계정으로 로그인 성공
            created_at = None
            if customer_row[4]:
                if hasattr(customer_row[4], 'isoformat'):
                    created_at = customer_row[4].isoformat()
                else:
                    created_at = str(customer_row[4])
            
            return {
                "result": {
                    "customer_seq": customer_row[0],
                    "customer_name": customer_row[1],
                    "customer_phone": customer_row[2],
                    "customer_email": customer_row[3],
                    "created_at": created_at,
                    "provider": customer_row[5],
                    "provider_subject": customer_row[6]
                },
                "message": "로그인 성공"
            }
        
        # 2. 이메일로 local 계정 확인
        curs.execute("""
            SELECT customer_seq, customer_name, provider 
            FROM customer 
            WHERE customer_email = %s AND provider = 'local'
        """, (customer_email,))
        local_account = curs.fetchone()
        
        if local_account:
            # 기존 local 계정 존재 → 계정 통합 필요
            return {
                "result": "NeedLink",
                "message": "기존 계정이 있습니다. 계정을 통합하시겠습니까?",
                "customer_seq": local_account[0],
                "customer_name": local_account[1]
            }
        
        # 3. 신규 구글 계정 생성
        curs.execute("""
            INSERT INTO customer 
            (customer_name, customer_phone, customer_email, customer_pw, 
             provider, provider_subject, created_at) 
            VALUES (%s, NULL, %s, NULL, 'google', %s, NOW())
        """, (customer_name, customer_email, provider_subject))
        customer_seq = curs.lastrowid
        conn.commit()
        
        return {
            "result": {
                "customer_seq": customer_seq,
                "customer_name": customer_name,
                "customer_phone": None,
                "customer_email": customer_email,
                "created_at": datetime.now().isoformat(),
                "provider": "google",
                "provider_subject": provider_subject
            },
            "message": "회원가입 성공"
        }
        
    except Exception as e:
        conn.rollback()
        import traceback
        error_msg = str(e)
        traceback.print_exc()
        return {
            "result": "Error",
            "errorMsg": error_msg,
            "traceback": traceback.format_exc()
        }
    finally:
        conn.close()


# ============================================
# 구글 계정 통합
# ============================================
@router.post("/link-social")
async def link_social_account(
    customer_seq: int = Form(...),
    provider_subject: str = Form(...),  # google_id
    customer_name: str = Form(...)
):
    """
    기존 local 계정을 구글 계정으로 통합
    - provider를 'google'로 변경
    - provider_subject 저장
    - customer_pw를 NULL로 설정
    - customer_name 업데이트
    """
    conn = connect_db()
    curs = conn.cursor()
    
    try:
        # 1. 고객 존재 확인 및 provider 확인
        curs.execute("""
            SELECT customer_seq, provider 
            FROM customer 
            WHERE customer_seq = %s
        """, (customer_seq,))
        existing_customer = curs.fetchone()
        
        if existing_customer is None:
            return {
                "result": "Error",
                "errorMsg": "고객을 찾을 수 없습니다."
            }
        
        if existing_customer[1] != 'local':
            return {
                "result": "Error",
                "errorMsg": "이미 소셜 로그인 계정입니다."
            }
        
        # 2. provider_subject 중복 확인
        curs.execute("""
            SELECT customer_seq FROM customer 
            WHERE provider_subject = %s AND customer_seq != %s
        """, (provider_subject, customer_seq))
        duplicate = curs.fetchone()
        
        if duplicate:
            return {
                "result": "Error",
                "errorMsg": "이미 사용 중인 구글 계정입니다."
            }
        
        # 3. 계정 통합 처리
        curs.execute("""
            UPDATE customer 
            SET provider = 'google',
                provider_subject = %s,
                customer_pw = NULL,
                customer_name = %s
            WHERE customer_seq = %s
        """, (provider_subject, customer_name, customer_seq))
        conn.commit()
        
        # 4. 업데이트된 정보 조회
        curs.execute("""
            SELECT customer_seq, customer_name, customer_phone, customer_email, 
                   created_at, provider, provider_subject
            FROM customer 
            WHERE customer_seq = %s
        """, (customer_seq,))
        customer_row = curs.fetchone()
        
        created_at = None
        if customer_row[4]:
            if hasattr(customer_row[4], 'isoformat'):
                created_at = customer_row[4].isoformat()
            else:
                created_at = str(customer_row[4])
        
        return {
            "result": {
                "customer_seq": customer_row[0],
                "customer_name": customer_row[1],
                "customer_phone": customer_row[2],
                "customer_email": customer_row[3],
                "created_at": created_at,
                "provider": customer_row[5],
                "provider_subject": customer_row[6]
            },
            "message": "계정이 통합되었습니다."
        }
        
    except Exception as e:
        conn.rollback()
        import traceback
        error_msg = str(e)
        traceback.print_exc()
        return {
            "result": "Error",
            "errorMsg": error_msg,
            "traceback": traceback.format_exc()
        }
    finally:
        try:
            curs.close()
        except:
            pass
        try:
            conn.close()
        except:
            pass


# ============================================
# 비밀번호 변경 요청 (이메일 인증 코드 발송)
# ============================================
@router.post("/request-password-change")
async def request_password_change(
    customer_seq: int = Form(...)
):
    """
    비밀번호 변경 요청
    - 이메일로 인증 코드 발송
    - 인증 토큰 생성 및 저장
    - 만료 시간: 10분
    """
    conn = connect_db()
    curs = conn.cursor()
    
    try:
        # 1. 고객 정보 확인
        curs.execute("""
            SELECT customer_seq, customer_name, customer_email, provider 
            FROM customer 
            WHERE customer_seq = %s
        """, (customer_seq,))
        customer = curs.fetchone()
        
        if customer is None:
            return {
                "result": "Error",
                "errorMsg": "고객을 찾을 수 없습니다."
            }
        
        customer_name = customer[1]
        customer_email = customer[2]
        provider = customer[3]
        
        # 2. 구글 계정은 비밀번호 변경 불가
        if provider == 'google':
            return {
                "result": "Error",
                "errorMsg": "구글 로그인 계정은 비밀번호를 변경할 수 없습니다."
            }
        
        # 3. 기존 미사용 인증 토큰 삭제 (중복 방지)
        curs.execute("""
            DELETE FROM password_reset_auth 
            WHERE customer_seq = %s AND is_verified = FALSE AND expires_at > NOW()
        """, (customer_seq,))
        
        # 4. 인증 토큰 및 코드 생성
        auth_token = str(uuid.uuid4())
        auth_code = f"{random.randint(100000, 999999)}"  # 6자리 숫자
        expires_at = datetime.now() + timedelta(minutes=10)  # 10분 후 만료
        
        # 5. 인증 토큰 저장
        curs.execute("""
            INSERT INTO password_reset_auth 
            (customer_seq, auth_token, auth_code, expires_at, is_verified, created_at) 
            VALUES (%s, %s, %s, %s, FALSE, NOW())
        """, (customer_seq, auth_token, auth_code, expires_at))
        
        conn.commit()
        
        # 6. 이메일 발송
        if EmailService is None:
            return {
                "result": "Error",
                "errorMsg": "이메일 서비스가 설정되지 않았습니다."
            }
        
        email_sent = EmailService.send_password_reset_email(
            to_email=customer_email,
            customer_name=customer_name,
            auth_code=auth_code,
            expires_minutes=10
        )
        
        if not email_sent:
            return {
                "result": "Error",
                "errorMsg": "이메일 발송에 실패했습니다. 잠시 후 다시 시도해주세요."
            }
        
        return {
            "result": "OK",
            "message": "인증 코드가 이메일로 발송되었습니다.",
            "auth_token": auth_token,  # 프론트엔드에서 인증 코드 검증 시 사용
            "expires_at": expires_at.isoformat()
        }
        
    except Exception as e:
        conn.rollback()
        import traceback
        error_msg = str(e)
        traceback.print_exc()
        return {
            "result": "Error",
            "errorMsg": error_msg,
            "traceback": traceback.format_exc()
        }
    finally:
        try:
            curs.close()
        except:
            pass
        try:
            conn.close()
        except:
            pass


# ============================================
# 인증 코드 검증
# ============================================
@router.post("/verify-password-change-code")
async def verify_password_change_code(
    customer_seq: int = Form(...),
    auth_token: str = Form(...),
    auth_code: str = Form(...)
):
    """
    인증 코드 검증
    - 인증 코드 확인
    - 만료 시간 확인
    - 인증 완료 처리
    """
    conn = connect_db()
    curs = conn.cursor()
    
    try:
        # 1. 인증 토큰 조회
        curs.execute("""
            SELECT auth_seq, auth_code, expires_at, is_verified, customer_seq
            FROM password_reset_auth 
            WHERE auth_token = %s AND customer_seq = %s
            ORDER BY created_at DESC
            LIMIT 1
        """, (auth_token, customer_seq))
        auth_record = curs.fetchone()
        
        if auth_record is None:
            return {
                "result": "Error",
                "errorMsg": "유효하지 않은 인증 토큰입니다."
            }
        
        stored_code = auth_record[1]
        expires_at = auth_record[2]
        is_verified = auth_record[3]
        
        # 2. 이미 인증 완료된 경우
        if is_verified:
            return {
                "result": "Error",
                "errorMsg": "이미 사용된 인증 코드입니다."
            }
        
        # 3. 만료 시간 확인
        if datetime.now() > expires_at:
            return {
                "result": "Error",
                "errorMsg": "인증 코드가 만료되었습니다. 다시 요청해주세요."
            }
        
        # 4. 인증 코드 확인
        if stored_code != auth_code:
            return {
                "result": "Error",
                "errorMsg": "인증 코드가 일치하지 않습니다."
            }
        
        # 5. 인증 완료 처리
        auth_seq = auth_record[0]
        curs.execute("""
            UPDATE password_reset_auth 
            SET is_verified = TRUE 
            WHERE auth_seq = %s
        """, (auth_seq,))
        
        conn.commit()
        
        return {
            "result": "OK",
            "message": "인증이 완료되었습니다."
        }
        
    except Exception as e:
        conn.rollback()
        import traceback
        error_msg = str(e)
        traceback.print_exc()
        return {
            "result": "Error",
            "errorMsg": error_msg,
            "traceback": traceback.format_exc()
        }
    finally:
        try:
            curs.close()
        except:
            pass
        try:
            conn.close()
        except:
            pass


# ============================================
# FCM 토큰 등록/업데이트
# ============================================
@router.post("/{customer_seq}/fcm-token")
async def register_fcm_token(
    customer_seq: int,
    request: FCMTokenRequest
):
    """
    FCM 토큰 등록/업데이트
    - 고객의 FCM 토큰을 등록하거나 업데이트합니다
    - 같은 고객의 같은 토큰이 이미 있으면 업데이트 (updated_at 갱신)
    - 새로운 토큰이면 등록
    """
    conn = connect_db()
    curs = conn.cursor()
    
    try:
        # 1. 고객 존재 확인
        curs.execute("""
            SELECT customer_seq FROM customer WHERE customer_seq = %s
        """, (customer_seq,))
        customer = curs.fetchone()
        
        if customer is None:
            return {
                "result": "Error",
                "errorMsg": "고객을 찾을 수 없습니다."
            }
        
        # 2. device_type 검증
        device_type = request.device_type.lower()
        if device_type not in ['ios', 'android']:
            return {
                "result": "Error",
                "errorMsg": "device_type은 'ios' 또는 'android'여야 합니다."
            }
        
        # 3. 기기 ID가 있으면 동일 기기 확인 및 다른 사용자 토큰 정리
        if request.device_id:
            # 같은 고객의 같은 기기 ID가 있는지 확인
            curs.execute("""
                SELECT device_token_seq, fcm_token FROM device_token 
                WHERE customer_seq = %s AND device_id = %s
            """, (customer_seq, request.device_id))
            existing_device = curs.fetchone()
            
            if existing_device:
                # 같은 기기에서 앱 재설치한 경우: 기존 토큰 업데이트
                existing_token_seq = existing_device[0]
                existing_fcm_token = existing_device[1]
                
                if existing_fcm_token == request.fcm_token:
                    # 같은 토큰이면 업데이트만
                    curs.execute("""
                        UPDATE device_token 
                        SET device_type = %s, updated_at = NOW()
                        WHERE device_token_seq = %s
                    """, (device_type, existing_token_seq))
                else:
                    # 다른 토큰이면 토큰 교체 (앱 재설치로 새 토큰 발급됨)
                    curs.execute("""
                        UPDATE device_token 
                        SET fcm_token = %s, device_type = %s, updated_at = NOW()
                        WHERE device_token_seq = %s
                    """, (request.fcm_token, device_type, existing_token_seq))
                
                conn.commit()
                return {
                    "result": "OK",
                    "message": "FCM 토큰이 업데이트되었습니다. (동일 기기)"
                }
        
        # 4. 기존 토큰 확인 (기기 ID가 없거나 동일 기기를 찾지 못한 경우)
        curs.execute("""
            SELECT device_token_seq FROM device_token 
            WHERE customer_seq = %s AND fcm_token = %s
        """, (customer_seq, request.fcm_token))
        existing_token = curs.fetchone()
        
        if existing_token:
            # 기존 토큰 업데이트 (updated_at 자동 갱신)
            if request.device_id:
                # 기기 ID도 함께 업데이트
                curs.execute("""
                    UPDATE device_token 
                    SET device_type = %s, device_id = %s, updated_at = NOW()
                    WHERE customer_seq = %s AND fcm_token = %s
                """, (device_type, request.device_id, customer_seq, request.fcm_token))
            else:
                curs.execute("""
                    UPDATE device_token 
                    SET device_type = %s, updated_at = NOW()
                    WHERE customer_seq = %s AND fcm_token = %s
                """, (device_type, customer_seq, request.fcm_token))
        else:
            # 새 토큰 등록
            # 주의: 같은 기기 ID를 가진 다른 사용자의 토큰도 별도로 유지됨
            # (테스트 환경에서 같은 기기에서 여러 사용자가 로그인할 수 있음)
            curs.execute("""
                INSERT INTO device_token 
                (customer_seq, fcm_token, device_type, device_id, created_at, updated_at)
                VALUES (%s, %s, %s, %s, NOW(), NOW())
            """, (customer_seq, request.fcm_token, device_type, request.device_id))
        
        conn.commit()
        
        return {
            "result": "OK",
            "message": "FCM 토큰이 등록되었습니다."
        }
        
    except Exception as e:
        conn.rollback()
        import traceback
        error_msg = str(e)
        traceback.print_exc()
        return {
            "result": "Error",
            "errorMsg": error_msg,
            "traceback": traceback.format_exc()
        }
    finally:
        try:
            curs.close()
        except:
            pass
        try:
            conn.close()
        except:
            pass


# ============================================
# 고객에게 푸시 알림 발송
# ============================================
@router.post("/{customer_seq}/push")
async def send_push_to_customer(
    customer_seq: int,
    request: PushNotificationRequest
):
    """
    고객의 모든 기기에 푸시 알림 발송
    
    Args:
        customer_seq: 고객 번호
        request: 푸시 알림 요청 (title, body, data)
    
    Returns:
        성공 시 발송된 기기 수 반환
    """
    try:
        from ..utils.fcm_service import FCMService
        
        # FCMService를 사용하여 고객의 모든 기기에 알림 발송
        success_count = FCMService.send_notification_to_customer(
            customer_seq=customer_seq,
            title=request.title,
            body=request.body,
            data=request.data
        )
        
        return {
            "result": "OK",
            "success_count": success_count,
            "message": f"{success_count}개 기기에 알림이 발송되었습니다."
        }
        
    except Exception as e:
        import traceback
        error_msg = str(e)
        traceback.print_exc()
        return {
            "result": "Error",
            "errorMsg": error_msg,
            "success_count": 0
        }


# ============================================================
# 생성 이력
# ============================================================
# 작성일: 2026-01-15
# 작성자: 김택권
# 설명: Customer API - 고객 계정 CRUD 및 인증 기능 (회원가입, 로그인, 소셜 로그인, 비밀번호 변경 등)
#
# ============================================================
# 수정 이력
# ============================================================
# 2026-01-15 김택권: 초기 생성
#   - 기본 CRUD 엔드포인트 구현 (GET, PUT, DELETE)
#   - 회원가입 API 구현 (/register)
#   - 일반 로그인 API 구현 (/login)
#   - 고객 정보 수정 API 구현 (PUT /{customer_seq})
#   - 구글 소셜 로그인 API 구현 (/social-login)
#   - 계정 통합 API 구현 (/link-social)
#   - 비밀번호 변경 요청 API 구현 (/request-password-change)
#   - 인증 코드 검증 API 구현 (/verify-password-change-code)
#   - 비밀번호 변경 API 구현 (PUT /change-password)
#   - provider 및 provider_subject 필드 지원
#   - 구글 계정 비밀번호 변경 제한 로직 구현
#   - 이메일 서비스 연동 (EmailService)
#
# 2026-01-15 김택권: 회원가입 API 개선
#   - customer_phone 필드를 선택사항(Optional)으로 변경
#   - Form(None)으로 설정하여 전화번호 없이도 회원가입 가능하도록 수정
#   - 빈 문자열을 None으로 변환하여 DB에 NULL 저장 처리
#

# 2026-01-16: FCM 토큰 등록 API 추가
#   - POST /{customer_seq}/fcm-token 엔드포인트 구현
#   - FCMTokenRequest 모델 추가
#   - 기존 토큰이 있으면 업데이트, 없으면 등록
#   - device_type 검증 (ios/android)

# 2026-01-31: 단독 실행 지원 추가
#   - __main__ 블록에서 FastAPI 앱을 직접 실행할 수 있도록 기능 추가
#   - 기존 main.py 라우터 연결 방식과 병행 지원

# =============================
# 단독 실행 지원
# =============================
if __name__ == "__main__":
    import uvicorn
    from fastapi import FastAPI

    app = FastAPI()
    app.include_router(router, prefix="/customer")

    uvicorn.run(app, host="0.0.0.0", port=8000)