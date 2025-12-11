<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//접근권한
Menu.accessible(102, userId, userKind);

//폼입력
String mode = m.rs("mode");

//객체
CourseDao course = new CourseDao();
CourseMainDao courseMain = new CourseMainDao();

//목록-타입
String types[] = m.split("|", SiteConfig.s("main_course_types"));
DataSet list = m.arr2loop(types);
list.sort("name", "asc");

if("json".equals(m.rs("mode"))) {
	response.setContentType("application/json;charset=utf-8");
	out.print(list.serialize());
	return;
}

//폼체크
f.addElement("type", null, "hname:'코드', required:'Y'");
f.addElement("type_nm", null, "hname:'영역명', required:'Y'");

//처리
if(m.isPost()) {
	//변수
	Hashtable<String, String> typeMap = new Hashtable<String, String>();

	//공통
	while(list.next()) {
		typeMap.put(list.s("id"), list.s("name"));
	}

	if("reg".equals(mode) || "mod".equals(mode)) {
		//등록.수정
		typeMap.put(f.get("type"), f.get("type_nm"));

	} else if("del".equals(mode)) {
		//삭제

		//제한-최소
		if(2 > typeMap.size()) {
			m.jsAlert("최소한 하나의 진열영역은 있어야 합니다.");
			return;
		}

		//제한-등록과정
		int courseCnt = courseMain.getOneInt(
			" SELECT COUNT(*) FROM " + courseMain.table + " a "
			+ " INNER JOIN " + course.table + " c ON a.course_id = c.id AND c.status != -1 "
			+ " WHERE a.site_id = " + siteId + " AND type = ? "
			, new String[] { f.get("type") }
		);
		if(0 < courseCnt) {
			m.jsAlert("진열된 과정이 있는 진열영역은 삭제할 수 없습니다.");
			return;
		}

		if(typeMap.containsKey(f.get("type"))) typeMap.remove(f.get("type"));
	}
	if(typeMap.containsKey("")) typeMap.remove("");

	//저장
	String type = "";
	int cnt = 0;
    for(Map.Entry<String, String> entry : typeMap.entrySet()) {
        type += entry.getKey() + "=>" + entry.getValue() + (++cnt < typeMap.size() ? "|" : "");
    }
	SiteConfig.put("main_course_types", type);

	m.jsReplace("course_main_type.jsp", "parent");
	return;
}

//출력
p.setLayout("pop");
p.setBody("course.course_main_type");
p.setVar("p_title", "진열영역관리");
p.setVar("form_script",  f.getScript());
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());

p.setLoop("list", list);

p.display(out);

%>