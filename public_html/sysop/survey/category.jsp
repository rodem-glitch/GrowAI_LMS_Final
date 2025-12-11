<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(35, userId, userKind)) { m.jsErrClose("접근 권한이 없습니다."); return; }

//폼입력
int id = m.ri("id");
String mode = m.rs("mode");
String md = m.rs("md");

//객체
SurveyCategoryDao category = new SurveyCategoryDao();
SurveyQuestionDao question = new SurveyQuestionDao();

//폼체크
f.addElement("category_nm", null, "hname:'설문분류명', required:'Y'");

//모드별처리
if(!courseManagerBlock && m.isPost()) {

	//공통
	category.item("category_nm", f.get("category_nm"));

	//등록
	if("reg".equals(mode)) {
		category.item("site_id", siteId);
		category.item("reg_date", m.time("yyyyMMddHHmmss"));
		category.item("status", 1);
		if(!category.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }

		m.jsAlert("등록되었습니다.");
	//수정
	} else if("mod".equals(mode)) {
		if(id == 0) { m.jsAlert("기본키는 반드시 지정해야 합니다. "); return; }

		//정보
		DataSet info = category.find("id = " + id + " AND status != -1 AND site_id = " + siteId + "");
		if(!info.next()){ m.jsAlert("해당 정보가 없습니다."); return; }

		if(!category.update("id = " + id + "")) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

		m.jsAlert("수정되었습니다.");
	//삭제
	} else if("del".equals(mode)) {
		if(id == 0) { m.jsAlert("기본키는 반드시 지정해야 합니다. "); return; }

		//정보
		DataSet info = category.find("id = " + id + " AND status != -1 AND site_id = " + siteId + "");
		if(!info.next()){ m.jsAlert("해당 정보가 없습니다."); return; }

		//제한
		if(0 < question.findCount("category_id = " + id + " AND status != -1")) {
			m.jsAlert("해당 설문분류는 설문문항에서 사용중입니다.. 삭제할 수 없습니다.");
			return;
		}

		category.item("status", -1);
		if(!category.update("id = '" + id + "'")) { m.jsAlert("삭제하는 중 오류가 발생하였습니다."); return; }

		m.jsAlert("삭제되었습니다.");
	}

	m.jsReplace("category.jsp?" + m.qs("mode"), "parent");
	return;
}

//목록
ListManager lm = new ListManager();
lm.setRequest(request);
lm.setListNum(10);
lm.setTable(category.table + " a");
lm.setFields("a.*");
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId + "");
lm.setOrderBy("a.id DESC");
//lm.setOrderBy("a.category_nm ASC");

DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("delete_block", list.i("item_cnt") == 0);
}


//출력
p.setLayout("pop");
p.setBody("survey.category");
p.setVar("p_title", "설문분류 관리");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("pagebar", lm.getPaging());
p.setVar("list_total", lm.getTotalString());

p.setVar(md + "_block", true);
p.display();

%>