<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
UserDao user = new UserDao();

//정보
DataSet uinfo = user.find("id = ? AND user_kind IN ('C', 'D', 'A', 'S') AND status = 1", new Object[] {userId});
if(uinfo.next()) {
	p.setBody("member.sysop_slogin");
	p.setVar("uid", userId);
	p.setVar("ek", m.md5("SEK" + userId + m.time("yyyyMMdd")));
	p.display();
}

%>