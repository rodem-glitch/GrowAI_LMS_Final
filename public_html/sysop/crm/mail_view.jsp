<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
MailDao mail = new MailDao();
MailUserDao mailUser = new MailUserDao();

int mid = m.ri("mid");
if(mid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

DataSet info = mail.query(
	"SELECT a.*, b.user_nm, b.email, b.login_id "
	+ " FROM " + mail.table + " a "
	+ " INNER JOIN " + mailUser.table + " mu ON a.id = mu.mail_id AND mu.send_yn = 'Y'"
	+ " INNER JOIN " + user.table + " ru ON mu.user_id = ru.id AND ru.site_id = " + siteId + " AND ru.status != -1 "
	+ " LEFT JOIN " + user.table + " b ON a.user_id = b.id AND b.status != -1 "
	+ " WHERE a.id = " + mid + ""
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm:ss", info.s("reg_date")));

if(info.i("user_id") == -9) {
	info.put("user_nm", "(자동)");
	info.put("login_id", "SYSTEM");
}

//출력
p.setLayout(ch);
p.setBody("crm.mail_view");
p.setVar("p_title", "메일상세보기");
p.setVar("list_query", m.qs("mid"));

p.setVar(info);
p.setVar("tab_sent", "current");
p.setVar("tab_sub_mail", "current");

p.display();

%>