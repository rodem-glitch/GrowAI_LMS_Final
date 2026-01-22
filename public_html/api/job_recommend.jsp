<%@ page contentType="application/json; charset=utf-8" %>
<%@ page import="dao.*,malgnsoft.db.*,malgnsoft.util.*" %>
<%@ page import="org.json.JSONObject,org.json.JSONArray" %>
<%@ include file="/init.jsp" %><%

// -------------------------------------------------------------------
// 목적: 교수 채용 추천 저장/목록 API
// 왜 필요한가:
// - 교수(관리자)가 학생에게 공고를 추천하면, 학생 탭에서 목록을 바로 볼 수 있어야 합니다.
// - “학생 기준 1회” 저장이 요구사항이라, 중복은 update로 흡수합니다.
// -------------------------------------------------------------------

Json j = new Json(out);
JobRecommendDao jobRecommend = new JobRecommendDao();
CourseTutorDao courseTutor = new CourseTutorDao();
CourseUserDao courseUser = new CourseUserDao();
CourseDao course = new CourseDao();
UserDao user = new UserDao();

try {
	// 공통: 로그인 필요
	if(userId <= 0) {
		j.print(-401, "로그인이 필요합니다.");
		return;
	}

	String mode = m.rs("mode").trim();
	String now = sysNow;

	// 입력값(공통)
	String provider = m.rs("provider").trim().toUpperCase();
	String wantedAuthNo = m.rs("wanted_auth_no").trim();

	// 왜: provider/wantedAuthNo는 유일키에 들어가므로, 최소한의 안전성 검사로 이상값을 막습니다.
	if(!"".equals(provider) && !provider.matches("^[A-Z0-9_\\-]{1,20}$")) provider = "";
	if(!"".equals(wantedAuthNo) && !wantedAuthNo.matches("^[A-Za-z0-9_\\-]{1,60}$")) wantedAuthNo = "";

if("add".equals(mode)) {
	// 저장(추천)
	if(!m.isPost()) { j.print(-405, "POST만 허용됩니다."); return; }

	int courseId = m.ri("course_id");
	if(0 >= courseId) { j.print(-1, "course_id가 필요합니다."); return; }
	if("".equals(wantedAuthNo)) { j.print(-1, "wanted_auth_no가 필요합니다."); return; }
	if("".equals(provider)) provider = "WORK24";

	// 권한: 관리자(S/A) 또는 교수자만
	boolean isAdmin = "S".equals(userKind) || "A".equals(userKind);
	DataSet uinfo = user.find("id = " + userId + " AND site_id = " + siteId + " AND status = 1");
	if(!uinfo.next()) { j.print(-404, "사용자 정보가 없습니다."); return; }
	if(!isAdmin && !"Y".equals(uinfo.s("tutor_yn"))) { j.print(-403, "교수 권한이 없습니다."); return; }

	// 교수자는 본인 과목(주강사)만 추천 가능
	if(!isAdmin) {
		int cnt = courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId);
		if(cnt <= 0) { j.print(-403, "해당 과목의 추천 권한이 없습니다."); return; }
	}

	// 학생 목록(콤마 구분)
	String rawStudentIds = m.rs("student_user_ids").trim();
	if("".equals(rawStudentIds)) {
		int singleId = m.ri("student_user_id");
		if(0 < singleId) rawStudentIds = String.valueOf(singleId);
	}
	if("".equals(rawStudentIds)) { j.print(-1, "student_user_ids가 필요합니다."); return; }

	java.util.HashSet<Integer> studentSet = new java.util.HashSet<Integer>();
	for(String token : m.split(",", rawStudentIds)) {
		if(token == null) continue;
		String trimmed = token.trim();
		if("".equals(trimmed)) continue;
		int sid = m.parseInt(trimmed);
		if(0 < sid) studentSet.add(sid);
	}
	if(studentSet.size() <= 0) { j.print(-1, "추천할 학생이 없습니다."); return; }
	if(studentSet.size() > 300) { j.print(-1, "한 번에 추천할 수 있는 학생 수(300명)를 초과했습니다."); return; }

	String wantedInfoUrl = m.rs("wanted_info_url").trim();
	String title = m.rs("title").trim();
	String company = m.rs("company").trim();
	String region = m.rs("region").trim();
	String closeDt = m.rs("close_dt").trim();
	String itemJson = m.rs("item_json").trim();

	// 왜: DB 컬럼 길이를 넘기면 저장이 실패하므로, 여기서 안전하게 잘라줍니다.
	if(wantedInfoUrl.length() > 400) wantedInfoUrl = wantedInfoUrl.substring(0, 400);
	if(title.length() > 300) title = title.substring(0, 300);
	if(company.length() > 200) company = company.substring(0, 200);
	if(region.length() > 200) region = region.substring(0, 200);
	if(closeDt.length() > 20) closeDt = closeDt.substring(0, 20);
	// 왜: mediumtext이지만, 과도하게 큰 값은 저장/응답/성능에 악영향이어서 테스트용 상한을 둡니다.
	if(itemJson.length() > 60000) itemJson = itemJson.substring(0, 60000);

	int saved = 0;
	int skipped = 0;

	for(Integer sid : studentSet) {
		if(sid == null || sid <= 0) { skipped++; continue; }

		// 왜: 과목에 등록된 수강생만 추천 대상으로 허용합니다.
		int enrolled = courseUser.findCount(
			"site_id = " + siteId
			+ " AND course_id = " + courseId
			+ " AND user_id = " + sid
			+ " AND status NOT IN (-1, -4)"
		);
		if(enrolled <= 0) { skipped++; continue; }

		boolean ok = jobRecommend.saveRecommend(
			siteId,
			userId,
			courseId,
			sid,
			provider,
			wantedAuthNo,
			wantedInfoUrl,
			title,
			company,
			region,
			closeDt,
			itemJson,
			now
		);
		if(ok) saved++;
		else skipped++;
	}

	JSONObject payload = new JSONObject();
	payload.put("saved", saved);
	payload.put("skipped", skipped);
	payload.put("total", studentSet.size());
	j.setJson(payload.toString());
	j.print(0, "추천을 저장했습니다.");
	return;

} else if("list".equals(mode)) {
	// 목록(학생 본인)
	int pageNo = m.ri("page"); if(pageNo < 1) pageNo = 1;
	int size = m.ri("size"); if(size < 1) size = 50; if(size > 200) size = 200;
	int offset = (pageNo - 1) * size;

	int total = jobRecommend.getCount(siteId, userId);
	// 왜: 학생은 “누가 추천했는지/어떤 과목인지”를 알아야 하므로, 교수/과목명을 조인해서 내려줍니다.
	DataSet list = jobRecommend.query(
		" SELECT a.id, a.tutor_user_id, a.course_id, a.student_user_id, a.provider, a.wanted_auth_no, a.wanted_info_url "
		+ " , a.title, a.company, a.region, a.close_dt, a.item_json, a.reg_date "
		+ " , tu.user_nm tutor_user_nm, c.course_nm course_nm "
		+ " FROM " + jobRecommend.table + " a "
		+ " LEFT JOIN " + user.table + " tu ON tu.id = a.tutor_user_id AND tu.site_id = " + siteId + " AND tu.status = 1 "
		+ " LEFT JOIN " + course.table + " c ON c.id = a.course_id AND c.site_id = " + siteId + " AND c.status != -1 "
		+ " WHERE a.site_id = ? AND a.student_user_id = ? AND a.status = 1 "
		+ " ORDER BY a.reg_date DESC, a.id DESC "
		+ " LIMIT ?, ? "
		, new Object[] { siteId, userId, offset, size }
	);

	JSONArray items = new JSONArray();
	while(list.next()) {
		JSONObject row = new JSONObject();
		row.put("id", list.i("id"));
		row.put("tutor_user_id", list.i("tutor_user_id"));
		row.put("course_id", list.i("course_id"));
		row.put("student_user_id", list.i("student_user_id"));
		row.put("provider", list.s("provider"));
		row.put("wanted_auth_no", list.s("wanted_auth_no"));
		row.put("wanted_info_url", list.s("wanted_info_url"));
		row.put("title", list.s("title"));
		row.put("company", list.s("company"));
		row.put("region", list.s("region"));
		row.put("close_dt", list.s("close_dt"));
		row.put("item_json", list.s("item_json"));
		row.put("tutor_user_nm", list.s("tutor_user_nm"));
		row.put("course_nm", list.s("course_nm"));
		row.put("reg_date", list.s("reg_date"));
		items.put(row);
	}

	JSONObject payload = new JSONObject();
	payload.put("total", total);
	payload.put("page", pageNo);
	payload.put("size", size);
	payload.put("items", items);

	j.setJson(payload.toString());
	j.print(0, "success");
	return;
} else if("sent".equals(mode)) {
	// 교수 보낸내역
	boolean isAdmin = "S".equals(userKind) || "A".equals(userKind);
	DataSet uinfo = user.find("id = " + userId + " AND site_id = " + siteId + " AND status = 1");
	if(!uinfo.next()) { j.print(-404, "사용자 정보가 없습니다."); return; }
	if(!isAdmin && !"Y".equals(uinfo.s("tutor_yn"))) { j.print(-403, "교수 권한이 없습니다."); return; }

	int pageNo = m.ri("page"); if(pageNo < 1) pageNo = 1;
	int size = m.ri("size"); if(size < 1) size = 50; if(size > 200) size = 200;
	int offset = (pageNo - 1) * size;
	int courseId = m.ri("course_id");
	String keyword = m.rs("student_keyword").trim();

	ArrayList<Object> params = new ArrayList<Object>();
	String where = " a.site_id = ? AND a.tutor_user_id = ? AND a.status = 1 ";
	params.add(siteId);
	params.add(userId);

	if(0 < courseId) {
		where += " AND a.course_id = ? ";
		params.add(courseId);
	}

	if(!"".equals(keyword)) {
		// 왜: 교수는 학생 이름/아이디로 쉽게 찾고 싶어 합니다.
		where += " AND (su.user_nm LIKE ? OR su.login_id LIKE ?) ";
		params.add("%" + keyword + "%");
		params.add("%" + keyword + "%");
	}

	DataSet cnt = jobRecommend.query(
		" SELECT COUNT(*) cnt "
		+ " FROM " + jobRecommend.table + " a "
		+ " LEFT JOIN " + user.table + " su ON su.id = a.student_user_id AND su.site_id = " + siteId + " AND su.status = 1 "
		+ " WHERE " + where
		, params.toArray()
	);
	int total = 0;
	if(cnt.next()) total = cnt.i("cnt");

	ArrayList<Object> listParams = new ArrayList<Object>(params);
	listParams.add(offset);
	listParams.add(size);
	DataSet list = jobRecommend.query(
		" SELECT a.id, a.tutor_user_id, a.course_id, a.student_user_id, a.provider, a.wanted_auth_no, a.wanted_info_url "
		+ " , a.title, a.company, a.region, a.close_dt, a.item_json, a.reg_date "
		+ " , su.user_nm student_user_nm, su.login_id student_login_id, c.course_nm course_nm "
		+ " FROM " + jobRecommend.table + " a "
		+ " LEFT JOIN " + user.table + " su ON su.id = a.student_user_id AND su.site_id = " + siteId + " AND su.status = 1 "
		+ " LEFT JOIN " + course.table + " c ON c.id = a.course_id AND c.site_id = " + siteId + " AND c.status != -1 "
		+ " WHERE " + where
		+ " ORDER BY a.reg_date DESC, a.id DESC "
		+ " LIMIT ?, ? "
		, listParams.toArray()
	);

	JSONArray items = new JSONArray();
	while(list.next()) {
		JSONObject row = new JSONObject();
		row.put("id", list.i("id"));
		row.put("tutor_user_id", list.i("tutor_user_id"));
		row.put("course_id", list.i("course_id"));
		row.put("student_user_id", list.i("student_user_id"));
		row.put("provider", list.s("provider"));
		row.put("wanted_auth_no", list.s("wanted_auth_no"));
		row.put("wanted_info_url", list.s("wanted_info_url"));
		row.put("title", list.s("title"));
		row.put("company", list.s("company"));
		row.put("region", list.s("region"));
		row.put("close_dt", list.s("close_dt"));
		row.put("item_json", list.s("item_json"));
		row.put("student_user_nm", list.s("student_user_nm"));
		row.put("student_login_id", list.s("student_login_id"));
		row.put("course_nm", list.s("course_nm"));
		row.put("reg_date", list.s("reg_date"));
		items.put(row);
	}

	JSONObject payload = new JSONObject();
	payload.put("total", total);
	payload.put("page", pageNo);
	payload.put("size", size);
	payload.put("items", items);

	j.setJson(payload.toString());
	j.print(0, "success");
	return;
}

j.print(-1, "mode가 올바르지 않습니다. (add/list)");

} catch(Throwable e) {
	// 왜: JSP 예외가 그대로 노출되면 화면/콘솔에서 원인 파악이 어렵고, 500으로만 보입니다.
	Exception ex = (e instanceof Exception) ? (Exception)e : new Exception(e);
	Malgn.errorLog("{api.job_recommend} error", ex);
	j.print(-1, "추천 처리 중 오류가 발생했습니다. " + (e.getMessage() == null ? "" : e.getMessage()));
}

%>
