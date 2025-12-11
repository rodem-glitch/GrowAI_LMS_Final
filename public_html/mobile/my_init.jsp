<%@ include file="/init.jsp" %><%

if(isRespWeb) { m.redirect("/main/index.jsp"); return; }

//로그인
if(0 == userId) { auth.loginForm("/mobile/login.jsp"); return; }
//if(0 == userId) { auth.loginForm(request.getScheme() + "://" + siteinfo.s("domain") + "/mobile/login.jsp"); return; }

//정보-회원
UserDao user = new UserDao();
DataSet uinfo = user.find("id = " + userId + " AND status = 1");
if(!uinfo.next()) { m.jsError(_message.get("alert.member.nodata")); return; }
uinfo.put("mobile", !"".equals(uinfo.s("mobile")) ? SimpleAES.decrypt(uinfo.s("mobile")) : "");

String ch = "mobile";

%>