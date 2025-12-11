<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(33, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int cid = m.ri("cid");
if(cid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//폼입력
String idx = m.rs("idx");

//객체
CourseDao course = new CourseDao();
HomeworkDao homework = new HomeworkDao();
LmCategoryDao category = new LmCategoryDao();

//정보
DataSet cinfo = course.find(
	"id = " + cid + " AND status != -1 AND site_id = " + siteId + ""
	+ ("C".equals(userKind) ? " AND id IN (" + manageCourses + ") " : "")
);
if(!cinfo.next()) { m.jsError("해당 정보가 없습니다."); return; }
cinfo.put("study_sdate_conv", m.time("yyyy-MM-dd", cinfo.s("study_sdate")));
cinfo.put("study_edate_conv", m.time("yyyy-MM-dd", cinfo.s("study_edate")));

//폼체크
f.addElement("s_category", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(10);
lm.setTable(
	homework.table + " a "
	
);
lm.setFields("a.*");
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId + "");
if(!"".equals(idx)) lm.addWhere("a.id NOT IN (" + idx + ")");
lm.addSearch("a.category_id", f.get("s_category"));
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.homework_nm", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("homework_nm_conv", m.cutString(list.s("homework_nm"), 90));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), homework.statusList));
}



//출력
p.setLayout("pop");
p.setBody("course.homework_select");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("idx_query", m.qs("idx"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setVar("course", cinfo);
p.setLoop("categories", category.getList(siteId));
p.display();

%>