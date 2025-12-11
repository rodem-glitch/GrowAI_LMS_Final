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
SurveyDao survey = new SurveyDao();
LmCategoryDao category = new LmCategoryDao("course");

//카테고리
DataSet categories = category.getList(siteId);

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
lm.setRequest(request);
lm.setListNum(10);
lm.setTable(survey.table + " a ");
lm.setFields("a.*");
lm.addWhere("a.status = 1");
lm.addWhere("a.site_id = " + siteId + "");
if(!"".equals(idx)) lm.addWhere("a.id NOT IN (" + idx + ")");
if(!"".equals(f.get("s_category"))) {
	lm.addWhere("a.category_id IN ( '" + m.join("','", category.getChildNodes(f.get("s_category"))) + "' )");
}
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.survey_nm", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.reg_date DESC");

//정보
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("name_conv", m.cutString(list.s("survey_nm"), 40));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), survey.statusList));
	list.put("cate_name", category.getTreeNames(list.i("category_id")));
}


//출력
p.setLayout("pop");
p.setBody("course.survey_select");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("idx_query", m.qs("idx"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setVar("course", cinfo);
p.setLoop("categories", categories);
p.display();

%>