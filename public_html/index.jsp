<%@ page contentType="text/html; charset=utf-8" %><%@ page import="dao.*,malgnsoft.db.*,malgnsoft.util.*" %><%

String agent = request.getHeader("user-agent");
boolean isMobile = false;
if(null != agent) {
	String[] mobileKeyWords = {
		"iPhone", "iPod", "iPad"
		, "BlackBerry", "Android", "Windows CE"
		, "LG", "MOT", "SAMSUNG", "SonyEricsson"
	};
	for(int i=0; i<mobileKeyWords.length; i++) {
		if(agent.indexOf(mobileKeyWords[i]) != -1) {
			isMobile = true;
			break;
		}
	}
}

Malgn m = new Malgn(request, response, out);

//처리-공사중
SiteDao Site = new SiteDao(); //Site.clear();
DataSet siteinfo = Site.getSiteInfo(request.getServerName());
SiteConfigDao SiteConfig = new SiteConfigDao(siteinfo.i("id"));
if(1 != siteinfo.i("status") || "".equals(siteinfo.s("doc_root"))) {
	m.jsReplace("about:blank", "top"); 
	return;
}

//처리-스킨5이상모바일해제
if(5 <= siteinfo.i("skin_cd")) isMobile = false;

//처리-B2B도메인
UserDeptDao userDept = new UserDeptDao();
String B2Bcode = m.rs("b2b");
if(!"".equals(B2Bcode)) {
	DataSet b2binfo = userDept.getB2BInfo(B2Bcode, siteinfo.i("id"));
	if(b2binfo.next()) {
		if(!isMobile) response.sendRedirect("/member/login.jsp?udid=" + b2binfo.i("id"));
		else response.sendRedirect("/mobile/login.jsp?udid=" + b2binfo.i("id"));
		return;
	}
}

if("Y".equals(SiteConfig.s("prepare_yn"))) {
%>
<!doctype html>
<html lang="ko">
<head>
	<meta charset="utf-8">
	<title>준비중입니다.</title>
	<style>
	* { margin:0; padding:0; }
	html, body { width:100%; height:100%; overflow:hidden; }
	#container { width:100%; height:100%; text-align:center; background:url('/common/images/under_construction.jpg') 50% 50% no-repeat; text-indent:-9999px; }
	
	@media screen and (max-width:998px) {
		#container { background-size:contain; }
	}
	@media screen and (max-height:469px) {
		#container { background-size:contain; }
	}
	</style>
</head>
<body>
<div id="container">
	<h1>홈페이지 <strong>오픈 준비중</strong>입니다.</h1>
	<h2>홈페이지를 찾아주시는 모든 분들께 더 나은 서비스를 제공하기 위해 <strong>홈페이지가 새 단장 중에 있습니다.</strong> 좋은 모습으로 곧 찾아뵙겠습니다. 감사합니다.</h2>
</div>
</body>
</html>
<%
	return;
}

//이동
String qs = m.qs("");
if(!"".equals(qs)) qs = "?" + qs;

if(!isMobile) {
	response.setStatus(HttpServletResponse.SC_MOVED_PERMANENTLY);
	response.setHeader("Location", request.getContextPath() + "/mypage/new_main/index.jsp" + qs);
	//response.sendRedirect("main/index.jsp" + qs);
} else {
	response.setStatus(HttpServletResponse.SC_MOVED_PERMANENTLY);
	response.setHeader("Location", request.getContextPath() + "/mobile/index.jsp" + qs);
	//response.sendRedirect("mobile/index.jsp" + qs);

}

%>
