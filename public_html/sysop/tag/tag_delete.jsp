<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
try {
	if(!Menu.accessible(712, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }
} catch (Exception e) {
	Malgn.errorLog("{tag.tag_delete} Menu accessible error", e);
}

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정하여야 합니다."); return; }

//객체
TagDao tag = new TagDao(siteId);

//정보
DataSet info = tag.find("id = " + id + "");
if(!info.next()) {
	m.jsError("삭제할 태그 정보를 확인할 수 없습니다.");
	return;
}

//삭제-태그
tag.item("status", -1);
if(!tag.update("id = " + info.i("id") + "")) { m.jsError("삭제하는 중 오류가 발생했습니다."); return; }

m.jsAlert("삭제하였습니다.");
m.jsReplace("../tag/tag_list.jsp?" + m.qs("id"));

%>