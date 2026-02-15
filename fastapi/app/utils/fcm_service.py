"""
FCM 푸시 알림 발송 서비스
다른 API 파일에서 import하여 사용할 수 있는 공통 FCM 서비스
작성일: 2026-01-19
작성자: 김택권
"""

import firebase_admin
from firebase_admin import credentials, messaging
import os
import time
from typing import Optional, Dict, List


class FCMService:
    """FCM 푸시 알림 발송 서비스 클래스"""
    
    _initialized = False
    
    @classmethod
    def _ensure_initialized(cls):
        """Firebase Admin SDK 초기화 확인 및 초기화"""
        if cls._initialized:
            return
        
        if firebase_admin._apps:
            cls._initialized = True
            return
        
        # serviceAccountKey.json 경로 설정
        cred_path = os.path.join(
            os.path.dirname(os.path.dirname(os.path.dirname(__file__))),
            "serviceAccountKey.json"
        )
        
        if not os.path.exists(cred_path):
            print(f"⚠️  Warning: serviceAccountKey.json not found at {cred_path}")
            print("⚠️  FCM push will not work until serviceAccountKey.json is added")
            return
        
        try:
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            cls._initialized = True
            print("✅ Firebase Admin SDK initialized successfully")
        except Exception as e:
            print(f"❌ Firebase Admin SDK initialization failed: {e}")
    
    @classmethod
    def send_notification(
        cls,
        token: str,
        title: str,
        body: str,
        data: Optional[Dict[str, str]] = None
    ) -> Optional[str]:
        """
        단일 기기에 푸시 알림 발송
        
        Args:
            token: FCM 토큰
            title: 알림 제목
            body: 알림 내용
            data: 추가 데이터 (선택사항)
            
        Returns:
            str: 메시지 ID (성공 시), None (실패 시)
        """
        cls._ensure_initialized()
        
        if not firebase_admin._apps:
            print("⚠️  Firebase Admin SDK not initialized")
            return None
        
        try:
            # Android에서 동일 알림이 카운트만 올라가는 문제 방지
            # 각 알림마다 고유한 tag 생성 (밀리초 기반)
            android_tag = f"notification_{int(time.time() * 1000)}"
            
            message = messaging.Message(
                token=token,
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data={k: str(v) for k, v in (data or {}).items()},
                android=messaging.AndroidConfig(
                    notification=messaging.AndroidNotification(
                        tag=android_tag,  # 고유 태그로 각 알림을 별도로 표시
                    ),
                ),
            )
            
            message_id = messaging.send(message)
            print(f"✅ Push notification sent: {message_id}")
            return message_id
            
        except messaging.UnregisteredError:
            print("⚠️  FCM token is invalid or expired")
            return None
        except Exception as e:
            import traceback
            print(f"❌ Failed to send push notification: {e}")
            print(f"❌ Error type: {type(e).__name__}")
            print(f"❌ Traceback:")
            traceback.print_exc()
            return None
    
    @classmethod
    def send_notification_to_customer(
        cls,
        customer_seq: int,
        title: str,
        body: str,
        data: Optional[Dict[str, str]] = None
    ) -> int:
        """
        고객의 모든 기기에 푸시 알림 발송
        
        Args:
            customer_seq: 고객 번호
            title: 알림 제목
            body: 알림 내용
            data: 추가 데이터 (선택사항)
            
        Returns:
            int: 발송 성공한 기기 수
        """
        from app.database.connection import connect_db
        
        cls._ensure_initialized()
        
        if not firebase_admin._apps:
            print("⚠️  Firebase Admin SDK not initialized")
            return 0
        
        # 고객의 FCM 토큰 조회
        conn = connect_db()
        curs = conn.cursor()
        
        try:
            curs.execute("""
                SELECT fcm_token FROM device_token 
                WHERE customer_seq = %s
            """, (customer_seq,))
            
            tokens = [row[0] for row in curs.fetchall()]
            
            if not tokens:
                print(f"⚠️  No FCM tokens found for customer_seq: {customer_seq}")
                return 0
            
            # 토큰 목록 로그 출력
            print(f"📱 고객 {customer_seq}의 FCM 토큰 목록 ({len(tokens)}개):")
            for i, token in enumerate(tokens, 1):
                # print(f"   [{i}] {token[:20]}...{token[-10:]}")
                print(f"   [{i}] {token}")
            
            # 각 토큰에 알림 발송 및 만료된 토큰 정리
            success_count = 0
            invalid_tokens = []
            
            for token in tokens:
                message_id = cls.send_notification(token, title, body, data)
                if message_id:
                    success_count += 1
                else:
                    # 발송 실패한 토큰은 만료되었을 가능성이 높음
                    # UnregisteredError가 발생했을 수 있으므로 추적
                    invalid_tokens.append(token)
            
            # 만료된 토큰이 있으면 DB에서 삭제
            if invalid_tokens:
                cls._cleanup_invalid_tokens(invalid_tokens, customer_seq)
            
            print(f"✅ Sent notifications to {success_count}/{len(tokens)} devices")
            return success_count
            
        except Exception as e:
            print(f"❌ Failed to send notifications to customer: {e}")
            return 0
        finally:
            try:
                curs.close()
                conn.close()
            except:
                pass
    
    @classmethod
    def send_multicast_notification(
        cls,
        tokens: List[str],
        title: str,
        body: str,
        data: Optional[Dict[str, str]] = None
    ) -> int:
        """
        여러 기기에 동시에 푸시 알림 발송 (최대 500개)
        
        Args:
            tokens: FCM 토큰 리스트
            title: 알림 제목
            body: 알림 내용
            data: 추가 데이터 (선택사항)
            
        Returns:
            int: 발송 성공한 기기 수
        """
        cls._ensure_initialized()
        
        if not firebase_admin._apps:
            print("⚠️  Firebase Admin SDK not initialized")
            return 0
        
        if not tokens:
            return 0
        
        # FCM은 최대 500개까지 한 번에 발송 가능
        if len(tokens) > 500:
            print(f"⚠️  Too many tokens ({len(tokens)}). Maximum is 500.")
            tokens = tokens[:500]
        
        try:
            # Android에서 동일 알림이 카운트만 올라가는 문제 방지
            # 각 알림마다 고유한 tag 생성 (밀리초 기반)
            android_tag = f"notification_{int(time.time() * 1000)}"
            
            message = messaging.MulticastMessage(
                tokens=tokens,
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data={k: str(v) for k, v in (data or {}).items()},
                android=messaging.AndroidConfig(
                    notification=messaging.AndroidNotification(
                        tag=android_tag,  # 고유 태그로 각 알림을 별도로 표시
                    ),
                ),
            )
            
            response = messaging.send_multicast(message)
            success_count = response.success_count
            
            print(f"✅ Sent notifications to {success_count}/{len(tokens)} devices")
            return success_count
            
        except Exception as e:
            print(f"❌ Failed to send multicast notification: {e}")
            return 0
    
    @classmethod
    def _cleanup_invalid_tokens(cls, invalid_tokens: List[str], customer_seq: int):
        """
        만료된 FCM 토큰을 DB에서 삭제
        
        Args:
            invalid_tokens: 만료된 토큰 리스트
            customer_seq: 고객 번호
        """
        if not invalid_tokens:
            return
        
        try:
            from ..database.connection import connect_db
            
            conn = connect_db()
            curs = conn.cursor()
            
            try:
                # 만료된 토큰 삭제
                placeholders = ','.join(['%s'] * len(invalid_tokens))
                curs.execute(f"""
                    DELETE FROM device_token 
                    WHERE customer_seq = %s AND fcm_token IN ({placeholders})
                """, [customer_seq] + invalid_tokens)
                
                deleted_count = curs.rowcount
                conn.commit()
                
                if deleted_count > 0:
                    print(f"🧹 Cleaned up {deleted_count} invalid FCM token(s) for customer_seq: {customer_seq}")
                    
            except Exception as e:
                conn.rollback()
                print(f"⚠️  Failed to cleanup invalid tokens: {e}")
            finally:
                try:
                    curs.close()
                except:
                    pass
                try:
                    conn.close()
                except:
                    pass
                    
        except Exception as e:
            print(f"⚠️  Failed to cleanup invalid tokens: {e}")


# ============================================================
# 생성 이력
# ============================================================
# 작성일: 2026-01-19
# 작성자: 김택권
# 설명: FCM 푸시 알림 발송 서비스 - 다른 API 파일에서 import하여 사용 가능
#
# ============================================================
# 수정 이력
# ============================================================
# 2026-01-19 김택권: 초기 생성
#   - Firebase Admin SDK 전역 초기화 로직
#   - 단일 기기 알림 발송 함수 (`send_notification`)
#   - 고객의 모든 기기 알림 발송 함수 (`send_notification_to_customer`)
#   - 여러 기기 동시 알림 발송 함수 (`send_multicast_notification`)
