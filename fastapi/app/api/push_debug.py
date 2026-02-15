"""
FCM 단발 푸시 테스트 API
DB·예약 로직 없이 푸시 발송만 테스트하기 위한 디버그 엔드포인트
작성일: 2026-01-17
작성자: 김택권
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.utils.fcm_service import FCMService

router = APIRouter()


class PushRequest(BaseModel):
    """푸시 발송 요청 모델"""
    token: str
    title: str = "테스트 푸시"
    body: str = "FCM 단발 테스트"
    data: dict | None = None


@router.post("/debug/push")
async def debug_push(req: PushRequest):
    """
    FCM 단발 푸시 테스트 엔드포인트
    
    Args:
        req: 푸시 발송 요청 (token, title, body, data)
    
    Returns:
        성공 시 message_id 반환
    """
    try:
        # FCMService를 사용하여 푸시 알림 발송
        message_id = FCMService.send_notification(
            token=req.token,
            title=req.title,
            body=req.body,
            data=req.data
        )
        
        if message_id is None:
            raise HTTPException(
                status_code=500,
                detail="Failed to send push notification. Check serviceAccountKey.json and FCM token."
            )
        
        return {
            "ok": True,
            "message_id": message_id,
            "token": req.token[:20] + "..." if len(req.token) > 20 else req.token,
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to send push notification: {str(e)}"
        )


# ============================================================
# 생성 이력
# ============================================================
# 작성일: 2026-01-17
# 작성자: 김택권
# 설명: FCM 단발 푸시 테스트 API - DB·예약 로직 없이 푸시 발송만 테스트
#
# ============================================================
# 수정 이력
# ============================================================
# 2026-01-17 김택권: 초기 생성
#   - Firebase Admin SDK 초기화 로직
#   - /debug/push 엔드포인트 구현
#   - 에러 처리 및 응답 형식 정의
# 2026-01-19 김택권: FCMService 사용으로 리팩토링
#   - 중복 초기화 코드 제거
#   - FCMService.send_notification() 사용
#   - 전역 초기화는 FCMService에서 자동 처리