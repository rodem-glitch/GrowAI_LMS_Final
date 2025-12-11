<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//접근권한
if(!(Menu.accessible(6, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
BoardDao board = new BoardDao();

//정보
DataSet info = board.find("id = " + id + "");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//삭제
board.item("status", -1);
if(!board.update("id = " + id)) { m.jsError("삭제하는 중 오류가 발생하였습니다."); return; }

//이동
m.jsReplace("board_list.jsp?" + m.qs("id"));
return;

%>