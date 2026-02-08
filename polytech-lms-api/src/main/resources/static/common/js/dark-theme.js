/**
 * GrowAI-LMS Light Theme Enforcer
 * 교수자 페이지와 동일한 Light 테마 적용
 * Version: 2.0.0
 * Updated: 2026-02-08 - Dark → Light 테마 전환
 */

(function() {
  'use strict';

  // 라이트 테마 강제 적용
  var LIGHT_THEME_ENABLED = true;

  // DOM Ready 시 실행
  function onDOMReady(callback) {
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', callback);
    } else {
      callback();
    }
  }

  // 라이트 테마 적용 - 다크 클래스 제거
  function applyLightTheme() {
    if (!LIGHT_THEME_ENABLED) return;

    // theme-dark 클래스 제거
    document.body.classList.remove('theme-dark');
    document.documentElement.classList.remove('theme-dark');

    // new-main-fullscreen 요소
    var mainFullscreen = document.querySelector('.new-main-fullscreen');
    if (mainFullscreen) {
      mainFullscreen.classList.remove('theme-dark');
    }

    // localStorage에 light 테마 저장
    try {
      localStorage.setItem('growai-theme', 'light');
    } catch(e) {}

    console.log('[GrowAI] Light theme applied');
  }

  // 테마 토글 함수 (사용자 설정용)
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

  // 실행
  onDOMReady(function() {
    applyLightTheme();
  });

  // 페이지 로드 전 즉시 다크 클래스 제거 (FOUC 방지)
  if (LIGHT_THEME_ENABLED) {
    document.documentElement.classList.remove('theme-dark');
    if (document.body) {
      document.body.classList.remove('theme-dark');
    }
  }

})();
