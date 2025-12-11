<%@ include file="../init.jsp" %><%

//로그인
if(0 == userId) {
    //m.jsAlert("로그인이 필요한 페이지입니다.");
    //m.jsReplace("/member/login.jsp");
    auth.loginForm();
    return;
}

//정보-회원
UserDao user = new UserDao();
DataSet uinfo = user.find("id = " + userId + " AND status = 1");
if(!uinfo.next()) { m.jsError(_message.get("alert.member.nodata")); return; }
uinfo.put("mobile_conv", !"".equals(uinfo.s("mobile")) ? uinfo.s("mobile") : "");

String ch = m.rs("ch", "mypage");

%>