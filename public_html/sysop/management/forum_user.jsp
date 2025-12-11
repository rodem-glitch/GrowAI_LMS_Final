<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int fid = m.ri("fid");
if(fid == 0 || courseId == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

String submitYn = m.rs("s_submit_yn", "Y");
if("".equals(submitYn)) submitYn = "Y";

//객체
CourseModuleDao courseModule = new CourseModuleDao();
CourseUserDao courseUser = new CourseUserDao();
ForumDao forum = new ForumDao();
ForumUserDao forumUser = new ForumUserDao();
ForumPostDao forumPost = new ForumPostDao();
UserDao user = new UserDao(isBlindUser);
UserDeptDao userDept = new UserDeptDao();

//정보
DataSet info = courseModule.query(
	"SELECT a.course_id, a.apply_type, a.start_date, a.end_date, a.chapter, a.assign_score "
	+ ", h.* "
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + forum.table + " h ON a.module_id = h.id "
	+ " WHERE a.status = 1 AND a.module = 'forum' "
	+ " AND a.module_id = " + fid + " AND a.course_id = " + courseId + " "
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }


//처리
if("cancel".equals(m.rs("mode"))) {

	//기본키
	int cuid = m.ri("cuid");
	if(cuid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

	//정보-응시자정보
	DataSet euinfo = forumUser.find("forum_id = " + fid + " AND course_user_id = " + cuid + "");
	if(!euinfo.next()) { m.jsError("해당 제출 정보가 없습니다."); return; }

	//삭제
	if(!forumUser.delete("forum_id = " + fid + " AND course_user_id = " + cuid + "")) {
		m.jsError("제출 취소하는 중 오류가 발생했습니다."); return;
	}

	//삭제
	if(-1 == forumPost.execute(
		"UPDATE " + forumPost.table + " SET "
		+ " status = -1 "
		+ " WHERE forum_id = " + fid + " AND course_id = " + courseId + " "
		+ " AND course_user_id = " + cuid + " AND status != -1 "
	)) {
		m.jsError("제출 취소하는 중 오류가 발생했습니다."); return;
	}

	//점수 업데이트
	courseUser.setCourseUserScore(cuid, "forum");

	m.jsAlert("참여취소 되었습니다.");
	m.jsReplace("forum_user.jsp?" + m.qs("mode,fu_idx,cuid"), "parent");
	return;
}

//처리
if(m.isPost()) {
	//제출
	if("mark".equals(f.get("mode"))) {
		String idx = f.get("fu_idx");
		if("".equals(idx)) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

		if(-1 == forumUser.execute(
			"UPDATE " + forumUser.table + " "
			+ " SET submit_yn = 'Y' "
			+ " WHERE course_user_id IN (" + idx + ") "
			+ " AND course_id = " + courseId + " AND forum_id = " + fid + " "
			+ " AND status = 1 "
		)) {
			m.jsError("제출 처리하는 중 오류가 발생했습니다."); return;
		}
	} else if("mod".equals(f.get("mode"))) {
		//기본키
		int cuid = f.getInt("cuid");
		int score = f.getInt("score");
		if(cuid == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

		//총점 저장
		if(-1 == forumUser.execute(
			"UPDATE " + forumUser.table + " "
			+ " SET confirm_yn = 'Y' "
			+ ", score = " + Math.min(info.d("assign_score"), info.d("assign_score") * score / 100) + " "
			+ ", marking_score = " + Math.min(score, 100.0) + " "
			+ ", confirm_user_id = " + userId + " "
			+ ", confirm_date = '" + m.time("yyyyMMddHHmmss") + "' "
			+ " WHERE forum_id = " + fid + " AND course_user_id = " + cuid + " "
		)) {
			m.jsError("평가하는 중 오류가 발생했습니다."); return;
		}

		//점수 업데이트
		courseUser.setCourseUserScore(cuid, "forum");

		m.jsAlert("수정되었습니다.");
	}

	m.jsReplace("forum_user.jsp?" + m.qs("mode,fu_idx,cuid"), "parent");
	return;
}

//폼체크
f.addElement("s_submit_yn", submitYn, null);
f.addElement("s_confirm_yn", null, null);
f.addElement("s_out_yn", null, null);
f.addElement("s_delete_yn", null, null);
f.addElement("s_field", null, null);
f.addElement("s_keyword", null, null);

//목록
ListManager lm = new ListManager();
//lm.d(out);
lm.setRequest(request);
lm.setListNum("excel".equals(m.rs("mode")) || "download".equals(m.rs("mode")) ? 20000 : 20);
lm.setTable(
	courseUser.table + " a"
	+ " LEFT JOIN " + forumUser.table + " b ON b.course_user_id = a.id AND b.forum_id = " + fid + " AND b.status = 1 "
	+ " INNER JOIN " + user.table + " c ON c.id = a.user_id " + (!"Y".equals(f.get("s_out_yn")) ? " AND c.status != -1 " : "")
			+ (deptManagerBlock ? " AND c.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
);
lm.setFields(
	"a.id, a.user_id u_id"
	+ ", b.*"
	+ ", c.user_nm, c.login_id "
);
if(!"Y".equals(f.get("s_delete_yn"))) lm.addWhere("a.status IN (1,3)");
lm.addWhere("a.course_id = " + courseId + "");
lm.addWhere(
	(!"Y".equals(submitYn) ? "NOT" : "")
	+ " EXISTS ( "
		+ " SELECT 1 FROM " + forumUser.table + " "
		+ " WHERE course_user_id = a.id AND forum_id = " + fid + " AND status = 1 "
	+" )"
);
if("Y".equals(submitYn)) { lm.addSearch("b.confirm_yn", f.get("s_confirm_yn")); }
if(!"".equals(f.get("s_field"))) lm.addSearch(f.get("s_field"), f.get("s_keyword"), "LIKE");
else if("".equals(f.get("s_field")) && !"".equals(f.get("s_keyword"))) {
	lm.addSearch("c.login_id,c.user_nm", f.get("s_keyword"), "LIKE");
}
lm.setOrderBy("a.id DESC, c.user_nm ASC");

//포맷팅
DataSet list = lm.getDataSet();
while(list.next()) {
	list.put("reg_date_conv", !"".equals(list.s("reg_date")) ? m.time("yyyy.MM.dd HH:mm", list.s("reg_date")) : "-");
	list.put("confirm_conv", "Y".equals(list.s("confirm_yn")) ? "평가완료" : "미평가");
	list.put("marking_score_conv", m.nf(list.d("marking_score"), 0));
	double score = Math.min(info.d("assign_score"), info.d("assign_score") * list.d("marking_score") / 100);
	list.put("score_conv", m.nf(score, 2));
	list.put("post_cnt_conv", m.nf(list.i("post_cnt")));
	user.maskInfo(list);
}

//기록-개인정보조회
if("".equals(m.rs("mode")) && list.size() > 0 && !isBlindUser) _log.add("L", Menu.menuNm, list.size(), "이러닝 운영", list);

//엑셀
if("excel".equals(m.rs("mode"))) {
	if(list.size() > 0 && !isBlindUser) _log.add("E", Menu.menuNm, list.size(), "이러닝 운영", list);

	ExcelWriter ex = new ExcelWriter(response, "[" + info.s("year") + "_" + info.s("step") + "_" + info.s("course_nm") + "]" + info.s("module_nm") + "_토론참여자현황.xls");
	ex.setData(list, new String[] { "__ord=>No", "user_nm=>이름", "u_id=>회원ID", "login_id=>로그인ID", "subject=>제목", "reg_date=>제출일", "confirm_str=>평가여부", "marking_score_conv=>취득점수", "score_conv=>환산점수" }, "[" + info.s("year") + "_" + info.s("step") + "_" + info.s("course_nm") + "]" + info.s("module_nm") + "_토론참여자현황");
	ex.write();
	return;
}

//출력
p.setLayout("blank");
p.setBody("management.forum_user");
p.setVar("query", m.qs("mode"));
p.setVar("list_query", m.qs("mode,fu_idx,cuid"));
p.setVar("form_script", f.getScript());

p.setVar("forum", info);

p.setLoop("list", list);
p.setVar("list_total", lm.getTotalString());
p.setVar("pagebar", lm.getPaging());

p.setVar("confirm_block", "Y".equals(submitYn));
p.setVar("offline_block", "F".equals(info.s("onoff_type")));
p.setVar("mod_block",  "Y".equals(submitYn) && "F".equals(info.s("onoff_type")));
p.display();

%>