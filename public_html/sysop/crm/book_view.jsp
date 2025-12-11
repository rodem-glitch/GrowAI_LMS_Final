<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int buid = m.ri("buid");
if(buid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
BookDao book = new BookDao();
BookUserDao bookUser = new BookUserDao();

LessonDao lesson = new LessonDao();

//변수
String today = m.time("yyyyMMdd");

//정보-수강생
DataSet buinfo = bookUser.query(
	"SELECT a.* "
	+ ", (CASE WHEN '" + today + "' BETWEEN a.start_date AND a.end_date THEN 'Y' ELSE 'N' END) is_study "
	+ ", u.user_nm, u.login_id "
	+ " FROM " + bookUser.table + " a "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id AND u.site_id = " + siteId + " AND u.status != -1 "
	+ " WHERE a.id = " + buid + " AND a.user_id = " + uid + " "
);
if(!buinfo.next()) { m.jsError("해당 수강생정보가 없습니다."); return; }
int bookId = buinfo.i("book_id");

//정보-도서
DataSet binfo = book.find("id = " + bookId + " AND site_id = " + siteId + " AND status != -1");
if(!binfo.next()) { m.jsAlert("해당 도서정보가 없습니다."); return; }

//폼체크
f.addElement("start_date", null, "hname:'학습 시작일', required:'Y'");
f.addElement("end_date", null, "hname:'학습 종료일', required:'Y'");
f.addElement("permanent_yn", null, "hname:'영구소장여부'");

//대여기간 수정
if(m.isPost() && f.validate()) {

	String permanentYn = f.get("permanent_yn");

	bookUser.item("start_date", m.time("yyyyMMdd", f.get("start_date")));
	bookUser.item("end_date", !"Y".equals(permanentYn) ? m.time("yyyyMMdd", f.get("end_date")) : "99991231");
	bookUser.item("permanent_yn", f.get("permanent_yn"));
	if(!bookUser.update("id = " + buid + "")) { m.jsError("수정하는 중 오류가 발생했습니다."); return; }

	m.jsReplace("book_view.jsp?" + m.qs());
	return;
}

//포맷팅
buinfo.put("status_conv", m.getItem(buinfo.s("status"), bookUser.statusList));
buinfo.put("period_block", "Y".equals(buinfo.s("period_yn")));

buinfo.put("start_date_conv", m.time("yyyy-MM-dd", buinfo.s("start_date")));
buinfo.put("end_date_conv", m.time("yyyy-MM-dd", buinfo.s("end_date")));
buinfo.put("mod_date_conv", !"".equals(buinfo.s("mod_date")) ? m.time("yyyy.MM.dd HH:mm", buinfo.s("mod_date")) : "-");
buinfo.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", buinfo.s("reg_date")));

//출력
p.setLayout(ch);
p.setBody("crm.book_view");
p.setVar("p_title", "대여정보");
p.setVar("query", m.qs("mode, cp, pchapter"));
p.setVar("list_query", m.qs("buid, mode, cp, pchapter"));
p.setVar("query", m.qs());

p.setVar("buinfo", buinfo);
p.setVar("book", binfo);

p.setVar("tab_book", "current");
p.display();

%>