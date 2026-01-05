<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

// -------------------------------------------------------------------
// 목적: /mypage/new_main 전용 신규 메인 페이지(Full-screen) 골격입니다.
// 왜: 기존 mypage 레이아웃(상단바/좌측메뉴 등)을 완전히 제거하고,
//     나중에 섹션별 콘텐츠를 채워 넣기 쉽게 "빈 컨테이너(Placeholder)"만 제공합니다.
// -------------------------------------------------------------------

// 레이아웃 제거: header(html/head)만 유지하고 전역 네비게이션은 포함하지 않습니다.
// (layout_blank.html은 header.html + BODY만 포함합니다.)
p.setLayout("blank");
p.setBody("mypage.new_main_full");

// 화면에서 사용할 기본 변수들
p.setVar("p_title", "마이페이지 신규 메인");
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.display();

%>

