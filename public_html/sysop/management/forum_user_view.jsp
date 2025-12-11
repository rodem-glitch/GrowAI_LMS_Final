<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//MANAGEMENT

//접근권한
if(!Menu.accessible(75, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int fid = m.ri("fid");
int cuid = m.ri("cuid");
if(fid == 0 || cuid == 0 || courseId == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
CourseModuleDao courseModule = new CourseModuleDao();
CourseUserDao courseUser = new CourseUserDao();
ForumUserDao forumUser = new ForumUserDao();
UserDao user = new UserDao(isBlindUser);
UserDeptDao userDept = new UserDeptDao();	

//정보-모듈
DataSet minfo = courseModule.find("status = 1 AND module = 'forum' AND module_id = " + fid + " AND course_id = " + courseId + "");
if(!minfo.next()) { m.jsError("해당 평가 정보가 없습니다."); return; }

//정보
DataSet info = forumUser.query(
	"SELECT a.*, c.user_nm, c.login_id "
	+ " FROM " + forumUser.table + " a "
	+ " INNER JOIN " + courseUser.table + " b ON a.course_user_id = b.id AND b.status IN (1,3) "
	+ " INNER JOIN " + user.table + " c ON a.user_id = c.id " + (deptManagerBlock ? " AND c.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
	+ " WHERE a.course_user_id = " + cuid + " AND a.forum_id = " + fid + " AND b.course_id = " + courseId + " AND a.status = 1 "
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }
user.maskInfo(info);

//기록-개인정보조회
if("".equals(m.rs("mode")) && info.size() > 0 && !isBlindUser) _log.add("V", Menu.menuNm, info.size(), "이러닝 운영", info);

if("del".equals(m.rs("mode"))) {
	if(m.encrypt("del" + userId).equals(m.rs("dek"))) {
		forumUser.item("score",  0);
		forumUser.item("marking_score",  0);
		forumUser.item("feedback", "");
		forumUser.item("confirm_yn", "N");
		forumUser.item("confirm_user_id", userId);
		forumUser.item("confirm_date", "");

		if(!forumUser.update("forum_id = " + fid + " AND course_user_id = " + cuid + "")) {
			m.jsError("저장하는 중 오류가 발생했습니다."); return;
		}

		//점수 업데이트
		courseUser.setCourseUserScore(cuid, "forum");

		m.jsAlert("삭제되었습니다.");
		m.js("opener.location.href = opener.location.href; window.close();");
		return;
	} else {
		m.jsError("올바른 접근이 아닙니다.");
		return;
	}
}

//폼체크
f.addElement("score", info.s("marking_score"), "hname:'점수', required:'Y'");
f.addElement("content", null, "hname:'내용', allowhtml:'Y'");

//등록
if(m.isPost() && f.validate()) {

	forumUser.item("score", Math.min(minfo.d("assign_score"), minfo.d("assign_score") * m.parseDouble(f.get("score")) / 100));
	forumUser.item("marking_score", Math.min(m.parseDouble(f.get("score")), 100.0));
	forumUser.item("feedback", f.get("feedback"));
	forumUser.item("confirm_yn", "Y");
	forumUser.item("confirm_date", m.time("yyyyMMddHHmmss"));
	forumUser.item("confirm_user_id", userId);

	if(!forumUser.update("forum_id = " + fid + " AND course_user_id = " + cuid + "")) {
		m.jsError("저장하는 중 오류가 발생했습니다."); return;
	}

	//점수 업데이트
	courseUser.setCourseUserScore(cuid, "forum");

	m.jsAlert("저장하였습니다.");
	m.js("opener.location.href = opener.location.href; window.close();");
	m.js("window.close();");
	return;
}

info.put("reg_date_conv", m.time("yyyy.MM.dd HH:mm", (!"".equals(info.s("mod_date")) ? info.s("mod_date") : info.s("reg_date"))));
info.put("confirm_str", "Y".equals(info.s("confirm_yn")) ? "평가완료" : "미평가");
info.put("confirm_block", "Y".equals(info.s("confirm_yn")));
info.put("post_cnt", info.i("post_cnt"));

//이전다음글
Vector<String> cond = new Vector<String>();
String submitYn = m.rs("s_submit_yn", "Y");
if("".equals(submitYn)) submitYn = "Y";
if(!"".equals(m.rs("s_keyword"))) {
	if("".equals(m.rs("s_field"))) {
		cond.add("( "
			+ " a.user_id LIKE '%" +  m.rs("s_keyword") + "%' "
			+ " OR b.subject LIKE '%" +  m.rs("s_keyword") + "%' "
			+ " OR c.user_nm LIKE '%" +  m.rs("s_keyword") + "%' "
		+ " )");
	} else {
		cond.add(m.rs("s_field") + " LIKE '%" +  m.rs("s_keyword") + "%'");
	}
}
if("Y".equals(submitYn) && !"".equals(m.rs("s_confirm_yn"))) cond.add("b.confirm_yn = '" + m.rs("s_confirm_yn") + "'");

DataSet prev = forumUser.query(
	"SELECT a.id cuid, a.user_id u_id "
	+ ", b.* "
	+ ", c.user_nm, c.login_id "
	+ " FROM " + courseUser.table + " a "
	+ " LEFT JOIN " + forumUser.table + " b ON b.course_user_id = a.id AND b.forum_id = " + fid + " AND b.status = 1 "
	+ " INNER JOIN " + user.table + " c ON a.user_id = c.id " + (deptManagerBlock ? " AND c.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
	+ " WHERE a.id > " + cuid + " "
	+ " AND a.status IN (1,3) AND a.course_id = " + courseId + " "
	+ " AND " + (!"Y".equals(submitYn) ? "NOT" : "") + " EXISTS (SELECT 1 FROM " + forumUser.table + " WHERE course_user_id = a.id AND forum_id = " + fid + " AND status = 1) "
	+ (cond.isEmpty() ? "" : " AND " + (m.join(" AND ", cond.toArray())))
	+ " ORDER BY a.id ASC, c.user_nm DESC "
	, 1
);
DataSet next = forumUser.query(
	"SELECT a.id cuid, a.user_id u_id "
	+ ", b.* "
	+ ", c.user_nm, c.login_id "
	+ " FROM " + courseUser.table + " a "
	+ " LEFT JOIN " + forumUser.table + " b ON b.course_user_id = a.id AND b.forum_id = " + fid + " AND b.status = 1 "
	+ " INNER JOIN " + user.table + " c ON a.user_id = c.id " + (deptManagerBlock ? " AND c.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ") " : "")
	+ " WHERE a.id < " + cuid + " "
	+ " AND a.status IN (1,3) AND a.course_id = " + courseId + " "
	+ " AND " + (!"Y".equals(submitYn) ? "NOT" : "") + " EXISTS (SELECT 1 FROM " + forumUser.table + " WHERE course_user_id = a.id AND forum_id = " + fid + " AND status = 1)"
	+ (cond.isEmpty() ? "" : " AND " + (m.join(" AND ", cond.toArray())))
	+ " ORDER BY a.id DESC, c.user_nm ASC "
	, 1
);

if(prev.next()) {
	prev.put("mod_date", m.time("yyyy.MM.dd HH:mm", (!"".equals(prev.s("mod_date")) ? prev.s("mod_date") : prev.s("reg_date"))));
	prev.put("post_cnt", m.nf(prev.i("post_cnt")));
}
if(next.next()) {
	next.put("mod_date", m.time("yyyy.MM.dd HH:mm", (!"".equals(next.s("mod_date")) ? next.s("mod_date") : next.s("reg_date"))));
	next.put("post_cnt", m.nf(next.i("post_cnt")));
}

//출력
p.setLayout("pop");
p.setBody("management.forum_user_view");
p.setVar("p_title", "토론 평가");
p.setVar("query", m.qs("mode, tceuid"));
p.setVar("list_query", m.qs("cuid,mode,tceuid"));
p.setVar("form_script", f.getScript());

p.setVar("info", info);
p.setVar("dek", m.encrypt("del" + userId));
p.setVar("next", next);
p.setVar("prev", prev);

p.display();

%>