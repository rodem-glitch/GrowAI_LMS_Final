# Google Drive API 설정 및 사용 가이드

## 📚 목차
1. [Google Cloud Console 설정](#1-google-cloud-console-설정)
2. [서비스 계정 키 다운로드](#2-서비스-계정-키-다운로드)
3. [Drive 폴더 권한 설정](#3-drive-폴더-권한-설정)
4. [로컬 환경 설정](#4-로컬-환경-설정)
5. [스크립트 실행](#5-스크립트-실행)
6. [문제 해결](#6-문제-해결)

---

## 1. Google Cloud Console 설정

### 1.1 프로젝트 생성
1. https://console.cloud.google.com/ 접속
2. 상단 "프로젝트 선택" 드롭다운 클릭
3. "새 프로젝트" 클릭
4. 프로젝트 이름: `claude-drive-access` 입력
5. "만들기" 클릭

### 1.2 Google Drive API 활성화
1. 좌측 메뉴: **API 및 서비스 > 라이브러리**
2. 검색: `Google Drive API`
3. "Google Drive API" 클릭
4. **"사용 설정"** 버튼 클릭

### 1.3 서비스 계정 생성
1. 좌측 메뉴: **API 및 서비스 > 사용자 인증 정보**
2. **"+ 사용자 인증 정보 만들기"** > "서비스 계정"
3. 서비스 계정 세부정보:
   - 이름: `drive-reader`
   - ID: 자동 생성
   - 설명: `Google Drive 폴더 읽기용`
4. "만들기 및 계속하기" 클릭
5. 역할 부여 단계: **건너뛰기** (계속 클릭)
6. "완료" 클릭

---

## 2. 서비스 계정 키 다운로드

### 2.1 JSON 키 생성
1. 생성된 서비스 계정 클릭
2. 상단 **"키"** 탭 클릭
3. **"키 추가" > "새 키 만들기"**
4. 키 유형: **JSON** 선택
5. "만들기" 클릭
6. JSON 파일 자동 다운로드 ✅

### 2.2 서비스 계정 이메일 확인
다운로드한 JSON 파일을 텍스트 에디터로 열기:

```json
{
  "type": "service_account",
  "client_email": "drive-reader@claude-drive-access.iam.gserviceaccount.com",
  ...
}
```

**`client_email` 값을 복사하세요!** 👆

---

## 3. Drive 폴더 권한 설정

### 3.1 폴더 공유
1. https://drive.google.com 접속
2. 대상 폴더로 이동:
   - URL: `https://drive.google.com/drive/folders/0ANgWhS-TqRnbUk9PVA`
3. 폴더 우클릭 > **"공유"**
4. "사용자 및 그룹 추가" 입력창에 **서비스 계정 이메일** 붙여넣기
   ```
   drive-reader@claude-drive-access.iam.gserviceaccount.com
   ```
5. 권한: **"뷰어"** 선택 (읽기 전용)
6. ✅ "알림 보내기" 체크 해제 (서비스 계정은 이메일 받지 않음)
7. **"전송"** 클릭

✅ 이제 서비스 계정이 폴더에 접근 가능합니다!

---

## 4. 로컬 환경 설정

### 4.1 JSON 키 파일 복사
다운로드한 JSON 파일을 프로젝트 디렉토리로 복사:

**Windows (PowerShell):**
```powershell
copy "$env:USERPROFILE\Downloads\claude-drive-access-*.json" service-account-key.json
```

**Mac/Linux:**
```bash
cp ~/Downloads/claude-drive-access-*.json service-account-key.json
```

### 4.2 Python 라이브러리 설치

**Option 1: pip 직접 사용**
```bash
pip install google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client
```

**Option 2: requirements 파일 사용**
```bash
pip install -r requirements-gdrive.txt
```

**가상환경 사용 권장 (선택사항):**
```bash
# Windows
python -m venv venv
.\venv\Scripts\activate

# Mac/Linux
python3 -m venv venv
source venv/bin/activate

# 라이브러리 설치
pip install -r requirements-gdrive.txt
```

---

## 5. 스크립트 실행

### 5.1 빠른 테스트
```bash
python quick_test.py
```

**예상 출력:**
```
폴더 ID 0ANgWhS-TqRnbUk9PVA의 내용을 조회합니다...

3개의 항목을 찾았습니다:

📄 문서1.pdf
   ID: 1ABC...
   타입: application/pdf

📄 이미지.jpg
   ID: 2DEF...
   타입: image/jpeg
```

### 5.2 전체 기능 스크립트
```bash
python gdrive_access.py 0ANgWhS-TqRnbUk9PVA
```

**예상 출력:**
```
✅ Google Drive API 인증 성공!

📁 폴더 ID: 0ANgWhS-TqRnbUk9PVA
================================================================================
폴더 이름: My Shared Folder
생성일: 2024-01-15T10:30:00.000Z
수정일: 2024-01-20T15:45:00.000Z
================================================================================

📋 총 5개 항목 발견:

📂 폴더:
  ├─ Subfolder1
  │  ID: 1XYZ...
  │  링크: https://drive.google.com/...

📄 파일:
  ├─ document.pdf
  │  ID: 2ABC...
  │  타입: application/pdf
  │  크기: 2.50 MB
  │  링크: https://drive.google.com/...
```

### 5.3 사용자 정의 실행
다른 폴더 ID나 키 파일 사용:
```bash
python gdrive_access.py <folder_id> <credentials_file>
```

예시:
```bash
python gdrive_access.py 1ABC123xyz my-custom-key.json
```

---

## 6. 문제 해결

### ❌ 오류: `FileNotFoundError: service-account-key.json`
**원인:** JSON 키 파일이 현재 디렉토리에 없음

**해결:**
1. JSON 파일 다운로드 확인
2. 파일을 프로젝트 디렉토리로 복사
3. 파일 이름이 정확히 `service-account-key.json`인지 확인

---

### ❌ 오류: `404 Not Found`
**원인:** 폴더 ID가 잘못되었거나 폴더가 삭제됨

**해결:**
1. 폴더 URL에서 ID 다시 확인
   - URL: `https://drive.google.com/drive/folders/0ANgWhS-TqRnbUk9PVA`
   - ID: `0ANgWhS-TqRnbUk9PVA`
2. 웹 브라우저에서 폴더 접근 가능한지 확인

---

### ❌ 오류: `403 Forbidden` 또는 "접근 권한 없음"
**원인:** 서비스 계정이 폴더에 대한 권한 없음

**해결:**
1. Google Drive에서 폴더 공유 설정 확인
2. 서비스 계정 이메일이 공유 목록에 있는지 확인
3. JSON 파일에서 `client_email` 값 확인
4. 폴더 우클릭 > 공유 > 서비스 계정 이메일 추가

**서비스 계정 이메일 찾기:**
```bash
# Windows PowerShell
Get-Content service-account-key.json | Select-String "client_email"

# Mac/Linux
grep "client_email" service-account-key.json
```

---

### ❌ 오류: `ModuleNotFoundError: No module named 'google'`
**원인:** Google 라이브러리 미설치

**해결:**
```bash
pip install google-auth google-api-python-client
```

---

### ❌ 오류: API가 활성화되지 않음
**원인:** Google Drive API가 프로젝트에서 활성화되지 않음

**해결:**
1. https://console.cloud.google.com/apis/library
2. 프로젝트 선택
3. "Google Drive API" 검색
4. "사용 설정" 클릭

---

## 7. 추가 기능

### 7.1 특정 파일 다운로드
```python
from gdrive_access import GoogleDriveClient

client = GoogleDriveClient('service-account-key.json')
client.download_file('file_id_here', 'output_file.pdf')
```

### 7.2 파일 검색
```python
client.search_files('folder_id', '검색키워드')
```

### 7.3 재귀적으로 모든 하위 폴더 탐색
```python
def list_all_files(client, folder_id, indent=0):
    items = client.list_folder_contents(folder_id)
    for item in items:
        print("  " * indent + f"- {item['name']}")
        if item['mimeType'] == 'application/vnd.google-apps.folder':
            list_all_files(client, item['id'], indent + 1)
```

---

## 8. 보안 권장사항

⚠️ **중요: JSON 키 파일 보안**

1. **절대 Git에 커밋하지 마세요!**
   - `.gitignore`에 추가됨: `service-account-key.json`

2. **파일 권한 제한**
   ```bash
   # Mac/Linux
   chmod 600 service-account-key.json
   ```

3. **환경변수 사용 (프로덕션)**
   ```python
   import os
   credentials_path = os.getenv('GOOGLE_CREDENTIALS', 'service-account-key.json')
   ```

4. **키 정기 갱신**
   - 주기적으로 새 키 생성하고 이전 키 삭제

---

## 9. 참고 자료

- [Google Drive API 공식 문서](https://developers.google.com/drive/api/guides/about-sdk)
- [Python Quickstart](https://developers.google.com/drive/api/quickstart/python)
- [API Reference](https://developers.google.com/drive/api/v3/reference)

---

**문제가 발생하면 위 "문제 해결" 섹션을 참고하세요!** 🔧
