<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(11, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
BannerDao banner = new BannerDao();

if(!"".equals(m.rs("idx"))) { //복수삭제
	String[] idx = m.rs("idx").split("\\,");
	int failed = 0;
	for(int i=0; i<idx.length; i++) {
		//if(!banner.delete(m.urldecode(Base64Coder.decode(idx[i])))) failed++;
		if(-1 == banner.execute("UPDATE " + banner.table + " SET status = -1 WHERE " + m.urldecode(Base64Coder.decode(idx[i])))) failed++;
	}
	if(failed > 0) {
		m.jsError("삭제하는 중 오류가 발생했습니다.(실패/전체 : " + failed + "/" + idx.length + ")");
		return;
	}
} else if(!"".equals(m.rs("id"))) { //개별삭제
	DataSet info = banner.find("id = '" + m.rs("id") + "'");
	if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
	/*
	if(!banner.delete("id = '" + m.rs("id") + "'")) {
		m.jsError("삭제하는 중 오류가 발생했습니다."); return;
	}
	*/
	banner.item("status", -1);
	if(!banner.update("id = '" + m.rs("id") + "'")) {
		m.jsError("삭제하는 중 오류가 발생했습니다.");
		return;
	}
} else {
	m.jsError("기본키는 반드시 지정해야 합니다.");
	return;
}

m.jsReplace("banner_list.jsp?" + m.qs("id, idx"));

%>