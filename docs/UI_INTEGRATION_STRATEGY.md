# UI 통합 전략 (Legacy + Modern)

> **작성일**: 2026-02-07
> **목표**: Legacy JSP UI와 교수자 React SPA의 톤앤매너 통일
> **대상**: 학생 LMS, 교수자 LMS, 관리자 페이지

---

## Executive Summary

| 항목 | 현재 | 목표 | 전략 |
|------|------|------|------|
| **테마** | 혼재 (Light/Dark) | 다크 테마 통일 | CSS 변수 기반 |
| **컴포넌트** | 개별 구현 | 공유 라이브러리 | Design Token |
| **마이그레이션** | - | 3단계 점진적 | Phase별 적용 |

---

## 1. 현황 분석

### 1.1 Legacy JSP (학생 LMS)

| 항목 | 현재 값 |
|------|---------|
| 배경색 | `#f9fafb` (라이트 그레이) |
| 헤더 | `#ffffff` (흰색) |
| 테두리 | `#e5e7eb` |
| 텍스트 | `#101828` (다크) |
| 폰트 | Pretendard |
| 프레임워크 | jQuery 1.12.3, Swiper 11 |

### 1.2 교수자 LMS (React SPA)

| 항목 | 현재 값 |
|------|---------|
| 배경색 | `#0a0a12` (다크) |
| 사이드바 | `#1a1a2e` |
| 카드 | `#252542` |
| 액센트 | `#e7005e` (핑크) |
| 골드 | `#d4af37` |
| 폰트 | Pretendard |
| 프레임워크 | React 18, Tailwind v4 |

---

## 2. 통합 디자인 시스템

### 2.1 Design Tokens (공통)

```css
:root {
  /* ===== Primary Colors (Dark Theme) ===== */
  --color-bg-primary: #0a0a12;
  --color-bg-secondary: #1a1a2e;
  --color-bg-tertiary: #252542;
  --color-bg-card: #2a2753;

  /* ===== Accent Colors ===== */
  --color-accent: #e7005e;
  --color-accent-hover: #b7094a;
  --color-gold: #d4af37;
  --color-gold-light: #f4e5b8;

  /* ===== Text Colors ===== */
  --color-text-primary: #f8f9fc;
  --color-text-secondary: #9194b3;
  --color-text-muted: #6b7280;

  /* ===== Status Colors ===== */
  --color-success: #10b981;
  --color-warning: #f59e0b;
  --color-error: #ef4444;
  --color-info: #3b82f6;

  /* ===== Border & Shadow ===== */
  --color-border: rgba(255, 255, 255, 0.08);
  --color-border-hover: var(--color-accent);
  --shadow-card: 0 4px 24px rgba(0, 0, 0, 0.3);
  --shadow-glow: 0 0 20px rgba(231, 0, 94, 0.3);

  /* ===== Typography ===== */
  --font-family: 'Pretendard', -apple-system, BlinkMacSystemFont, sans-serif;
  --font-size-xs: 0.75rem;
  --font-size-sm: 0.875rem;
  --font-size-base: 1rem;
  --font-size-lg: 1.125rem;
  --font-size-xl: 1.25rem;
  --font-size-2xl: 1.5rem;
  --font-size-3xl: 2rem;

  /* ===== Spacing ===== */
  --spacing-xs: 0.25rem;
  --spacing-sm: 0.5rem;
  --spacing-md: 1rem;
  --spacing-lg: 1.5rem;
  --spacing-xl: 2rem;
  --spacing-2xl: 3rem;

  /* ===== Border Radius ===== */
  --radius-sm: 0.375rem;
  --radius-md: 0.5rem;
  --radius-lg: 0.75rem;
  --radius-xl: 1rem;
  --radius-2xl: 1.5rem;
  --radius-full: 9999px;

  /* ===== Transitions ===== */
  --transition-fast: 150ms ease;
  --transition-normal: 275ms ease;
  --transition-slow: 300ms ease;
  --transition-spring: cubic-bezier(0.16, 1, 0.3, 1);
}
```

### 2.2 공통 컴포넌트 스타일

```css
/* ===== Button (Primary) ===== */
.btn-primary {
  background: var(--color-accent);
  color: white;
  padding: 0.75rem 1.5rem;
  border-radius: var(--radius-full);
  font-weight: 600;
  transition: all var(--transition-normal);
  border: none;
  cursor: pointer;
}
.btn-primary:hover {
  background: var(--color-accent-hover);
  box-shadow: var(--shadow-glow);
  transform: translateY(-2px);
}

/* ===== Card ===== */
.card {
  background: var(--color-bg-card);
  border-radius: var(--radius-2xl);
  padding: var(--spacing-xl);
  border: 1px solid var(--color-border);
  transition: all var(--transition-slow);
}
.card:hover {
  border-color: var(--color-accent);
  transform: translateY(-4px);
  box-shadow: var(--shadow-card);
}

/* ===== Input ===== */
.input {
  background: var(--color-bg-tertiary);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: 0.75rem 1rem;
  color: var(--color-text-primary);
  transition: border-color var(--transition-fast);
}
.input:focus {
  border-color: var(--color-accent);
  outline: none;
}

/* ===== Glass Effect ===== */
.glass {
  background: rgba(255, 255, 255, 0.03);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.08);
}
```

---

## 3. 마이그레이션 전략

### Phase 1: 공통 CSS 적용 (1주)

| 작업 | 파일 | 내용 |
|------|------|------|
| 1.1 | `/common/css/unified-theme.css` | Design Token CSS 생성 |
| 1.2 | `skin5.css` 수정 | 변수 기반으로 전환 |
| 1.3 | Legacy 페이지 테스트 | 호환성 검증 |

**적용 방법:**
```html
<!-- Legacy JSP에 추가 -->
<link rel="stylesheet" href="/common/css/unified-theme.css" />
<body class="theme-dark">
```

### Phase 2: 핵심 컴포넌트 변환 (2주)

| 우선순위 | 컴포넌트 | Before | After |
|----------|----------|--------|-------|
| P0 | Header | 흰색 배경 | 다크 그라데이션 |
| P0 | Navigation | 회색 텍스트 | 핑크 액센트 |
| P1 | Card | 흰색 카드 | Glass 효과 |
| P1 | Button | 파란색 | 핑크 라운드 |
| P2 | Form | 기본 스타일 | 다크 입력창 |
| P2 | Table | 회색 테두리 | 투명 테두리 |

### Phase 3: 페이지별 적용 (3주)

| 주차 | 페이지 | 영향 범위 |
|------|--------|-----------|
| 1주차 | 메인 페이지 (`index.jsp`) | Header, Hero, Footer |
| 2주차 | 마이페이지 (`/mypage/*`) | 대시보드, 프로필 |
| 3주차 | 학습 페이지 (`/study/*`) | 강의 목록, 플레이어 |

---

## 4. 구현 가이드

### 4.1 Legacy JSP 변환 예시

**Before (라이트 테마):**
```css
.nm-header {
  background: #fff;
  border-bottom: 1px solid #e5e7eb;
}
.nm-header__logo-text {
  color: #101828;
}
```

**After (다크 테마):**
```css
.nm-header {
  background: linear-gradient(135deg, var(--color-bg-primary) 0%, var(--color-bg-secondary) 100%);
  border-bottom: 1px solid var(--color-border);
}
.nm-header__logo-text {
  color: var(--color-text-primary);
}
```

### 4.2 컴포넌트 매핑

| Legacy Class | Unified Class | 설명 |
|--------------|---------------|------|
| `.btn-primary` | `.btn-accent` | 액센트 버튼 |
| `.card` | `.card-glass` | 글래스 카드 |
| `.form-control` | `.input-dark` | 다크 입력창 |
| `.table` | `.table-transparent` | 투명 테이블 |

---

## 5. 파일 구조

```
/common/css/
├── unified-theme.css      ← Design Tokens (신규)
├── unified-components.css ← 공통 컴포넌트 (신규)
├── skin5.css              ← Legacy 기본 스타일 (수정)
└── dark-override.css      ← 다크 테마 오버라이드 (신규)

/tutor_lms/app/
├── src/
│   └── styles/
│       └── tokens.css     ← React용 토큰 (동일)
```

---

## 6. 비교 시각화

### Before (현재)

```
┌──────────────────────────────────────────────────────────────┐
│ Legacy JSP (Light Theme)    │ React SPA (Dark Theme)         │
├──────────────────────────────────────────────────────────────┤
│ ┌────────────────────────┐  │ ┌────────────────────────────┐ │
│ │ ░░░░░ Header ░░░░░░░░░ │  │ │ ████ Header ████████████  │ │
│ │ Background: #ffffff    │  │ │ Background: #0a0a12       │ │
│ ├────────────────────────┤  │ ├────────────────────────────┤ │
│ │                        │  │ │                            │ │
│ │  ┌──────┐  ┌──────┐   │  │ │  ┌──────┐  ┌──────┐       │ │
│ │  │ Card │  │ Card │   │  │ │  │ Card │  │ Card │       │ │
│ │  │ #fff │  │ #fff │   │  │ │  │#2a27│  │#2a27│       │ │
│ │  └──────┘  └──────┘   │  │ │  └──────┘  └──────┘       │ │
│ │                        │  │ │                            │ │
│ └────────────────────────┘  │ └────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

### After (통합)

```
┌──────────────────────────────────────────────────────────────┐
│                  Unified Dark Theme                          │
├──────────────────────────────────────────────────────────────┤
│ ┌────────────────────────────────────────────────────────┐   │
│ │ ████████████ Header ████████████████████████████████   │   │
│ │ Background: linear-gradient(#0a0a12, #1a1a2e)         │   │
│ │ Accent: #e7005e                                        │   │
│ ├────────────────────────────────────────────────────────┤   │
│ │                                                        │   │
│ │  ┌──────────────┐  ┌──────────────┐  ┌────────────┐   │   │
│ │  │ ▓▓ Card ▓▓▓ │  │ ▓▓ Card ▓▓▓ │  │ ▓▓ Card ▓▓ │   │   │
│ │  │ Glass Effect │  │ Glass Effect │  │ Glass Eff. │   │   │
│ │  │ #2a2753      │  │ #2a2753      │  │ #2a2753    │   │   │
│ │  │ hover: glow  │  │ hover: glow  │  │ hover:glow │   │   │
│ │  └──────────────┘  └──────────────┘  └────────────┘   │   │
│ │                                                        │   │
│ └────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────┘
```

---

## 7. 일정

| Phase | 기간 | 산출물 |
|-------|------|--------|
| Phase 1 | 2/10 - 2/14 | unified-theme.css |
| Phase 2 | 2/17 - 2/28 | 핵심 컴포넌트 변환 |
| Phase 3 | 3/3 - 3/21 | 전체 페이지 적용 |
| QA | 3/24 - 3/28 | 통합 테스트 |

**총 예상 기간: 7주**

---

## 8. 체크리스트

### Phase 1 완료 조건
- [ ] Design Token CSS 생성
- [ ] Legacy 페이지에 CSS 변수 적용
- [ ] 다크 테마 전환 검증

### Phase 2 완료 조건
- [ ] Header 컴포넌트 통일
- [ ] Navigation 액센트 적용
- [ ] Card/Button 스타일 변환
- [ ] Form 입력창 다크 테마

### Phase 3 완료 조건
- [ ] 메인 페이지 완전 적용
- [ ] 마이페이지 완전 적용
- [ ] 학습 페이지 완전 적용
- [ ] 크로스 브라우저 테스트

---

**작성자**: Claude AI
**승인자**: [담당자명]
**상태**: 전략 수립 완료
