<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(111, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int did = m.ri("did");
String dno = m.rs("dno");
if(did == 0 || "".equals(dno)) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
DeliveryDao delivery = new DeliveryDao();

//정보
DataSet info = delivery.find("id = " + did + " AND status = 1");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//이동
m.jsReplace(info.s("link") + dno);

%>