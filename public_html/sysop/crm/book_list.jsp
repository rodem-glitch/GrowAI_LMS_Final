<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
BookUserDao bookUser = new BookUserDao();
BookDao book = new BookDao();

//변수
String today = m.time("yyyyMMdd");

//폼체크
f.addElement("course_id", null, "hname:'신청과정',required:'Y'");
f.addElement("course_nm", null, "hname:'신청과정',required:'Y'");

//수강중인 과정
DataSet list1 = bookUser.query(
	" SELECT a.*, b.book_nm "
	+ " FROM " + bookUser.table + " a "
	+ " INNER JOIN " + book.table + " b ON a.book_id = b.id "
	+ " INNER JOIN " + user.table + " u ON u.id = a.user_id AND u.status != -1 "
	+ " WHERE a.user_id = " + uid + " AND a.status IN (0, 1, 3) "
	+ " AND (a.permanent_yn = 'Y' OR a.end_date >= '" + today + "') "
	+ " ORDER BY a.start_date ASC, a.id DESC "
);
while(list1.next()) {
	list1.put("start_date_conv", m.time("yyyy.MM.dd", list1.s("start_date")));
	list1.put("end_date_conv", m.time("yyyy.MM.dd", list1.s("end_date")));
	list1.put("study_date_conv", list1.s("start_date_conv") + " - " + list1.s("end_date_conv"));
	list1.put("book_nm_conv", m.cutString(list1.s("book_nm"), 80));
	list1.put("status_conv", m.getItem(list1.s("status"), bookUser.statusList));
}

//종료된 과정
DataSet list2 = bookUser.query(
	" SELECT a.*, b.book_nm "
	+ " FROM " + bookUser.table + " a "
	+ " INNER JOIN " + book.table + " b ON a.book_id = b.id "
	+ " INNER JOIN " + user.table + " u ON u.id = a.user_id AND u.status != -1 "
	+ " WHERE a.user_id = " + uid + " AND a.status IN (1, 3) "
	+ " AND a.end_date < '" + today + "' "
	+ " ORDER BY a.end_date DESC, a.id DESC "
);
while(list2.next()) {
	list2.put("start_date_conv", m.time("yyyy.MM.dd", list2.s("start_date")));
	list2.put("end_date_conv", m.time("yyyy.MM.dd", list2.s("end_date")));
	list2.put("study_date_conv", list2.s("start_date_conv") + " - " + list2.s("end_date_conv"));
	list2.put("book_nm_conv", m.cutString(list2.s("book_nm"), 80));
	list2.put("status_conv", m.getItem(list2.s("status"), bookUser.statusList));
}

//출력
p.setLayout(ch);
p.setBody("crm.book_list");
p.setVar("tab_book", "current");
p.setVar("form_script", f.getScript());
p.setVar("list_query", m.qs("cuid"));

p.setLoop("list1", list1);
p.setLoop("list2", list2);

p.display();

%>