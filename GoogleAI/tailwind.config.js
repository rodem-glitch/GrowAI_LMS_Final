/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      // ================================================================
      // Colors — 디자인 가이드 JSON 기반
      // ================================================================
      colors: {
        // --- Primary (Blue → Indigo axis) ---
        primary: {
          50:  '#eff6ff',
          100: '#dbeafe',
          200: '#bfdbfe',
          300: '#93c5fd',
          400: '#60a5fa',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
          800: '#1e40af',
          900: '#1e3a8a',
          DEFAULT: '#2563eb',
        },

        // --- Secondary (Purple → Violet) ---
        secondary: {
          50:  '#faf5ff',
          100: '#f3e8ff',
          200: '#e9d5ff',
          300: '#d8b4fe',
          400: '#c084fc',
          500: '#a855f7',
          600: '#9333ea',
          700: '#7e22ce',
          800: '#6b21a8',
          900: '#581c87',
          DEFAULT: '#9333ea',
        },

        // --- Semantic: Success (Emerald) ---
        success: {
          50:  '#ecfdf5',
          100: '#d1fae5',
          200: '#a7f3d0',
          400: '#34d399',
          500: '#10b981',
          600: '#059669',
          700: '#047857',
          DEFAULT: '#10b981',
        },

        // --- Semantic: Warning (Amber) ---
        warning: {
          50:  '#fffbeb',
          100: '#fef3c7',
          500: '#f59e0b',
          600: '#d97706',
          700: '#b45309',
          DEFAULT: '#f59e0b',
        },

        // --- Semantic: Danger (Red) ---
        danger: {
          50:  '#fef2f2',
          100: '#fee2e2',
          400: '#f87171',
          500: '#ef4444',
          600: '#dc2626',
          700: '#b91c1c',
          DEFAULT: '#ef4444',
        },

        // --- Semantic: Info (Cyan) ---
        info: {
          50:  '#ecfeff',
          100: '#cffafe',
          400: '#22d3ee',
          500: '#06b6d4',
          DEFAULT: '#06b6d4',
        },

        // --- Surface (Light theme) ---
        surface: {
          DEFAULT: '#ffffff',
          muted:   '#f9fafb',   // gray-50
          subtle:  '#f3f4f6',   // gray-100
          border:  '#e5e7eb',   // gray-200
        },

        // --- Dark surface (Video player, Security demo, etc.) ---
        'surface-dark': {
          DEFAULT: '#0f172a',   // slate-900
          card:    '#1e293b',   // slate-800
          muted:   '#334155',   // slate-700
        },

        // --- Text ---
        content: {
          DEFAULT:   '#111827',   // gray-900
          secondary: '#4b5563',   // gray-600
          muted:     '#9ca3af',   // gray-400
          subtle:    '#6b7280',   // gray-500
          inverse:   '#ffffff',
        },

        // --- KOPO brand ---
        kopo: {
          blue:  '#004990',
          light: '#0066cc',
          dark:  '#003366',
        },
      },

      // ================================================================
      // Typography
      // ================================================================
      fontFamily: {
        sans: [
          'Pretendard',
          '-apple-system',
          'BlinkMacSystemFont',
          'system-ui',
          'Roboto',
          '"Helvetica Neue"',
          '"Segoe UI"',
          '"Apple SD Gothic Neo"',
          '"Malgun Gothic"',
          'sans-serif',
        ],
        mono: [
          'ui-monospace',
          'SFMono-Regular',
          '"SF Mono"',
          'Menlo',
          'Consolas',
          '"Liberation Mono"',
          'monospace',
        ],
      },
      fontSize: {
        // 커스텀 micro 사이즈 (badges, metadata)
        'micro': ['10px', { lineHeight: '14px' }],
        // 커스텀 tiny 사이즈 (table cells, AI summaries)
        'tiny':  ['11px', { lineHeight: '16px' }],
      },

      // ================================================================
      // Spacing (추가 토큰)
      // ================================================================
      spacing: {
        '4.5': '1.125rem',   // 18px — 중간 갭용
        '13':  '3.25rem',    // 52px
        '15':  '3.75rem',    // 60px
        '18':  '4.5rem',     // 72px
      },

      // ================================================================
      // Border Radius
      // ================================================================
      borderRadius: {
        '4xl': '2rem',       // 32px — extra-large panels
      },

      // ================================================================
      // Box Shadow
      // ================================================================
      boxShadow: {
        // Colored shadows (디자인 가이드 colored variants)
        'primary':   '0 10px 15px -3px rgba(59, 130, 246, 0.25)',
        'secondary': '0 10px 15px -3px rgba(168, 85, 247, 0.3)',
        'success':   '0 10px 15px -3px rgba(16, 185, 129, 0.25)',
        // Elevated card
        'card':      '0 2px 8px rgba(16, 24, 40, 0.06)',
        'card-hover':'0 8px 24px rgba(16, 24, 40, 0.1)',
        // Focus ring
        'ring-primary': '0 0 0 2px rgba(59, 130, 246, 0.2)',
      },

      // ================================================================
      // Background Image (Gradients)
      // ================================================================
      backgroundImage: {
        // Page backgrounds
        'page-gradient':      'linear-gradient(to bottom right, #f8fafc, #eff6ff, #eef2ff)',
        // Button gradients
        'btn-primary':        'linear-gradient(to right, #2563eb, #4f46e5)',
        'btn-primary-hover':  'linear-gradient(to right, #1d4ed8, #4338ca)',
        'btn-play':           'linear-gradient(to bottom right, #a855f7, #4f46e5)',
        'btn-play-hover':     'linear-gradient(to bottom right, #9333ea, #4338ca)',
        // Progress bar
        'progress':           'linear-gradient(to right, #a855f7, #6366f1)',
        // Banner
        'ai-banner':          'linear-gradient(to right, #7c3aed, #9333ea, #4f46e5)',
        // Surface tints
        'tint-purple':        'linear-gradient(to right, #faf5ff, #eef2ff)',
        'tint-orange':        'linear-gradient(to right, #fff7ed, #fffbeb)',
        'tint-emerald':       'linear-gradient(to right, #10b981, #34d399)',
        'tint-cyan-purple':   'linear-gradient(to right, rgba(6,182,212,0.1), rgba(168,85,247,0.1))',
      },

      // ================================================================
      // Animation / Keyframes
      // ================================================================
      keyframes: {
        'fade-in': {
          '0%':   { opacity: '0', transform: 'translateY(8px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        'slide-up': {
          '0%':   { opacity: '0', transform: 'translateY(16px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        'pulse-soft': {
          '0%, 100%': { opacity: '1' },
          '50%':      { opacity: '0.7' },
        },
      },
      animation: {
        'fade-in':    'fade-in 0.3s ease-out',
        'slide-up':   'slide-up 0.4s ease-out',
        'pulse-soft': 'pulse-soft 2s ease-in-out infinite',
      },

      // ================================================================
      // Transition Duration
      // ================================================================
      transitionDuration: {
        '250': '250ms',
        '400': '400ms',
      },

      // ================================================================
      // Z-Index
      // ================================================================
      zIndex: {
        '60': '60',
        '70': '70',
      },

      // ================================================================
      // Min Height (Video player)
      // ================================================================
      minHeight: {
        'player': '380px',
      },

      // ================================================================
      // Max Height (Simulation output)
      // ================================================================
      maxHeight: {
        'sim-output': '120px',
      },

      // ================================================================
      // Width (Sidebar)
      // ================================================================
      width: {
        'sidebar': '224px',   // w-56
      },
    },
  },
  plugins: [],
}
