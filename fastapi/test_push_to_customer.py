"""
고객의 모든 기기에 푸시 알림 발송 테스트 스크립트

사용법:
    python test_push_to_customer.py CUSTOMER_SEQ

예시:
    python test_push_to_customer.py 8
"""

import sys
from datetime import datetime
from app.utils.fcm_service import FCMService

def main():
    # 고객 번호 확인
    customer_seq = None
    if len(sys.argv) > 1:
        try:
            customer_seq = int(sys.argv[1])
        except ValueError:
            print("❌ 고객 번호는 숫자여야 합니다.")
            return
    else:
        customer_seq_input = input("고객 번호를 입력하세요: ").strip()
        try:
            customer_seq = int(customer_seq_input)
        except ValueError:
            print("❌ 고객 번호는 숫자여야 합니다.")
            return
    
    print("=" * 60)
    print("고객의 모든 기기에 푸시 알림 발송 테스트")
    print("=" * 60)
    print(f"👤 고객 번호: {customer_seq}")
    print()
    
    # 테스트 메시지 데이터
    test_data = {
        'type': 'test',
        'timestamp': datetime.now().isoformat(),
        'message': '고객의 모든 기기에 발송되는 테스트 메시지입니다.',
    }
    
    print("📤 테스트 푸시 발송 중...")
    print(f"   제목: 테스트 알림")
    print(f"   본문: 고객 {customer_seq}번의 모든 기기에 알림이 발송됩니다.")
    print(f"   데이터: {test_data}")
    print()
    
    # 푸시 발송
    success_count = FCMService.send_notification_to_customer(
        customer_seq=customer_seq,
        title="테스트 알림",
        body=f"고객 {customer_seq}번의 모든 기기에 알림이 발송됩니다.",
        data=test_data
    )
    
    print()
    print("=" * 60)
    if success_count > 0:
        print(f"✅ 푸시 발송 성공!")
        print(f"📨 발송된 기기 수: {success_count}개")
    else:
        print("❌ 푸시 발송 실패 또는 등록된 기기가 없습니다")
    print("=" * 60)
    print()
    print("💡 확인 사항:")
    print("   1. 고객의 모든 기기에서 알림이 수신되었는지 확인하세요")
    print("   2. 알림 제목/본문이 올바르게 표시되는지 확인하세요")
    print("   3. 만료된 토큰은 자동으로 정리됩니다")

if __name__ == "__main__":
    main()
