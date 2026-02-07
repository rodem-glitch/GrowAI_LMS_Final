# 🎨 GrowAI-MAP UI/UX 가이드라인 (Standardization)

이 문서는 GrowAI 플랫폼의 일관된 UI/UX 구현을 위한 표준 가이드라인입니다. 모든 신규 컴포넌트 개발 및 기존 코드 수정 시 이 명세를 엄격히 준수합니다.

---

## 1. 기술 스택 (Tech Stack)
* **Framework:** Vue 3 (^3.5.24)
* **Styling:** Tailwind CSS v4 (^4.1.18)
* **Build Tool:** Vite 7 (^7.2.4)
* **Main Directory:** `src/components/`, `src/views/` (또는 `src/pages/`)

---

## 2. 색상 팔레트 (Color Palette)
Pluralsight/Cloud Guru 스타일의 다크 모드 기반 액센트 테마를 사용합니다.

| 변수명 | HEX | 용도 |
| :--- | :--- | :--- |
| `--color-primary` | `#130f25` | 메인 다크 (헤더, 배경) |
| `--color-primary-light` | `#2a2753` | 서브 다크 (그라디언트 요소) |
| `--color-accent` | `#e7005e` | **Primary Pink** (CTA, 주요 버튼) |
| `--color-accent-dark` | `#b7094a` | 호버 시 액센트 |
| `--color-neutral-100` | `#f7f5f4` | 밝은 배경/호버 효과 |
| `--color-neutral-200` | `#e5e5e5` | 보더(Border), 구분선 |
| `--color-neutral-300` | `#a5aacf` | 서브 텍스트 (Light) |
| `--color-neutral-400` | `#555555` | 기본 본문 텍스트 |

### 🌈 기능별 그라디언트 (Features Section)
* **Blue:** `#0ea5e9` → `#0284c7`
* **Purple:** `#8b5cf6` → `#7c3aed`
* **Green:** `#10b981` → `#059669`
* **Orange:** `#f59e0b` → `#d97706`

---

## 3. 레이아웃 & 시스템 규칙 (Layout & Spacing)
* **Container:** `max-w-7xl mx-auto px-4 sm:px-6 lg:px-8`
* **Section Vertical Padding:** `py-16 lg:py-24`
* **Grid Gap:** `gap-8` ~ `gap-12`
* **Transitions:** `transition-all duration-275` (기본), `duration-300` (카드 호버)

---

## 4. 컴포넌트 표준 스타일 (Component Standards)

### 🔘 Buttons
* **Primary (CTA):** `bg-[#e7005e] hover:bg-[#b7094a] text-white px-8 py-4 rounded-full font-semibold`
* **Secondary:** `border-2 border-white hover:bg-white hover:text-[#130f25] px-8 py-4 rounded-full`
* **Small:** `px-6 py-3 rounded-full`

### 🗂 Cards
* **Default:** `bg-white rounded-2xl p-8 border border-[#e5e5e5] hover:border-[#e7005e] hover:shadow-xl`

### ⌨️ Form Fields
* **Input:** `w-full px-4 py-3 border border-[#e5e5e5] rounded-lg focus:outline-none focus:ring-2 focus:ring-[#e7005e] focus:border-transparent`

---

## 5. 타이포그래피 (Typography)
* **Font Family:** `Inter`, `PS TT Commons Regular`, sans-serif
* **H1 (Hero):** `text-4xl lg:text-5xl xl:text-6xl font-bold`
* **H2 (Section):** `text-3xl lg:text-4xl font-bold`
* **H3 (Card):** `text-xl font-semibold`
* **Body:** `text-lg` (중요 본문), `text-base` (기본 본문)

---

## 6. 애니메이션 (Animations)
* **Entry:** `.animate-fade-in-up` (0.6s), `.animate-slide-in-right` (0.4s)
* **Hover:** `transition-transform duration-500` (큰 변환 효과 시)
