<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(7, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
PopupDao popup = new PopupDao();

if(!"".equals(m.rs("idx"))) { //복수삭제
	String[] idx = m.rs("idx").split("\\,");
	int failed = 0;
	for(int i=0; i<idx.length; i++) {
		//if(!popup.delete(m.urldecode(Base64Coder.decode(idx[i])))) failed++;
		if(-1 == popup.execute("UPDATE " + popup.table + " SET status = -1 WHERE " + m.urldecode(Base64Coder.decode(idx[i])))) failed++;
	}
	if(failed > 0) {
		m.jsError("삭제하는 중 오류가 발생했습니다.(실패/전체 : " + failed + "/" + idx.length + ")");
		return;
	}
} else if(!"".equals(m.rs("id"))) { //개별삭제
	DataSet info = popup.find("id = '" + m.rs("id") + "'");
	if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
	/*
	if(!popup.delete("id = '" + m.rs("id") + "'")) {
		m.jsError("삭제하는 중 오류가 발생했습니다."); return;
	}
	*/
	popup.item("status", -1);
	if(!popup.update("id = '" + m.rs("id") + "'")) {
		m.jsError("삭제하는 중 오류가 발생했습니다.");
		return;
	}
} else {
	m.jsError("기본키는 반드시 지정해야 합니다.");
	return;
}

m.jsReplace("popup_list.jsp?" + m.qs("id, idx"));

%>