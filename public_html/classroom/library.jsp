<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
LibraryDao library = new LibraryDao();
FileDao file = new FileDao();
CourseLibraryDao courseLibrary = new CourseLibraryDao();


//폼체크
f.addElement("sf", null, null);
f.addElement("sq", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(15);
lm.setTable(
	courseLibrary.table + " a "
	+ "LEFT JOIN " + library.table + " l ON a.library_id = l.id "
);
lm.setFields("l.*");
lm.addWhere("l.status = 1");
lm.addWhere("l.site_id = " + siteId + "");
lm.addWhere("a.course_id = " + courseId + "");
if(!"".equals(f.get("sf"))) lm.addSearch(f.get("sf"), f.get("sq"), "LIKE");
else if("".equals(f.get("sf")) && !"".equals(f.get("sq"))) {
	lm.addSearch("l.library_nm, l.content", f.get("sq"), "LIKE");
}
lm.setOrderBy("l.reg_date DESC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("library_file_ek", m.encrypt(list.s("id") + m.time("yyyyMMdd")));
	list.put("library_file_ext", file.getFileIcon(list.s("library_file")));
	list.put("library_link_conv", (0 > list.s("library_link").indexOf("//") ? "http://" : "") + list.s("library_link"));
}

//출력
p.setLayout(ch);
p.setBody("classroom.library");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.display();

%>