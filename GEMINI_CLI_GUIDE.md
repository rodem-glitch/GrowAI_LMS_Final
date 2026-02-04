# 🤖 Gemini CLI 완벽 가이드

## 📚 목차
1. [Gemini CLI란?](#gemini-cli란)
2. [사전 준비사항](#사전-준비사항)
3. [Google AI Studio에서 API 키 발급](#api-키-발급)
4. [Gemini CLI 설치](#gemini-cli-설치)
5. [환경 설정](#환경-설정)
6. [기본 사용법](#기본-사용법)
7. [고급 활용](#고급-활용)
8. [Python SDK 사용](#python-sdk-사용)
9. [문제 해결](#문제-해결)

---

## Gemini CLI란?

Google의 Gemini AI 모델을 명령줄(CLI)에서 사용할 수 있는 도구입니다.

**주요 기능:**
- 텍스트 생성 및 대화
- 이미지 분석
- 코드 생성 및 설명
- 문서 요약
- 다국어 번역

---

## 사전 준비사항

### 필수 요구사항
- **Python 3.9 이상**
- **pip** (Python 패키지 관리자)
- **Google AI Studio API 키**
- 인터넷 연결

### Python 버전 확인
```bash
python --version
# 또는
python3 --version
```

---

## API 키 발급

### Step 1: Google AI Studio 접속
1. https://makersuite.google.com/app/apikey 접속
   - 또는 https://aistudio.google.com/app/apikey
2. Google 계정으로 로그인

### Step 2: API 키 생성
1. **"Create API Key"** 또는 **"API 키 만들기"** 클릭
2. 프로젝트 선택 또는 새 프로젝트 생성
3. API 키가 생성됩니다 (예: `AIzaSyXXXXXXXXXXXXXXXXXXXXXXXX`)
4. **⚠️ API 키를 안전한 곳에 복사하세요!**

### Step 3: API 키 확인
생성된 API 키는 다음과 같은 형식:
```
AIzaSyXXXXXXXXXXXXXXXXXXXXXXXX
```

---

## Gemini CLI 설치

### Option 1: 공식 Python SDK 설치 (권장)

```bash
pip install google-generativeai
```

### Option 2: 비공식 CLI 도구 설치

```bash
# gemini-cli (npm 기반)
npm install -g @google/generative-ai-cli

# 또는 Python 기반 래퍼
pip install gemini-cli-tool
```

### Option 3: 직접 Python 스크립트 사용
이 가이드에서 제공하는 커스텀 CLI 스크립트 사용 (아래 참조)

---

## 환경 설정

### Windows (PowerShell)

#### 임시 설정 (현재 세션만)
```powershell
$env:GEMINI_API_KEY = "AIzaSyXXXXXXXXXXXXXXXXXXXXXXXX"
```

#### 영구 설정 (권장)
```powershell
# 1. 시스템 환경 변수 설정
[System.Environment]::SetEnvironmentVariable('GEMINI_API_KEY', 'AIzaSyXXXXXXXXXXXXXXXXXXXXXXXX', 'User')

# 2. 또는 GUI 방식:
# - Windows 검색: "환경 변수"
# - "시스템 환경 변수 편집" 클릭
# - "환경 변수" 버튼 클릭
# - "새로 만들기" 클릭
# - 변수 이름: GEMINI_API_KEY
# - 변수 값: [발급받은 API 키]
# - 확인 클릭
```

#### .env 파일 사용 (프로젝트별)
프로젝트 디렉토리에 `.env` 파일 생성:
```bash
GEMINI_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXXXXX
```

---

### Mac/Linux (Bash/Zsh)

#### 임시 설정
```bash
export GEMINI_API_KEY="AIzaSyXXXXXXXXXXXXXXXXXXXXXXXX"
```

#### 영구 설정
```bash
# Bash 사용자
echo 'export GEMINI_API_KEY="AIzaSyXXXXXXXXXXXXXXXXXXXXXXXX"' >> ~/.bashrc
source ~/.bashrc

# Zsh 사용자
echo 'export GEMINI_API_KEY="AIzaSyXXXXXXXXXXXXXXXXXXXXXXXX"' >> ~/.zshrc
source ~/.zshrc
```

#### .env 파일 사용
```bash
# .env 파일 생성
cat > .env << 'EOF'
GEMINI_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXXXXX
EOF

# 파일 권한 제한 (보안)
chmod 600 .env
```

---

## 기본 사용법

### 방법 1: Python SDK 직접 사용

#### 간단한 텍스트 생성
```python
import google.generativeai as genai
import os

# API 키 설정
genai.configure(api_key=os.environ['GEMINI_API_KEY'])

# 모델 초기화
model = genai.GenerativeModel('gemini-pro')

# 텍스트 생성
response = model.generate_content('파이썬으로 Hello World를 출력하는 방법을 알려줘')
print(response.text)
```

#### 대화형 채팅
```python
model = genai.GenerativeModel('gemini-pro')
chat = model.start_chat(history=[])

response = chat.send_message('안녕! 너는 누구야?')
print(response.text)

response = chat.send_message('Python에 대해 알려줘')
print(response.text)
```

#### 이미지 분석
```python
from PIL import Image

model = genai.GenerativeModel('gemini-pro-vision')
image = Image.open('image.jpg')

response = model.generate_content(['이 이미지에 무엇이 있나요?', image])
print(response.text)
```

---

### 방법 2: 커스텀 CLI 스크립트 사용
(이 가이드에서 제공하는 `gemini-cli.py` 사용)

#### 기본 질의
```bash
python gemini-cli.py "Python으로 피보나치 수열을 구현하는 방법"
```

#### 대화형 모드
```bash
python gemini-cli.py --chat
```

#### 이미지 분석
```bash
python gemini-cli.py --image photo.jpg "이 사진을 설명해줘"
```

#### 파일에서 프롬프트 읽기
```bash
python gemini-cli.py --file prompt.txt
```

---

## 고급 활용

### 스트리밍 응답
```python
model = genai.GenerativeModel('gemini-pro')

response = model.generate_content(
    '긴 이야기를 들려줘',
    stream=True
)

for chunk in response:
    print(chunk.text, end='', flush=True)
```

### 생성 설정 커스터마이징
```python
generation_config = {
    'temperature': 0.7,        # 창의성 (0.0 ~ 1.0)
    'top_p': 0.95,            # 다양성
    'top_k': 40,              # 토큰 선택 범위
    'max_output_tokens': 1024, # 최대 출력 길이
}

model = genai.GenerativeModel(
    'gemini-pro',
    generation_config=generation_config
)

response = model.generate_content('창의적인 이야기를 써줘')
print(response.text)
```

### 안전 설정
```python
from google.generativeai.types import HarmCategory, HarmBlockThreshold

safety_settings = {
    HarmCategory.HARM_CATEGORY_HATE_SPEECH: HarmBlockThreshold.BLOCK_NONE,
    HarmCategory.HARM_CATEGORY_HARASSMENT: HarmBlockThreshold.BLOCK_NONE,
    HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT: HarmBlockThreshold.BLOCK_NONE,
    HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT: HarmBlockThreshold.BLOCK_NONE,
}

model = genai.GenerativeModel(
    'gemini-pro',
    safety_settings=safety_settings
)
```

### 프롬프트 템플릿
```python
template = """
당신은 전문 {role}입니다.
다음 질문에 답변해주세요:

질문: {question}

답변 형식:
- 명확하고 간결하게
- 예시 포함
- 단계별 설명
"""

role = "Python 개발자"
question = "리스트 컴프리헨션이 뭔가요?"

prompt = template.format(role=role, question=question)
response = model.generate_content(prompt)
print(response.text)
```

---

## Python SDK 사용

### 전체 기능 예제

```python
import google.generativeai as genai
import os
from pathlib import Path

# API 키 설정
genai.configure(api_key=os.environ.get('GEMINI_API_KEY'))

# 사용 가능한 모델 목록
for model in genai.list_models():
    if 'generateContent' in model.supported_generation_methods:
        print(f"모델: {model.name}")

# 텍스트 생성
def generate_text(prompt, temperature=0.7):
    model = genai.GenerativeModel('gemini-pro')
    config = {'temperature': temperature}

    response = model.generate_content(
        prompt,
        generation_config=config
    )
    return response.text

# 채팅
def chat_session():
    model = genai.GenerativeModel('gemini-pro')
    chat = model.start_chat(history=[])

    print("채팅 시작! (종료: 'quit')")
    while True:
        user_input = input("\n사용자: ")
        if user_input.lower() in ['quit', 'exit', '종료']:
            break

        response = chat.send_message(user_input)
        print(f"Gemini: {response.text}")

# 이미지 + 텍스트
def analyze_image(image_path, prompt="이미지를 설명해주세요"):
    from PIL import Image

    model = genai.GenerativeModel('gemini-pro-vision')
    image = Image.open(image_path)

    response = model.generate_content([prompt, image])
    return response.text

# 파일 업로드 (긴 문서 처리)
def process_file(file_path, prompt):
    file = genai.upload_file(file_path)
    print(f"업로드 완료: {file.display_name}")

    model = genai.GenerativeModel('gemini-1.5-flash')
    response = model.generate_content([file, prompt])

    return response.text

# 토큰 카운트 확인
def count_tokens(text):
    model = genai.GenerativeModel('gemini-pro')
    token_count = model.count_tokens(text)
    print(f"토큰 수: {token_count.total_tokens}")
    return token_count.total_tokens
```

---

## 문제 해결

### ❌ `ImportError: No module named 'google.generativeai'`

**원인:** SDK 미설치

**해결:**
```bash
pip install google-generativeai
```

---

### ❌ `API key not valid`

**원인:** API 키가 잘못되었거나 만료됨

**해결:**
1. API 키 재확인: https://aistudio.google.com/app/apikey
2. 환경 변수 확인:
   ```bash
   # Windows PowerShell
   echo $env:GEMINI_API_KEY

   # Mac/Linux
   echo $GEMINI_API_KEY
   ```
3. 새 API 키 발급

---

### ❌ `ResourceExhausted: 429 Quota exceeded`

**원인:** API 사용량 한도 초과

**해결:**
1. API 사용량 확인: https://console.cloud.google.com/
2. 잠시 대기 후 재시도 (무료 플랜은 분당 요청 제한)
3. 필요시 유료 플랜으로 업그레이드

---

### ❌ `PermissionDenied: API has not been enabled`

**원인:** Generative Language API 미활성화

**해결:**
1. https://console.cloud.google.com/apis/library 접속
2. "Generative Language API" 검색
3. "사용 설정" 클릭

---

### ❌ 환경 변수가 인식되지 않음

**Windows:**
```powershell
# PowerShell 재시작 후 확인
Get-ChildItem Env:GEMINI_API_KEY
```

**Mac/Linux:**
```bash
# 터미널 재시작 후 확인
printenv | grep GEMINI_API_KEY
```

---

## 요금 정보

### 무료 플랜
- **모델:** gemini-pro, gemini-pro-vision
- **제한:** 분당 60 요청, 일일 1,500 요청
- **비용:** 무료

### 유료 플랜
- **모델:** gemini-1.5-pro, gemini-1.5-flash
- **가격:** 사용량에 따라 과금
- 자세한 정보: https://ai.google.dev/pricing

---

## 보안 권장사항

### 1. API 키 보안
```bash
# .gitignore에 추가
echo ".env" >> .gitignore
echo "*.key" >> .gitignore
```

### 2. 환경 변수 사용
코드에 API 키를 하드코딩하지 마세요:

❌ **나쁜 예:**
```python
genai.configure(api_key="AIzaSyXXXXXXXXXXXXXXX")
```

✅ **좋은 예:**
```python
import os
genai.configure(api_key=os.environ['GEMINI_API_KEY'])
```

### 3. .env 파일 권한
```bash
chmod 600 .env
```

---

## 참고 자료

- [Google AI Studio](https://aistudio.google.com/)
- [Gemini API 공식 문서](https://ai.google.dev/docs)
- [Python SDK 가이드](https://ai.google.dev/tutorials/python_quickstart)
- [API 가격 정책](https://ai.google.dev/pricing)
- [Community Forum](https://discuss.ai.google.dev/)

---

**즉시 실행 가능한 명령어는 다음 섹션에서 제공됩니다!** 🚀
