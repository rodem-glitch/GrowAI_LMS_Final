<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(132, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//객체
UserDao user = new UserDao(isBlindUser);
UserDeptDao userDept = new UserDeptDao();
CourseUserDao courseUser = new CourseUserDao();

//폼체크
f.addElement("user_nm", null, "hname:'성명', required:'Y'");

if(m.isPost() && f.validate()) {

	//목록
	DataSet list = user.query(
		" SELECT a.* "
		+ " , (SELECT COUNT(*) FROM " + courseUser.table + " WHERE user_id = a.id AND site_id = a.site_id AND status IN (0, 1, 3)) course_user_cnt "
		+ " FROM " + user.table + " a "
		+ " WHERE a.user_nm = ? AND a.site_id = " + siteId + " AND a.status != -1 "
		+ " ORDER BY a.birthday ASC "
		, new String[] { f.get("user_nm") }
	);
	while(list.next()) {
		if(0 < list.i("dept_id")) {
			list.put("dept_nm_conv", userDept.getNames(list.i("dept_id")));
		} else {
			list.put("dept_nm", "[미소속]");
			list.put("dept_nm_conv", "[미소속]");
		}
		list.put("birthday_conv", m.time("yyyy.MM.dd", list.s("birthday")));
		list.put("mobile_conv", "-");
		list.put("mobile_conv", !"".equals(list.s("mobile")) ? list.s("mobile") : "" );

		list.put("gender_conv", m.getItem(list.s("gender"), user.genders));
		list.put("course_user_cnt_conv", m.nf(list.i("course_user_cnt")));

		String key = m.getUniqId();
		list.put("key", key);
		list.put("ek", m.encrypt(list.s("id") + "_LMS-USCH2017!_" + key + "_" + m.time("yyyyMMdd")));
		user.maskInfo(list);
	}

	//기록-개인정보조회
	if(list.size() > 0 && !isBlindUser) _log.add("v", Menu.menuNm, list.size(), "이러닝 운영", list);

	//출력
	p.setLayout("blank");
	p.setBody("complete.user_search");
	p.setVar("query", m.qs());
	p.setVar("list_query", m.qs("id"));
	p.setVar("form_script", f.getScript());

	p.setLoop("list", list);
	p.setVar("list_area", true);
	p.display();

	return;
}

//출력
p.setBody("complete.user_search");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id,sid"));
p.setVar("form_script", f.getScript());

p.setVar("search_area", true);
p.display();

%>