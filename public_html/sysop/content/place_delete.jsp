<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!(Menu.accessible(27, userId, userKind))) { m.jsError("접근 권한이 없습니다."); return; }

//객체
PlaceDao place = new PlaceDao();

if(!"".equals(m.request("idx"))) { //복수삭제
	String[] idx = m.request("idx").split("\\,");
	int failed = 0;
	for(int i=0; i<idx.length; i++) {
		if(!place.delete(m.urldecode(malgnsoft.util.Base64.decode(idx[i])))) failed++;
		//if(-1 == place.execute("UPDATE LM_PLACE SET status = -1 WHERE " + m.urldecode(Base64.decode(idx[i])))) failed++;
	}
	if(failed > 0) {
		m.jsError("삭제하는 중 오류가 발생했습니다.(실패/전체 : " + failed + "/" + idx.length + ")");
		return;
	}
} else if(!"".equals(m.request("id"))) { //개별삭제
	DataSet info = place.find("id = '" + m.request("id") + "'");
	if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
	if(!place.delete("id = '" + m.request("id") + "'")) {
		m.jsError("삭제하는 중 오류가 발생했습니다."); return; 
	}
	/*
	place.item("status", -1);
	if(!place.update("id = '" + m.request("id") + "'")) {
		m.jsError("삭제하는 중 오류가 발생했습니다.");
		return;
	}
	*/
} else {
	m.jsError("기본키는 반드시 지정해야 합니다.");
	return;
}

m.jsReplace("place_list.jsp?" + m.qs("id"));

%>