<%@ page contentType="application/json; charset=utf-8" %><%@ include file="/init.jsp" %><%

//왜 필요한가:
//- `project`(React) 화면은 같은 도메인에서 세션 로그인 상태로 API를 호출합니다.
//- 그래서 API는 "로그인 + 교수자 여부"를 먼저 검사해서, 다른 사람이 데이터에 접근/수정하지 못하게 막아야 합니다.

// 왜: 교수자 페이지는 SPA 호출이 많아 브라우저/프록시 캐시로 이전 응답이 남을 수 있어 최신 수정사항을 보장합니다.
response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0");
response.setHeader("Pragma", "no-cache");
response.setHeader("Expires", "0");

Json result = new Json(out);
result.put("rst_code", "9999");
result.put("rst_message", "올바른 접근이 아닙니다.");

//로그인 확인
if(0 == userId) {
	result.put("rst_code", "4010");
	result.put("rst_message", "로그인이 필요합니다.");
	result.print();
	return;
}

//관리자 권한 여부(왜: 운영자/최고관리자는 교수자 여부와 상관없이 접근이 필요합니다)
boolean isAdmin = "S".equals(userKind) || "A".equals(userKind);

//교수자 권한 확인(TB_USER.tutor_yn) - 관리자가 아니면 교수자만 허용
//왜: 각 API(JSP)에서 흔히 `UserDao user` 변수를 따로 선언해서 쓰기 때문에, include(init.jsp)에서는 이름 충돌이 나지 않도록 별도 이름을 사용합니다.
UserDao authUser = new UserDao();
DataSet uinfo = authUser.find("id = " + userId + " AND site_id = " + siteId + " AND status = 1");
if(!uinfo.next()) {
	result.put("rst_code", "4041");
	result.put("rst_message", "사용자 정보가 없습니다.");
	result.print();
	return;
}
if(!isAdmin && !"Y".equals(uinfo.s("tutor_yn"))) {
	result.put("rst_code", "4030");
	result.put("rst_message", "교수자 권한이 없습니다.");
	result.print();
	return;
}

%>
