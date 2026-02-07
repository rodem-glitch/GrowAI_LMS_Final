/**
 * GrowAI-LMS Dark Theme Activator
 * Legacy 페이지에 다크 테마 자동 적용
 * Version: 1.1.0
 * Created: 2026-02-07
 * Updated: 2026-02-07 - 인라인 스타일 오버라이드 추가
 */

(function() {
  'use strict';

  // 다크 테마 활성화 설정
  var DARK_THEME_ENABLED = true;

  // 다크 테마 색상
  var DARK_COLORS = {
    bgPrimary: '#0a0a12',
    bgSecondary: '#1a1a2e',
    bgTertiary: '#252542',
    bgCard: '#2a2753',
    textPrimary: '#f8f9fc',
    textSecondary: '#9194b3',
    accent: '#e7005e',
    border: 'rgba(255, 255, 255, 0.08)'
  };

  // DOM Ready 시 실행
  function onDOMReady(callback) {
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', callback);
    } else {
      callback();
    }
  }

  // 인라인 스타일 오버라이드
  function overrideInlineStyles() {
    // 배경색 변경 대상
    var bgElements = document.querySelectorAll('[style*="background"]');
    bgElements.forEach(function(el) {
      var style = el.getAttribute('style') || '';
      // 라이트 배경색을 다크로 변경
      style = style.replace(/background:\s*#f9fafb/gi, 'background: ' + DARK_COLORS.bgPrimary);
      style = style.replace(/background:\s*#fff(fff)?/gi, 'background: ' + DARK_COLORS.bgSecondary);
      style = style.replace(/background:\s*#ffffff/gi, 'background: ' + DARK_COLORS.bgSecondary);
      style = style.replace(/background:\s*#f3f4f6/gi, 'background: ' + DARK_COLORS.bgTertiary);
      style = style.replace(/background:\s*#e5e7eb/gi, 'background: ' + DARK_COLORS.bgCard);
      style = style.replace(/background-color:\s*#f9fafb/gi, 'background-color: ' + DARK_COLORS.bgPrimary);
      style = style.replace(/background-color:\s*#fff(fff)?/gi, 'background-color: ' + DARK_COLORS.bgSecondary);
      style = style.replace(/background-color:\s*#ffffff/gi, 'background-color: ' + DARK_COLORS.bgSecondary);
      style = style.replace(/background-color:\s*#f3f4f6/gi, 'background-color: ' + DARK_COLORS.bgTertiary);
      el.setAttribute('style', style);
    });

    // 텍스트 색상 변경
    var textElements = document.querySelectorAll('[style*="color"]');
    textElements.forEach(function(el) {
      var style = el.getAttribute('style') || '';
      // 다크 텍스트를 라이트로 변경 (배경색 변경은 제외)
      if (style.indexOf('background') === -1) {
        style = style.replace(/color:\s*#1e1e1e/gi, 'color: ' + DARK_COLORS.textPrimary);
        style = style.replace(/color:\s*#101828/gi, 'color: ' + DARK_COLORS.textPrimary);
        style = style.replace(/color:\s*#333/gi, 'color: ' + DARK_COLORS.textPrimary);
        style = style.replace(/color:\s*#666/gi, 'color: ' + DARK_COLORS.textSecondary);
        style = style.replace(/color:\s*#777/gi, 'color: ' + DARK_COLORS.textSecondary);
        el.setAttribute('style', style);
      }
    });

    // 테두리 색상 변경
    var borderElements = document.querySelectorAll('[style*="border"]');
    borderElements.forEach(function(el) {
      var style = el.getAttribute('style') || '';
      style = style.replace(/border[^:]*:\s*[^;]*#e5e7eb/gi, function(match) {
        return match.replace(/#e5e7eb/gi, DARK_COLORS.border);
      });
      style = style.replace(/border[^:]*:\s*[^;]*#d1d5db/gi, function(match) {
        return match.replace(/#d1d5db/gi, DARK_COLORS.border);
      });
      el.setAttribute('style', style);
    });

    // new-main-fullscreen 직접 스타일 적용
    var mainFullscreen = document.querySelector('.new-main-fullscreen');
    if (mainFullscreen) {
      mainFullscreen.style.background = DARK_COLORS.bgPrimary;
      mainFullscreen.style.color = DARK_COLORS.textPrimary;
    }

    // nm-header 스타일 적용
    var nmHeader = document.querySelector('.nm-header');
    if (nmHeader) {
      nmHeader.style.background = 'linear-gradient(135deg, ' + DARK_COLORS.bgPrimary + ' 0%, ' + DARK_COLORS.bgSecondary + ' 100%)';
      nmHeader.style.borderBottom = '1px solid ' + DARK_COLORS.border;
    }

    // nm-card 스타일 적용
    var nmCards = document.querySelectorAll('.nm-card, .course-card, .video-card');
    nmCards.forEach(function(card) {
      card.style.background = DARK_COLORS.bgCard;
      card.style.border = '1px solid ' + DARK_COLORS.border;
      card.style.borderRadius = '1.5rem';
    });

    console.log('[GrowAI] Inline styles overridden');
  }

  // 다크 테마 적용
  function applyDarkTheme() {
    if (!DARK_THEME_ENABLED) return;

    // body에 theme-dark 클래스 추가
    document.body.classList.add('theme-dark');

    // html 요소에도 추가 (일부 스타일용)
    document.documentElement.classList.add('theme-dark');

    // new-main-fullscreen 요소가 있으면 클래스 추가
    var mainFullscreen = document.querySelector('.new-main-fullscreen');
    if (mainFullscreen) {
      mainFullscreen.classList.add('theme-dark');
    }

    // 인라인 스타일 오버라이드
    overrideInlineStyles();

    console.log('[GrowAI] Dark theme applied');
  }

  // 테마 토글 함수 (나중에 사용자 설정용)
  window.toggleDarkTheme = function(enable) {
    if (enable === undefined) {
      enable = !document.body.classList.contains('theme-dark');
    }

    if (enable) {
      document.body.classList.add('theme-dark');
      document.documentElement.classList.add('theme-dark');
      localStorage.setItem('growai-theme', 'dark');
    } else {
      document.body.classList.remove('theme-dark');
      document.documentElement.classList.remove('theme-dark');
      localStorage.setItem('growai-theme', 'light');
    }

    return enable;
  };

  // 저장된 테마 확인 및 적용
  function checkSavedTheme() {
    var savedTheme = localStorage.getItem('growai-theme');

    // 저장된 테마가 없으면 기본값(dark) 적용
    if (!savedTheme) {
      applyDarkTheme();
      return;
    }

    // 저장된 테마에 따라 적용
    if (savedTheme === 'dark') {
      applyDarkTheme();
    }
  }

  // 실행
  onDOMReady(function() {
    // 즉시 다크 테마 적용 (깜빡임 방지)
    applyDarkTheme();
  });

  // 페이지 로드 전에 body에 클래스 추가 시도 (FOUC 방지)
  if (DARK_THEME_ENABLED) {
    // body가 있으면 바로 적용
    if (document.body) {
      document.body.classList.add('theme-dark');
    }
    // html에 먼저 적용
    document.documentElement.classList.add('theme-dark');
  }

})();
