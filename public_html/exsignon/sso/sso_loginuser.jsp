<%@ page language="java"
    contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"
    session="false"
%><%@ include file="../include/sso_entry.jsp"
%><%@ page import="dao.*,malgnsoft.util.*,malgnsoft.db.*" %><%

//기본객체
Malgn m = new Malgn(request, response, out);
//사이트 정보
SiteDao Site = new SiteDao();
DataSet siteinfo = Site.getSiteInfo(request.getServerName());
if(1 != siteinfo.i("status") || "".equals(siteinfo.s("doc_root"))) {
    return;
}

//변수
String ssoKey = siteinfo.s("sso_key");

//SSO 세션 정보 확인
//HttpSession session = request.getSession();
//String eXSignOnUserId = (String) session.getAttribute("eXSignOn.session.userid");
//테스트 데이터 : eXSignOnUserId = "{\"dept_cd\":\"0100188\",\"user_id\":\"kangucl\",\"pers_no\":\"20191579\"}";
m.log("pslogin", "폴리텍 대학 로그인 세션 데이터 : " + eXSignOnUserId);
//System.out.println(eXSignOnUserId);
/*
SSO 로그인이 되어 사용자 인증정보가 존재할 때에 이 화면으로 넘어온다.
session.getAttribute("eXSignOn.session.userid") 에는 인증서버의 설정에 따라
사용자의 인증정보가 단일 String 혹은 JSONString 형태로 들어오게 되는데, 넘어온 정보를 핸들링하여 연계시스템에 로그인시키면 된다.
*/

//제한
if(eXSignOnUserId == null || "anonymous".equals(eXSignOnUserId)) {
    m.jsErrClose("세션 정보가 없습니다.");
    m.log("pslogin", "세션 정보가 없습니다.");
//    System.out.println("세션 정보가 없습니다.");
    return;
}

//세션 데이터를 로그인 데이터 셋으로 생성
DataSet info = new DataSet();
info.unserialize("[" + eXSignOnUserId + "]");
info.first();
//제한-데이터가 없음
if(!info.next()) {
    m.jsErrClose("로그인 정보가 없습니다.");
    m.log("pslogin", "로그인 정보가 없습니다.");
    return;
}
String ek = m.encrypt(info.s("user_id") + ssoKey + Malgn.time("yyyyMMdd"), "SHA-256");
info.put("user_id", SimpleAES.encrypt(info.s("user_id"), ssoKey));
info.put("dept_cd", SimpleAES.encrypt(info.s("dept_cd"), ssoKey));
info.put("pers_no", SimpleAES.encrypt(info.s("pers_no"), ssoKey));

//회원 정보 파싱 후 암호화해서 sso 로그인 페이지로 전달
%><body onload="document.form1.submit()">
<form name="form1" method="POST" action="/member/slogin.jsp">
    <input type="hidden" name="encrypted" value="Y">
    <input type="hidden" name="ek" value="<%= ek %>">
    <input type="hidden" name="login_id" value="<%= info.s("user_id") %>">
    <%-- 왜: 폴리텍 SSO 세션에는 사용자ID(user_id)와 학번/사번(pers_no)이 같이 들어옵니다.
         그런데 기존에 관리자에서 '학번'으로 회원을 만들어둔 경우, login_id가 pers_no라서 SSO(user_id)로는 매칭이 안 되어
         "회원 정보가 없습니다/등록된 회원이 아닙니다"가 뜰 수 있습니다.
         아래처럼 pers_no도 같이 전달해두면, slogn.jsp에서 보조키로 찾아서 로그인/동기화가 가능해집니다. --%>
    <input type="hidden" name="pers_no" value="<%= info.s("pers_no") %>">
    <%--<input type="hidden" name="dept_cd" value="<%= info.s("dept_cd") %>">--%>
</form>
</body>
