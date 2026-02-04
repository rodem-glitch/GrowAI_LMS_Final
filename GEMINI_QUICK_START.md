# 🚀 Gemini CLI 즉시 실행 가이드

## 1단계: API 키 발급 (3분)

### ✅ 체크리스트
1. https://aistudio.google.com/app/apikey 접속
2. Google 계정 로그인
3. "Create API Key" 클릭
4. API 키 복사 (예: `AIzaSyXXXXXXXXXXXXXXX`)

---

## 2단계: 환경 설정 (1분)

### Windows 사용자

**PowerShell 열기** → 다음 명령 실행:

```powershell
# API 키 환경 변수 설정 (발급받은 키로 변경)
$env:GEMINI_API_KEY = "AIzaSyXXXXXXXXXXXXXXX"

# 확인
echo $env:GEMINI_API_KEY
```

### Mac/Linux 사용자

**터미널 열기** → 다음 명령 실행:

```bash
# API 키 환경 변수 설정 (발급받은 키로 변경)
export GEMINI_API_KEY="AIzaSyXXXXXXXXXXXXXXX"

# 확인
echo $GEMINI_API_KEY
```

---

## 3단계: Python 패키지 설치 (1분)

```bash
pip install -r requirements-gemini.txt
```

또는 개별 설치:

```bash
pip install google-generativeai python-dotenv Pillow
```

---

## 4단계: 즉시 실행! ⚡

### 테스트 1: 간단한 질문

```bash
python gemini-cli.py "Python으로 Hello World를 출력하는 방법을 알려줘"
```

**예상 출력:**
```
✅ Gemini API 인증 성공!

Python에서 "Hello World"를 출력하는 방법은 매우 간단합니다:

print("Hello World")

이 한 줄의 코드만으로 콘솔에 "Hello World"가 출력됩니다.
```

---

### 테스트 2: 대화형 채팅

```bash
python gemini-cli.py --chat
```

**사용 예시:**
```
사용자: 안녕! 너는 누구야?
Gemini: 안녕하세요! 저는 구글이 개발한 대규모 언어 모델 Gemini입니다...

사용자: Python을 배우고 싶은데 어디서부터 시작하면 좋을까?
Gemini: Python 학습을 시작하시려면...

사용자: /exit
👋 채팅을 종료합니다.
```

---

### 테스트 3: 코드 생성

```bash
python gemini-cli.py "Python으로 피보나치 수열을 생성하는 함수를 만들어줘"
```

---

### 테스트 4: 스트리밍 출력

```bash
python gemini-cli.py --stream "우주에 대한 흥미로운 사실 10가지를 알려줘"
```

---

### 테스트 5: 이미지 분석 (선택)

```bash
# 이미지 파일이 있는 경우
python gemini-cli.py --image photo.jpg "이 사진에 무엇이 있나요?"
```

---

### 테스트 6: 파일 처리 (선택)

```bash
# 텍스트 파일 요약
python gemini-cli.py --file README.md "이 문서를 한 문단으로 요약해줘"
```

---

### 테스트 7: 모델 목록 보기

```bash
python gemini-cli.py --list-models
```

---

## 5단계: 고급 사용법

### 창의성 조절

```bash
# 보수적 (정확하고 일관성 있음)
python gemini-cli.py --temperature 0.2 "프로그래밍 베스트 프랙티스"

# 창의적 (다양하고 창의적)
python gemini-cli.py --temperature 0.9 "판타지 소설 아이디어"
```

---

### 다른 모델 사용

```bash
# Gemini 1.5 Pro (더 강력함)
python gemini-cli.py --model gemini-1.5-pro "복잡한 수학 문제 풀이"

# Gemini 1.5 Flash (빠르고 효율적)
python gemini-cli.py --model gemini-1.5-flash "간단한 질문"
```

---

## 전체 명령어 옵션

```bash
python gemini-cli.py [옵션] "프롬프트"

옵션:
  --chat              대화형 채팅 모드
  --image FILE        이미지 파일 분석
  --file FILE         파일 처리
  --model MODEL       사용할 모델 (기본: gemini-pro)
  --temperature 0.7   창의성 (0.0 ~ 1.0)
  --stream            스트리밍 출력
  --api-key KEY       API 키 직접 전달
  --list-models       모델 목록 보기
  -h, --help          도움말
```

---

## 실전 예제

### 1. 코드 리뷰

```bash
python gemini-cli.py "다음 Python 코드를 리뷰해줘:
def calc(a,b):
  return a+b
"
```

---

### 2. 디버깅 도움

```bash
python gemini-cli.py "이 오류를 어떻게 해결하나요?
TypeError: 'int' object is not subscriptable
"
```

---

### 3. 번역

```bash
python gemini-cli.py "다음을 영어로 번역해줘: 안녕하세요, 반갑습니다."
```

---

### 4. 문서 작성

```bash
python gemini-cli.py "Python 함수 add(a, b)에 대한 docstring을 작성해줘"
```

---

### 5. 학습 도우미

```bash
python gemini-cli.py --chat
# 채팅에서: "Python의 데코레이터가 뭔가요? 예제와 함께 설명해주세요"
```

---

## 문제 해결

### ❌ "API key not valid"

```bash
# API 키 재설정
# Windows
$env:GEMINI_API_KEY = "새_API_키"

# Mac/Linux
export GEMINI_API_KEY="새_API_키"
```

---

### ❌ "ModuleNotFoundError"

```bash
pip install google-generativeai
```

---

### ❌ "429 Quota exceeded"

**원인:** 무료 플랜 한도 초과 (분당 60 요청)

**해결:** 잠시 대기 후 재시도

---

### ❌ 환경 변수가 사라짐 (재부팅 후)

**영구 설정:**

**Windows:**
```powershell
[System.Environment]::SetEnvironmentVariable('GEMINI_API_KEY', 'YOUR_API_KEY', 'User')
```

**Mac/Linux:**
```bash
# .bashrc 또는 .zshrc에 추가
echo 'export GEMINI_API_KEY="YOUR_API_KEY"' >> ~/.bashrc
source ~/.bashrc
```

---

## .env 파일 사용 (권장)

프로젝트 디렉토리에 `.env` 파일 생성:

```bash
GEMINI_API_KEY=AIzaSyXXXXXXXXXXXXXXX
```

이제 환경 변수 설정 없이 바로 실행 가능!

```bash
python gemini-cli.py "질문"
```

---

## 성공 확인 ✅

다음 명령이 정상 작동하면 설정 완료:

```bash
python gemini-cli.py "안녕하세요"
```

**정상 출력:**
```
✅ Gemini API 인증 성공!

안녕하세요! 무엇을 도와드릴까요?
```

---

**이제 Gemini CLI를 자유롭게 사용하세요!** 🎉
