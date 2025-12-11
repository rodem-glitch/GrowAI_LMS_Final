<%@ include file="../init.jsp" %><%

//로그인
if(0 == userId) { auth.loginForm(); return; }

//정보-회원
UserDao user = new UserDao();

DataSet uinfo = user.find("id = " + userId + " AND status = 1");
if(!uinfo.next()) { m.jsError(_message.get("alert.member.nodata")); return; }
uinfo.put("mobile_conv", !"".equals(uinfo.s("mobile")) ? uinfo.s("mobile") : "");
//uinfo.put("mobile", !"".equals(uinfo.s("mobile")) ? SimpleAES.decrypt(uinfo.s("mobile")) : "");
String ch = !userB2BBlock ? m.rs("ch", "mypage") : "b2b";

%>