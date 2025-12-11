<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
UserDao user = new UserDao();

//폼체크
f.addElement("s_user_kind", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//출력
p.setLayout("pop");
p.setBody("user.find_users");
p.setVar("p_title", "대상선택");
p.setVar("query", m.qs());

p.setLoop("user_kinds", m.arr2loop(user.kinds));
p.setLoop("receive_yn", m.arr2loop(user.receiveYn));
p.display(out);

%>