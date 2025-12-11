<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(41, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsErrClose("기본키는 반드시 지정해야 합니다."); return; }

//객체
MessageDao message = new MessageDao();
UserDao user = new UserDao();
MessageUserDao messageUser = new MessageUserDao();

//정보
DataSet info = message.query(
	"SELECT a.*, u.user_nm, u.login_id "
	+ " FROM " + message.table + " a "
	+ " LEFT JOIN " + user.table + " u ON a.user_id = u.id "
	+ " WHERE a.id = " + id + " AND a.status != -1 "
);
if(!info.next()) { m.jsErrClose("해당 정보가 없습니다."); return; }

//폼체크
f.addElement("subject", info.s("subject"), "hname:'제목', required:'Y'");
f.addElement("content", null, "hname:'내용', required:'Y'");

//수정
if(m.isPost() && f.validate()) {
	message.item("subject", f.get("subject"));
	message.item("content", f.get("content"));
	if(!message.update("id = " + id + "")) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	m.js("parent.opener.location.href = parent.opener.location.href;alert('수정되었습니다.');");
	m.jsReplace("message_view.jsp?id=" + id);
	return;
}

//포멧팅
info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", info.s("reg_date")));
info.put("send_cnt_conv", m.nf(info.i("send_cnt")));
info.put("send_block", info.i("send_cnt") > 0);

//출력
p.setLayout("pop");
p.setBody("message.message_view");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(info);
p.display();

%>