<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(29, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int cid = m.ri("cid");
if(cid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
ContentDao content = new ContentDao();
CourseLessonDao courseLesson = new CourseLessonDao();
LessonDao lesson = new LessonDao();

//정보-콘텐츠
DataSet cinfo = content.find("id = " + cid + " AND status != -1 AND site_id IN (0, " + siteId + ")");
if(!cinfo.next()) {	m.jsError("해당 정보가 없습니다.");	return; }

//수정
if(m.isPost() && f.validate()) {
	if("sort".equals(f.get("mode"))) {
		//순서정렬-활성
		if(f.getArr("lesson_id") != null) {
			int sort = 0;
			for(int i = 0; i < f.getArr("lesson_id").length; i++) {
				lesson.item("sort", ("Y".equals(f.getArr("use_yn")[i]) ? ++sort : 99999));
				if(!lesson.update("id = " + m.parseInt(f.getArr("lesson_id")[i]) + " AND content_id = " + cid)) { }
			}
		}

		//이동
		m.jsAlert("수정되었습니다.");
		m.jsReplace("lesson_list.jsp?" + m.qs(), "parent");
		return;
	} else if("time".equals(f.get("mode"))) {
		//기본키
		int lid = f.getInt("lesson_id");
		if(0 == lid) { m.jsAlert("기본키는 반드시 지정해야 합니다."); return; }

		//수정
		int completeTime = f.getInt("complete_time");
		lesson.item("complete_time", completeTime);
		if(!lesson.update("id = " + lid)) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

		//이동
		m.jsReplace("lesson_list.jsp?" + m.qs(), "parent");
		return;
	}
}

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum(1000);
lm.setTable(lesson.table + " a");
lm.setFields("a.*");
lm.addWhere("a.site_id = " + siteId + " AND a.content_id = " + cid + "");
lm.addWhere("a.status != -1");
if("C".equals(userKind)) lm.addWhere("a.manager_id = " + userId);
lm.setOrderBy("a.use_yn desc, a.sort asc, a.id desc");

//포멧팅
DataSet sortList = new DataSet();
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("complete_time_conv", m.nf(list.i("complete_time")));
	list.put("lesson_type_conv", m.getItem(list.s("lesson_type"), lesson.allLessonTypes));
	list.put("pc_block", !"".equals(list.s("start_url")));
	list.put("mobile_block", !"".equals(list.s("mobile_a")));

	sortList.addRow();
	sortList.put("id", list.i("__asc"));
	sortList.put("name", list.i("__asc"));
}

//출력
p.setBody("content.lesson_list");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar("list_total", lm.getTotalString());
p.setLoop("list", list);

p.setVar("content", cinfo);
p.setLoop("sort_list", sortList);
p.setLoop("use_types", m.arr2loop(lesson.useTypes));
p.display();

%>