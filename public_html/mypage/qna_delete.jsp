<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
QnaDao qna = new QnaDao();

//정보
DataSet info = qna.find("id = " + id);
if(!info.next()) { m.jsError(_message.get("alert.common.nodata")); return; }

if(info.i("user_id") != userId) { m.jsError(_message.get("alert.common.permission_delete")); return; }

qna.item("status", -1);

if(!qna.update("id = " + id)) { m.jsError(_message.get("alert.common.error_delete")); return; }

if(!"".equals(info.s("qna_file"))) {
	qna.item("qna_file", "");
	if(!qna.update("id = " + id)) {}
}

m.jsReplace("qna_list.jsp?" + m.qs("id"));

%>
