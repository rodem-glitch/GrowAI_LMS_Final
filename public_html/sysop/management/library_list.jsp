<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
LibraryDao library = new LibraryDao();
CourseLibraryDao courseLibrary = new CourseLibraryDao();

//처리
if("del".equals(m.rs("mode"))) {
	if(!courseLibrary.delete("course_id = " + courseId + " AND library_id = " + m.ri("id") + "")) {
		m.jsAlert("삭제하는 중 오류가 발생했습니다."); return;
	}

	m.jsReplace("library_list.jsp?cid=" + courseId, "parent");
	return;
}

//목록
DataSet list = courseLibrary.query(
	"SELECT l.*"
	+ " FROM " + courseLibrary.table + " a "
	+ " LEFT JOIN " + library.table + " l ON a.library_id = l.id "
	+ " WHERE a.course_id  = " + courseId + " "
);
while(list.next()) {
	list.put("library_nm_conv", m.cutString(list.s("library_nm"), 90));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), library.statusList));
	list.put("library_file_conv", m.encode(list.s("library_file")));
	list.put("library_file_ek", m.encrypt(list.s("library_file") + m.time("yyyyMMdd")));
}

//출력
p.setBody("management.library_list");
p.setVar("p_title", ptitle);
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total_count", list.size());
p.display();

%>