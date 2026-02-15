# ERD (Entity Relationship Diagram)

Habit App 데이터 모델 ERD. **Mermaid** 문법으로 작성됨.

SQLite와 MySQL이 역할이 다르므로 ERD를 두 개로 분리했다.

| 파일 | 대상 | 용도 |
|------|------|------|
| [erd_sqlite.mmd](./erd_sqlite.mmd) | Client (SQLite) | 앱 도메인 모델 (습관, 카테고리, 로그) |
| [erd_mysql.mmd](./erd_mysql.mmd) | Server (MySQL) | 백업/인프라 (기기, 이메일 인증, 스냅샷) |

## 관계

- **device_uuid**: 클라이언트(GetStorage)와 서버(devices)를 논리적으로 연결
- MySQL `backups.payload_json`에 SQLite 전체 스냅샷(categories, habits, logs 등)이 JSON으로 저장됨

## 렌더링 방법

- **GitHub/GitLab**: `.md` 파일 내 Mermaid 코드 블록 자동 렌더링
- **VSCode**: Mermaid 확장 (bierner.markdown-mermaid)
- **온라인**: [mermaid.live](https://mermaid.live)
