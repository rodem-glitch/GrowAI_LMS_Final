<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(72, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
ExamDao exam = new ExamDao();
LmCategoryDao category = new LmCategoryDao();
UserDao user = new UserDao();

//카테고리
DataSet categories = category.getList(siteId);

//폼체크
f.addElement("s_category", null, null);
f.addElement("s_sdate", null, null);
f.addElement("s_edate", null, null);

f.addElement("s_subject", null, null);
f.addElement("s_status", null, null);
f.addElement("s_onofftype", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(20);
lm.setTable(
	exam.table + " a "
	+ " LEFT JOIN " + user.table + " u ON a.manager_id = u.id "
);
lm.setFields("a.*, u.user_nm manager_nm, u.login_id");
lm.addWhere("a.status != -1");
lm.addWhere("a.site_id = " + siteId + "");
if(courseManagerBlock) lm.addWhere("a.manager_id IN (-99, " + userId + ")");
lm.addSearch("a.status", f.get("s_status"));
lm.addSearch("a.category_id", f.get("s_category_id"));
lm.addSearch("a.onoff_type", f.get("s_onofftype"));
lm.addSearch("a.reg_date", m.time("yyyyMMdd000000", f.get("s_sdate")), ">=");
lm.addSearch("a.reg_date", m.time("yyyyMMdd235959", f.get("s_edate")), "<=");
if(!"".equals(f.get("s_category"))) {
	lm.addWhere("a.category_id IN ( '" + m.join("','", category.getChildNodes(f.get("s_category"))) + "' )");
}
//if("C".equals(userKind)) lm.addWhere("a.manager_id = " + userId);
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("a.exam_nm", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy(!"".equals(m.rs("ord")) ? m.rs("ord") : "a.id DESC");

//포멧팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("exam_nm_conv", m.cutString(list.s("exam_nm"), 90));
	list.put("reg_date_conv", m.time("yyyy.MM.dd", list.s("reg_date")));
	list.put("status_conv", m.getItem(list.s("status"), exam.statusList));
	list.put("onoff_type_conv", m.getItem(list.s("onoff_type"), exam.onoffTypes));
	list.put("online_block", "N".equals(list.s("onoff_type")));
	list.put("cate_name", category.getTreeNames(list.i("category_id")));

	list.put("manager_block", 0 < list.i("manager_id"));
	if(-99 == list.i("manager_id")) list.put("manager_nm_conv", "공용");
	else if(1 > list.i("manager_id")) list.put("manager_nm_conv", "없음");
	else list.put("manager_nm_conv", list.s("manager_nm"));
}

//엑셀
if("excel".equals(m.rs("mode"))) {
	ExcelWriter ex = new ExcelWriter(response, "시험관리(" + m.time("yyyy-MM-dd") + ").xls");
	ex.setData(list, new String[] { "__ord=>No", "onoff_type_conv=>구분", "exam_nm=>시험명", "content=>시험내용", "exam_time=>시험시간", "question_cnt=>문항수", "mcnt1=>난이도 1의 객관식 문항수", "mcnt2=>난이도 2의 객관식 문항수", "mcnt3=>난이도 3의 객관식 문항수", "mcnt4=>난이도 4의 객관식 문항수", "mcnt5=>난이도 5의 객관식 문항수", "tcnt1=>난이도 1의 주관식 문항수", "tcnt2=>난이도 2의 주관식 문항수", "tcnt3=>난이도 3의 주관식 문항수", "tcnt4=>난이도 4의 주관식 문항수", "tcnt5=>난이도 5의 주관식 문항수", "assign1=>난이도 1의 배점", "assign2=>난이도 2의 배점", "assign3=>난이도 3의 배점", "assign4=>난이도 4의 배점", "assign5=>난이도 5의 배점", "shuffle_yn=>보기섞기여부", "auto_complete_yn=>자동채점여부", "reg_date_conv=>등록일", "status_conv=>상태" }, "시험관리(" + m.time("yyyy-MM-dd") + ")");
	ex.write();
	return;
}


//출력
p.setBody("exam.exam_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id,onoff"));
p.setVar("form_script", f.getScript());

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setLoop("status_list", m.arr2loop(exam.statusList));
p.setLoop("categories", categories);
p.setLoop("onoff_types", m.arr2loop(exam.onoffTypes));

p.display();

%>