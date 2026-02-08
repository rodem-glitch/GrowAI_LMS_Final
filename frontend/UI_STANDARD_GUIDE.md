# GrowAILMS UI Standard Guide

> MidCheck.tsx 디자인 분석 기반 — 프론트엔드 개발자 참조 문서
>
> **Last Updated**: 2026-02-08 &nbsp;|&nbsp; **Stack**: React 18 + TypeScript + Tailwind CSS 3.4 + Vite 5

---

## 1. Color Palette

### 1.1 Primary Colors (Blue → Indigo)

| Swatch | Token | Hex | CSS Variable | Usage |
|--------|-------|-----|--------------|-------|
| ![#eff6ff](https://via.placeholder.com/16/eff6ff/eff6ff) | `primary-50` | `#eff6ff` | `--color-primary-50` | 배경 하이라이트, 호버 상태 |
| ![#dbeafe](https://via.placeholder.com/16/dbeafe/dbeafe) | `primary-100` | `#dbeafe` | `--color-primary-100` | 알림 배경, 선택 상태 |
| ![#bfdbfe](https://via.placeholder.com/16/bfdbfe/bfdbfe) | `primary-200` | `#bfdbfe` | `--color-primary-200` | 비활성 보더 |
| ![#93c5fd](https://via.placeholder.com/16/93c5fd/93c5fd) | `primary-300` | `#93c5fd` | `--color-primary-300` | 아이콘, 장식 요소 |
| ![#60a5fa](https://via.placeholder.com/16/60a5fa/60a5fa) | `primary-400` | `#60a5fa` | `--color-primary-400` | 링크 호버 |
| ![#3b82f6](https://via.placeholder.com/16/3b82f6/3b82f6) | `primary-500` | `#3b82f6` | `--color-primary-500` | 인터랙티브 요소 |
| ![#2563eb](https://via.placeholder.com/16/2563eb/2563eb) | **`primary-600`** | `#2563eb` | `--color-primary` | **기본 CTA 버튼, 링크** |
| ![#1d4ed8](https://via.placeholder.com/16/1d4ed8/1d4ed8) | `primary-700` | `#1d4ed8` | `--color-primary-700` | 호버 상태 버튼 |
| ![#1e40af](https://via.placeholder.com/16/1e40af/1e40af) | `primary-800` | `#1e40af` | `--color-primary-800` | 다크모드 강조 |
| ![#1e3a8a](https://via.placeholder.com/16/1e3a8a/1e3a8a) | `primary-900` | `#1e3a8a` | `--color-primary-900` | 다크모드 텍스트 |

### 1.2 Secondary Colors (Purple → Violet)

| Swatch | Token | Hex | CSS Variable | Usage |
|--------|-------|-----|--------------|-------|
| ![#faf5ff](https://via.placeholder.com/16/faf5ff/faf5ff) | `secondary-50` | `#faf5ff` | `--color-secondary-50` | AI 기능 배경 |
| ![#f3e8ff](https://via.placeholder.com/16/f3e8ff/f3e8ff) | `secondary-100` | `#f3e8ff` | `--color-secondary-100` | AI 배너 배경 |
| ![#e9d5ff](https://via.placeholder.com/16/e9d5ff/e9d5ff) | `secondary-200` | `#e9d5ff` | `--color-secondary-200` | 보더 장식 |
| ![#a855f7](https://via.placeholder.com/16/a855f7/a855f7) | `secondary-500` | `#a855f7` | `--color-secondary-500` | 프로그레스 바, 그라디언트 시작 |
| ![#9333ea](https://via.placeholder.com/16/9333ea/9333ea) | **`secondary-600`** | `#9333ea` | `--color-secondary` | **AI/특수 기능 CTA** |
| ![#7e22ce](https://via.placeholder.com/16/7e22ce/7e22ce) | `secondary-700` | `#7e22ce` | `--color-secondary-700` | 호버 상태 |

### 1.3 Semantic Colors

| Category | Default | 50 (BG) | 600~700 (Text) | Usage |
|----------|---------|---------|----------------|-------|
| **Success** | `#10b981` | `#ecfdf5` | `#059669` | 완료 상태, 성공 알림, 출석 확인 |
| **Warning** | `#f59e0b` | `#fffbeb` | `#d97706` | 주의 알림, 진행중 상태 |
| **Danger** | `#ef4444` | `#fef2f2` | `#dc2626` | 오류, 차단 상태, 삭제 액션 |
| **Info** | `#06b6d4` | `#ecfeff` | — | 정보 알림, 도움말 |

### 1.4 Surface & Content Colors

| Token | Light Mode | Dark Mode | Usage |
|-------|-----------|-----------|-------|
| `surface-default` | `#ffffff` | `#0f172a` | 페이지/카드 배경 |
| `surface-muted` | `#f9fafb` | `#1e293b` | 섹션 배경, 테이블 헤더 |
| `surface-subtle` | `#f3f4f6` | `#334155` | 인풋 배경, 스크롤바 트랙 |
| `surface-border` | `#e5e7eb` | `#475569` | 구분선, 카드 보더 |
| `content-default` | `#111827` | `#f1f5f9` | 본문 텍스트 |
| `content-secondary` | `#4b5563` | `#cbd5e1` | 부제목, 설명 텍스트 |
| `content-muted` | `#9ca3af` | `#64748b` | 플레이스홀더, 비활성 텍스트 |
| `content-subtle` | `#6b7280` | `#94a3b8` | 메타데이터, 타임스탬프 |

### 1.5 KOPO Brand Colors

| Token | Hex | Usage |
|-------|-----|-------|
| `kopo-blue` | `#004990` | 기관 로고, 공식 헤더 |
| `kopo-light` | `#0066cc` | 링크, 서브 브랜드 |
| `kopo-dark` | `#003366` | 호버, 강조 |

---

## 2. Typography

### 2.1 Font Family

```css
--font-sans: 'Pretendard', -apple-system, BlinkMacSystemFont, system-ui,
  Roboto, 'Helvetica Neue', 'Segoe UI', 'Apple SD Gothic Neo',
  'Malgun Gothic', sans-serif;

--font-mono: ui-monospace, SFMono-Regular, 'SF Mono', Menlo, Consolas,
  'Liberation Mono', monospace;
```

> **Pretendard**는 한국어 최적화 가변 폰트입니다. CDN 또는 로컬로 제공합니다.

### 2.2 Type Scale

| Level | Tailwind Class | Size | Weight | Line Height | Usage |
|-------|---------------|------|--------|-------------|-------|
| **H1** | `text-2xl font-bold` | 24px | 700 | 1.25 | 페이지 타이틀 |
| **H2** | `text-xl font-bold` | 20px | 700 | 1.25 | 섹션 헤더 |
| **H3** | `text-lg font-semibold` | 18px | 600 | 1.25 | 카드 타이틀 |
| **H4** | `text-base font-semibold` | 16px | 600 | 1.5 | 서브섹션 헤더 |
| **Body** | `text-sm` | 14px | 400 | 1.5 | 본문 텍스트 |
| **Body Small** | `text-xs` | 12px | 400 | 1.5 | 부가 설명, 메타 정보 |
| **Tiny** | `text-tiny` (custom) | 11px | 400 | 16px | 테이블 셀, AI 요약 |
| **Micro** | `text-micro` (custom) | 10px | 500 | 14px | 뱃지, 타임스탬프 |

### 2.3 Font Weight 규칙

| Weight | Tailwind | Usage |
|--------|----------|-------|
| 400 | `font-normal` | 본문, 설명 텍스트 |
| 500 | `font-medium` | 버튼, 뱃지, 라벨 |
| 600 | `font-semibold` | 카드 타이틀, 서브헤더 |
| 700 | `font-bold` | 페이지 타이틀, 수치 강조 |

---

## 3. Layout Rules

### 3.1 Container & Page Structure

```
┌─────────────────────────────────────────────────────┐
│  .page-header  (max-w-7xl mx-auto px-6 py-4)       │
├─────────────────────────────────────────────────────┤
│  .page-container  (max-w-7xl mx-auto px-6 py-8)    │
│  ┌─────────────────────────────────────────────┐    │
│  │  Content Area                                │    │
│  └─────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘
```

| Token | Value | Tailwind | Description |
|-------|-------|----------|-------------|
| Max Width | 1280px | `max-w-7xl` | 콘텐츠 최대 너비 |
| Page Padding X | 24px | `px-6` | 좌우 여백 |
| Page Padding Y | 32px | `py-8` | 상하 여백 (콘텐츠) |
| Header Padding Y | 16px | `py-4` | 상하 여백 (헤더) |
| Sidebar Width | 224px | `w-sidebar` / `w-56` | 사이드바 너비 |

### 3.2 Spacing Scale

| Token | Value | Tailwind | Usage |
|-------|-------|----------|-------|
| `--space-1` | 4px | `p-1`, `gap-1` | 아이콘-텍스트 갭 |
| `--space-2` | 8px | `p-2`, `gap-2` | 인라인 요소 간격 |
| `--space-3` | 12px | `p-3`, `gap-3` | 카드 내부 패딩 (compact) |
| `--space-4` | 16px | `p-4`, `gap-4` | 카드 패딩, 섹션 갭 |
| `--space-5` | 20px | `p-5`, `gap-5` | 확장 카드 패딩 |
| `--space-6` | 24px | `p-6`, `gap-6` | 그리드 갭, 페이지 패딩 |
| `--space-8` | 32px | `p-8`, `gap-8` | 섹션 간 여백 |
| `4.5` (custom) | 18px | `gap-4.5` | 중간 갭 |

### 3.3 Grid System

| Pattern | Tailwind | Usage |
|---------|----------|-------|
| 6-column stats | `grid grid-cols-6 gap-4` | 대시보드 통계 카드 |
| 5-column grid | `grid grid-cols-5 gap-2` | 컴팩트 항목 나열 |
| 4-column grid | `grid grid-cols-4 gap-2` | 뱃지/태그 그리드 |
| 3-column grid | `grid grid-cols-3 gap-2` | 상태 표시 |
| 2-column layout | `grid grid-cols-1 lg:grid-cols-2 gap-6` | 카드 2열 반응형 |
| Vertical stack | `space-y-4` ~ `space-y-6` | 카드 리스트 |

### 3.4 Responsive Breakpoints

| Breakpoint | Min Width | Tailwind Prefix | Usage |
|-----------|-----------|-----------------|-------|
| Mobile | 0px | (default) | 1-column, 풀 너비 |
| Tablet | 768px | `md:` | 2-column 그리드 시작 |
| Desktop | 1024px | `lg:` | `lg:grid-cols-2` 등 |
| Wide | 1280px | `xl:` | max-w-7xl 컨테이너 |

> **참고**: MidCheck.tsx는 데스크톱 우선 설계이며, 반응형은 `lg:` 프리픽스를 주로 사용합니다.

### 3.5 Border Radius

| Token | Value | Tailwind | Usage |
|-------|-------|----------|-------|
| `--radius-sm` | 6px | `rounded-md` | 뱃지 (micro), 작은 요소 |
| `--radius-md` | 8px | `rounded-lg` | 버튼, 인풋, 알림 |
| `--radius-lg` | 12px | `rounded-xl` | 카드 |
| `--radius-2xl` | 24px | `rounded-2xl` | 비디오 플레이어 셸 |
| `--radius-full` | 9999px | `rounded-full` | 뱃지, 아이콘 버튼, 필터 칩 |

### 3.6 Shadows

| Token | CSS Value | Tailwind | Usage |
|-------|-----------|----------|-------|
| `card` | `0 2px 8px rgba(16,24,40,0.06)` | `shadow-card` | 기본 카드 |
| `card-hover` | `0 8px 24px rgba(16,24,40,0.1)` | `shadow-card-hover` | 카드 호버 |
| `primary` | `0 10px 15px -3px rgba(59,130,246,0.25)` | `shadow-primary` | Primary 버튼 |
| `secondary` | `0 10px 15px -3px rgba(168,85,247,0.3)` | `shadow-secondary` | Play 버튼 |
| `ring` | `0 0 0 2px rgba(59,130,246,0.2)` | `shadow-ring-primary` | 포커스 링 |

---

## 4. Component Reference

### 4.1 Cards

```tsx
// 기본 카드
<div className="card">...</div>

// 호버 효과 카드
<div className="card-hover">...</div>

// 컴팩트 카드 (p-4)
<div className="card-compact">...</div>

// 다크 서피스 카드 (비디오 플레이어)
<div className="card-dark">...</div>

// 음영 배경 카드
<div className="card-muted">...</div>
```

### 4.2 Buttons

```tsx
// Primary (그라디언트)
<button className="btn-primary">
  <CheckCircle2 className="w-4 h-4" /> 저장
</button>

// Secondary
<button className="btn-secondary">취소</button>

// Ghost
<button className="btn-ghost">더보기</button>

// Play (보라 그라디언트)
<button className="btn-play w-9 h-9">
  <Play className="w-4 h-4" />
</button>

// 사이즈 조절: btn + btn-sm | btn-md | btn-lg
<button className="btn btn-lg bg-primary text-white">큰 버튼</button>
```

### 4.3 Badges

```tsx
// 기본 뱃지
<span className="badge badge-success">완료</span>
<span className="badge badge-info">진행중</span>
<span className="badge badge-warning">대기</span>
<span className="badge badge-danger">차단</span>

// 소형 뱃지 (10px)
<span className="badge-sm badge-purple">AI</span>

// 마이크로 뱃지
<span className="badge-micro badge-gray">v1.0</span>
```

### 4.4 Alerts

```tsx
<div className="alert alert-info">
  <AlertCircle className="w-4 h-4 shrink-0" />
  <span>정보 메시지입니다.</span>
</div>

<div className="alert alert-success">...</div>
<div className="alert alert-warning">...</div>
<div className="alert alert-danger">...</div>
<div className="alert alert-purple">AI 추천 안내</div>
```

### 4.5 Tables

```tsx
<div className="table-container">
  <table className="w-full">
    <thead className="table-head">
      <tr>
        <th className="table-th">항목</th>
        <th className="table-th-center">상태</th>
      </tr>
    </thead>
    <tbody>
      <tr className="table-row">
        <td className="table-td">학사연동</td>
        <td className="table-td-center">
          <span className="badge-sm badge-success">완료</span>
        </td>
      </tr>
    </tbody>
  </table>
</div>
```

### 4.6 Progress Bar

```tsx
<div className="progress-track">
  <div className="progress-fill" style={{ width: '75%' }} />
</div>

// 성공(녹색) 변형
<div className="progress-track">
  <div className="progress-fill-success" style={{ width: '100%' }} />
</div>
```

### 4.7 Status Indicators

```tsx
// 점 형태
<span className="status-dot status-completed" />
<span className="status-dot status-inprogress" />
<span className="status-dot status-pending" />
<span className="status-dot status-blocked" />

// 링 형태
<div className="status-ring-completed p-2 rounded-lg">...</div>
```

### 4.8 Filter Bar

```tsx
<div className="filter-bar">
  <button className="filter-chip filter-chip-active">전체</button>
  <button className="filter-chip filter-chip-inactive">진행중</button>
  <button className="filter-chip filter-chip-inactive">완료</button>
</div>
```

---

## 5. Implementation Notes

### 5.1 Tailwind 사용법

디자인 토큰은 두 가지 방식으로 접근 가능합니다:

**방법 A — Tailwind 유틸리티 클래스 (권장)**

```tsx
<div className="bg-primary text-white shadow-primary rounded-xl p-6">
  <h2 className="text-xl font-bold text-content">제목</h2>
  <p className="text-sm text-content-secondary">설명</p>
</div>
```

**방법 B — CSS 변수 (동적 값 필요 시)**

```tsx
<div style={{ backgroundColor: 'var(--color-primary)' }}>
  커스텀 배경
</div>
```

### 5.2 CSS 변수 네이밍 컨벤션

| Prefix | Category | Example |
|--------|----------|---------|
| `--color-{name}-{shade}` | 색상 팔레트 | `--color-primary-600` |
| `--surface-{variant}` | 배경 서피스 | `--surface-muted` |
| `--content-{variant}` | 텍스트 컬러 | `--content-secondary` |
| `--shadow-{name}` | 그림자 | `--shadow-card-hover` |
| `--radius-{size}` | 보더 반경 | `--radius-xl` |
| `--space-{n}` | 스페이싱 | `--space-6` |
| `--font-{type}` | 폰트 패밀리 | `--font-sans` |

### 5.3 다크 모드

Tailwind의 `class` 전략을 사용합니다 (`tailwind.config.js`에서 `darkMode: 'class'`).

```tsx
// HTML 루트에 .dark 클래스 토글
document.documentElement.classList.toggle('dark');

// 컴포넌트에서 다크모드 대응
<div className="bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100">
  ...
</div>
```

> 커스텀 컴포넌트 클래스(`.card`, `.alert-*` 등)는 `index.css`에서 다크 모드가 자동 적용됩니다.

### 5.4 Gradient 패턴

| Tailwind Class | Usage |
|---------------|-------|
| `bg-btn-primary` | Primary 버튼 (blue → indigo) |
| `bg-btn-play` | Play 버튼 (purple → indigo) |
| `bg-progress` | 프로그레스 바 (purple → indigo) |
| `bg-ai-banner` | AI 배너 (violet → purple → indigo) |
| `bg-tint-purple` | 연보라 틴트 배경 |
| `bg-tint-orange` | 연주황 틴트 배경 |
| `bg-page-gradient` | 페이지 전체 배경 그라디언트 |

### 5.5 아이콘 시스템

**lucide-react** 라이브러리를 사용합니다.

```tsx
import { CheckCircle2, AlertCircle } from 'lucide-react';

// 사이즈 규칙
<CheckCircle2 className="w-3 h-3" />  // 뱃지 내 아이콘
<CheckCircle2 className="w-4 h-4" />  // 버튼, 인라인 아이콘
<CheckCircle2 className="w-5 h-5" />  // 카드 헤더 아이콘
<CheckCircle2 className="w-8 h-8" />  // 대형 스탯 아이콘
<CheckCircle2 className="w-10 h-10" /> // 히어로 아이콘
```

### 5.6 애니메이션

| Class | Duration | Usage |
|-------|----------|-------|
| `animate-fade-in` | 0.3s | 컴포넌트 등장 |
| `animate-slide-up` | 0.4s | 리스트 아이템 등장 |
| `animate-pulse-soft` | 2s (infinite) | 로딩 인디케이터 |
| `animate-spin` | — | 스피너 (Tailwind 기본) |
| `transition-all duration-300` | 300ms | 카드 호버 |
| `transition-colors` | 150ms | 버튼 호버 |

### 5.7 파일 구조

```
frontend/
├── tailwind.config.js     ← 디자인 토큰 정의 (Tailwind extend)
├── src/
│   ├── index.css           ← 전역 스타일 (CSS 변수 + 컴포넌트 클래스)
│   ├── main.tsx            ← index.css import
│   └── pages/
│       └── MidCheck.tsx    ← 레퍼런스 구현체
└── postcss.config.js
```

---

## 6. Quick Reference Card

```
Color:     bg-primary, text-content-secondary, border-surface-border
Card:      .card, .card-hover, .card-compact, .card-dark
Button:    .btn-primary, .btn-secondary, .btn-ghost, .btn-play
Badge:     .badge .badge-success, .badge-sm .badge-info
Alert:     .alert .alert-info, .alert .alert-warning
Table:     .table-container > table > thead.table-head > tr > th.table-th
Progress:  .progress-track > .progress-fill
Status:    .status-dot .status-completed
Filter:    .filter-bar > .filter-chip .filter-chip-active
Layout:    .page-container, .page-header
Player:    .player-shell > .player-toolbar, .player-controls
```
