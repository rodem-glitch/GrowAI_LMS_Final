<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
TutorDao tutor = new TutorDao();
UserDao user = new UserDao();

//폼체크
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);
f.addElement("s_listnum", null, null);
f.addElement("ord", null, null);

//변수-정렬
String ord = !"".equals(m.rs("ord")) ? m.getItem(m.rs("ord").toLowerCase(), user.ordList) : "";

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(f.getInt("s_listnum", 9));
lm.setFields("t.*");
lm.setTable(
	user.table + " a "
	+ " INNER JOIN " + tutor.table + " t ON a.id = t.user_id AND t.status = 1 "
);
lm.addWhere("a.site_id = " + siteId);
lm.addWhere("a.tutor_yn = 'Y'");
lm.addWhere("a.display_yn = 'Y'");
lm.addWhere("a.status = 1");
lm.addSearch("a.dept_id", f.get("did"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else lm.addSearch("t.tutor_nm, t.introduce", f.get("s_keyword"), "LIKE");
lm.setOrderBy(!"".equals(ord) ? ord : "t.sort asc, a.user_nm asc");

//목록
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("tutor_nm_conv", m.cutString(list.s("tutor_nm"), 18));
	list.put("introduce_conv", m.stripTags(list.s("introduce")));
	if(!"".equals(list.s("tutor_file"))) {
		list.put("tutor_file_url", m.getUploadUrl(list.s("tutor_file")));
	} else {
		list.put("tutor_file_url", "/html/images/common/noimage_tutor.jpg");
	}
}

//출력
p.setLayout(ch);
p.setBody("tutor.tutor_list");
p.setVar("p_title", "강사소개");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());

p.display();

%>