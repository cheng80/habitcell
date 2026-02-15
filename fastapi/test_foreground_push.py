"""
포그라운드 로컬 노티피케이션 테스트 스크립트

사용법:
    python test_foreground_push.py YOUR_FCM_TOKEN

또는:
    python test_foreground_push.py
    # 실행 후 FCM 토큰 입력 요청
"""

import sys
import os
from datetime import datetime
from app.utils.fcm_service import FCMService

def main():
    # FCM 토큰 확인
    fcm_token = None
    if len(sys.argv) > 1:
        fcm_token = sys.argv[1]
    else:
        fcm_token = input("FCM 토큰을 입력하세요: ").strip()
    
    if not fcm_token:
        print("❌ FCM 토큰이 필요합니다.")
        return
    
    print("=" * 60)
    print("포그라운드 로컬 노티피케이션 테스트")
    print("=" * 60)
    print(f"📱 FCM 토큰: {fcm_token[:20]}...")
    print()
    
    # 테스트 메시지 데이터
    test_data = {
        'type': 'test',
        'timestamp': datetime.now().isoformat(),
        'message': '이것은 포그라운드 테스트 메시지입니다.',
    }
    
    print("📤 테스트 푸시 발송 중...")
    print(f"   제목: 포그라운드 테스트 알림")
    print(f"   본문: 앱이 포그라운드에 있을 때 로컬 알림이 표시됩니다.")
    print(f"   데이터: {test_data}")
    print()
    
    # 푸시 발송
    message_id = FCMService.send_notification(
        token=fcm_token,
        title="포그라운드 테스트 알림",
        body="앱이 포그라운드에 있을 때 로컬 알림이 표시됩니다.",
        data=test_data
    )
    
    if message_id:
        print("=" * 60)
        print("✅ 푸시 발송 성공!")
        print(f"📨 Message ID: {message_id}")
        print("=" * 60)
        print()
        print("💡 확인 사항:")
        print("   1. 앱이 포그라운드 상태인지 확인하세요")
        print("   2. 로컬 알림이 표시되는지 확인하세요")
        print("   3. 알림 제목/본문이 올바르게 표시되는지 확인하세요")
        print("   4. 콘솔 로그에서 '📨 Foreground message received' 메시지 확인")
    else:
        print("=" * 60)
        print("❌ 푸시 발송 실패")
        print("=" * 60)
        print()
        print("💡 확인 사항:")
        print("   1. serviceAccountKey.json 파일이 있는지 확인")
        print("   2. FCM 토큰이 유효한지 확인")
        print("   3. Firebase 프로젝트 설정 확인")

if __name__ == "__main__":
    main()
