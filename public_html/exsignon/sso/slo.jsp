<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"
    session="false"

%><%

/*
인증서버에 통합로그아웃 요청이 들어오면, 로그인 되어 있는 모든 연계시스템에서 일괄적으로 로그아웃 처리를 시켜야 한다.
때문에 타 연계시스템에서 통합로그아웃을 요청했을 때에 현재의 연계시스템을 로그아웃 시키기 위해 이 파일을 호출한다.
만일 로그아웃 전처리가 필요할 경우 세션 만료 이전에 작업이 가능하다.
*/

// TO DO...(로그아웃 전처리)

// 세션 만료
HttpSession session = request.getSession();
session.invalidate();

%>