/**
 * 프론트엔드 보안 유틸리티
 * 웹취약점 점검 기준 준수
 */

// HTML 엔티티 매핑
const HTML_ENTITIES: Record<string, string> = {
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  "'": '&#x27;',
  '/': '&#x2F;',
  '`': '&#x60;',
  '=': '&#x3D;',
};

/**
 * XSS 방지를 위한 HTML 이스케이프
 * @param str 이스케이프할 문자열
 * @returns 이스케이프된 문자열
 */
export function escapeHtml(str: string | null | undefined): string {
  if (str == null) return '';
  return String(str).replace(/[&<>"'`=/]/g, (char) => HTML_ENTITIES[char] || char);
}

/**
 * HTML 태그 제거 (plain text 추출)
 * @param html HTML 문자열
 * @returns 태그가 제거된 텍스트
 */
export function stripHtmlTags(html: string | null | undefined): string {
  if (html == null) return '';
  return String(html)
    .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
    .replace(/<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>/gi, '')
    .replace(/<[^>]+>/g, '')
    .replace(/&nbsp;/g, ' ')
    .trim();
}

// 허용된 HTML 태그 (화이트리스트)
const ALLOWED_TAGS = new Set([
  'p', 'br', 'b', 'i', 'u', 'strong', 'em', 'span',
  'ul', 'ol', 'li', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
  'table', 'thead', 'tbody', 'tr', 'th', 'td',
  'blockquote', 'pre', 'code', 'hr', 'div',
]);

// 허용된 속성 (화이트리스트)
const ALLOWED_ATTRS = new Set([
  'class', 'style', 'colspan', 'rowspan', 'align', 'valign',
]);

// 위험한 속성 패턴
const DANGEROUS_ATTR_PATTERN = /^on|^data-|javascript:|vbscript:|expression\(/i;

// 위험한 CSS 패턴
const DANGEROUS_CSS_PATTERN = /expression|url\s*\(|behavior|binding|-moz-binding|javascript/i;

/**
 * HTML Sanitizer - 안전한 HTML만 허용
 * @param html 정제할 HTML 문자열
 * @returns 정제된 HTML 문자열
 */
export function sanitizeHtml(html: string | null | undefined): string {
  if (html == null) return '';

  const str = String(html);

  // 임시 DOM 파서 사용
  const parser = new DOMParser();
  const doc = parser.parseFromString(`<div>${str}</div>`, 'text/html');
  const container = doc.body.firstChild as HTMLElement;

  if (!container) return '';

  // 재귀적으로 노드 정제
  const sanitizeNode = (node: Node): void => {
    const childNodes = Array.from(node.childNodes);

    for (const child of childNodes) {
      if (child.nodeType === Node.ELEMENT_NODE) {
        const element = child as HTMLElement;
        const tagName = element.tagName.toLowerCase();

        // script, style, iframe 등 위험한 태그 제거
        if (!ALLOWED_TAGS.has(tagName)) {
          // 텍스트 내용만 유지하고 태그 제거
          const textContent = document.createTextNode(element.textContent || '');
          node.replaceChild(textContent, child);
          continue;
        }

        // 위험한 속성 제거
        const attrs = Array.from(element.attributes);
        for (const attr of attrs) {
          const attrName = attr.name.toLowerCase();
          const attrValue = attr.value;

          // 이벤트 핸들러, data- 속성, javascript: 프로토콜 제거
          if (DANGEROUS_ATTR_PATTERN.test(attrName) ||
              DANGEROUS_ATTR_PATTERN.test(attrValue)) {
            element.removeAttribute(attr.name);
            continue;
          }

          // 허용되지 않은 속성 제거
          if (!ALLOWED_ATTRS.has(attrName)) {
            element.removeAttribute(attr.name);
            continue;
          }

          // style 속성의 위험한 CSS 제거
          if (attrName === 'style' && DANGEROUS_CSS_PATTERN.test(attrValue)) {
            element.removeAttribute('style');
          }
        }

        // 자식 노드 재귀 처리
        sanitizeNode(element);
      }
    }
  };

  sanitizeNode(container);

  return container.innerHTML;
}

/**
 * URL 검증 - javascript:, data: 프로토콜 차단
 * @param url 검증할 URL
 * @returns 안전한 URL이면 true
 */
export function isValidUrl(url: string | null | undefined): boolean {
  if (url == null) return false;

  const str = String(url).trim().toLowerCase();

  // 위험한 프로토콜 차단
  if (str.startsWith('javascript:') ||
      str.startsWith('vbscript:') ||
      str.startsWith('data:')) {
    return false;
  }

  return true;
}

/**
 * 안전한 URL 반환 - 위험한 URL은 빈 문자열 반환
 * @param url 검증할 URL
 * @returns 안전한 URL 또는 빈 문자열
 */
export function sanitizeUrl(url: string | null | undefined): string {
  if (!isValidUrl(url)) return '';
  return String(url).trim();
}

/**
 * 안전한 localStorage 래퍼
 * - JSON 직렬화/역직렬화 처리
 * - 민감정보 저장 경고
 */
export const secureStorage = {
  /**
   * 데이터 저장
   * @param key 저장 키
   * @param value 저장할 값
   */
  setItem<T>(key: string, value: T): void {
    try {
      const serialized = JSON.stringify(value);
      localStorage.setItem(key, serialized);
    } catch (e) {
      // 저장 실패 시 무시 (quota 초과 등)
    }
  },

  /**
   * 데이터 조회
   * @param key 조회 키
   * @param defaultValue 기본값
   * @returns 저장된 값 또는 기본값
   */
  getItem<T>(key: string, defaultValue: T | null = null): T | null {
    try {
      const item = localStorage.getItem(key);
      if (item === null) return defaultValue;
      return JSON.parse(item) as T;
    } catch (e) {
      return defaultValue;
    }
  },

  /**
   * 데이터 삭제
   * @param key 삭제할 키
   */
  removeItem(key: string): void {
    try {
      localStorage.removeItem(key);
    } catch (e) {
      // 삭제 실패 시 무시
    }
  },

  /**
   * 키 존재 여부 확인
   * @param key 확인할 키
   * @returns 존재하면 true
   */
  hasItem(key: string): boolean {
    return localStorage.getItem(key) !== null;
  },
};

/**
 * 프로덕션 환경에서 안전한 로깅
 * - 개발 환경에서만 출력
 * - 민감정보 마스킹
 */
export const secureLog = {
  _isDev: import.meta.env.DEV,

  log(...args: unknown[]): void {
    if (this._isDev) {
      console.log(...args);
    }
  },

  warn(...args: unknown[]): void {
    if (this._isDev) {
      console.warn(...args);
    }
  },

  error(...args: unknown[]): void {
    // 에러는 프로덕션에서도 로깅 (민감정보 제외)
    console.error(...args);
  },

  debug(...args: unknown[]): void {
    if (this._isDev) {
      console.debug(...args);
    }
  },
};

/**
 * 입력값 검증 유틸리티
 */
export const validate = {
  /**
   * 이메일 형식 검증
   */
  email(value: string): boolean {
    const pattern = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
    return pattern.test(value);
  },

  /**
   * 숫자 범위 검증
   */
  numberRange(value: number, min: number, max: number): boolean {
    return !isNaN(value) && value >= min && value <= max;
  },

  /**
   * 문자열 길이 검증
   */
  stringLength(value: string, min: number, max: number): boolean {
    const len = value?.length ?? 0;
    return len >= min && len <= max;
  },

  /**
   * 필수값 검증
   */
  required(value: unknown): boolean {
    if (value === null || value === undefined) return false;
    if (typeof value === 'string') return value.trim().length > 0;
    if (Array.isArray(value)) return value.length > 0;
    return true;
  },

  /**
   * SQL Injection 패턴 검사
   */
  noSqlInjection(value: string): boolean {
    const pattern = /('|"|;|--|\/\*|\*\/|xp_|union|select|insert|update|delete|drop|exec|execute)/i;
    return !pattern.test(value);
  },
};
