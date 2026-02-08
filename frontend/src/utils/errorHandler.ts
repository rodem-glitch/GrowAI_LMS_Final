// utils/errorHandler.ts — 공통 오류코드 매핑 및 에러 처리 유틸리티
import errorCodes from '@/constants/errorCodes.json';

type ErrorCodeKey = keyof typeof errorCodes;

interface ApiError {
  errorCode?: string;
  message?: string;
}

/**
 * 에러코드로 사용자 친화적 메시지 반환
 */
export function getErrorMessage(errorCode?: string): string {
  if (!errorCode) return '요청을 처리하는 중 오류가 발생했습니다.';
  const entry = errorCodes[errorCode as ErrorCodeKey];
  return entry?.message || '알 수 없는 오류가 발생했습니다.';
}

/**
 * API 에러 응답에서 사용자 메시지 추출
 * 우선순위: errorCode 매핑 > 서버 message > 기본 메시지
 */
export function extractErrorMessage(err: any): string {
  const data: ApiError = err?.response?.data;
  if (data?.errorCode) {
    return getErrorMessage(data.errorCode);
  }
  if (data?.message) {
    return data.message;
  }

  // HTTP 상태 코드별 기본 메시지
  const status = err?.response?.status;
  switch (status) {
    case 400: return '잘못된 요청입니다.';
    case 401: return '인증이 필요합니다. 다시 로그인해주세요.';
    case 403: return '접근 권한이 없습니다.';
    case 404: return '요청한 리소스를 찾을 수 없습니다.';
    case 409: return '요청이 충돌했습니다.';
    case 429: return '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.';
    case 500: return '서버 내부 오류가 발생했습니다.';
    case 502: return '서버 연결에 실패했습니다.';
    case 503: return '서비스가 일시적으로 이용 불가합니다.';
    case 504: return '요청 처리 시간이 초과되었습니다.';
    default:  return '요청을 처리하는 중 오류가 발생했습니다.';
  }
}
