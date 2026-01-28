<%@ page contentType="application/json; charset=utf-8" %>
<%@ page import="dao.*,malgnsoft.db.*,malgnsoft.util.*" %>
<%@ page import="org.json.JSONObject,org.json.JSONArray" %>
<%@ include file="/init.jsp" %><%

// -------------------------------------------------------------------
// 목적: 채용 자연어 검색어 로그 저장 + 교수(담당과목) 기준 검색어 통계 API
// 왜 필요한가:
// - 교수 화면에서 "담당 과목 학생들이 어떤 검색어를 검색했는지(익명)" 통계를 보여주기 위해서입니다.
// - 검색어를 클릭하면 동일 키워드로 공고를 재검색할 수 있도록, 검색어 목록이 필요합니다.
// -------------------------------------------------------------------

Json j = new Json(out);
JobSearchLogDao jobSearchLog = new JobSearchLogDao();
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

	if("log".equals(mode)) {
		// 검색어 로그 저장 (자연어 검색에서 사용)
		if(!m.isPost()) { j.print(-405, "POST만 허용됩니다."); return; }

		String queryText = m.rs("query").trim();
		if("".equals(queryText)) { j.print(-1, "query가 필요합니다."); return; }
		// 왜: 폴백(조용히 자르기) 없이 입력 제한 위반은 오류로 처리해 원인이 드러나게 합니다.
		if(queryText.length() > 200) { j.print(-1, "query는 200자 이하여야 합니다."); return; }

		// 왜: 현재 자연어 검색은 통합(ALL)로 고정이므로 provider도 ALL로 저장합니다.
		String provider = "ALL";

		// 왜: 운영 로그에는 검색어 원문을 남기지 않고(개인정보 가능성), 길이/해시만 남겨 추적 가능하게 합니다.
		String qhash = "";
		try {
			qhash = Malgn.sha256(queryText);
			if(qhash != null && qhash.length() > 12) qhash = qhash.substring(0, 12);
		} catch(Exception e) {
			m.log("job_search_stat", "mode=log sha256 fail siteId=" + siteId + ", userId=" + userId + ", qlen=" + queryText.length() + ", err=" + e.getMessage());
			qhash = "";
		}
		m.log("job_search_stat", "mode=log siteId=" + siteId + ", userId=" + userId + ", qlen=" + queryText.length() + ", qhash=" + qhash);

		if(!jobSearchLog.insertLog(siteId, userId, provider, queryText, now)) {
			m.log("job_search_stat", "mode=log insert fail siteId=" + siteId + ", userId=" + userId + ", qlen=" + queryText.length() + ", qhash=" + qhash);
			j.print(-1, "검색어 로그 저장에 실패했습니다.");
			return;
		}

		j.print(0, "success");
		return;
	}

	// 아래부터는 교수(또는 관리자)만 허용
	boolean isAdmin = "S".equals(userKind) || "A".equals(userKind);
	DataSet uinfo = user.find("id = " + userId + " AND site_id = " + siteId + " AND status = 1");
	if(!uinfo.next()) { j.print(-404, "사용자 정보가 없습니다."); return; }
	if(!isAdmin && !"Y".equals(uinfo.s("tutor_yn"))) { j.print(-403, "교수 권한이 없습니다."); return; }

	if("stats".equals(mode)) {
		// 요구사항 변경(왜): 교수는 "과목을 고르는 것"보다, 본인이 맡은 과목(주/보조강사) 학생들이 뭘 검색했는지 한 번에 보고 싶어합니다.
		// - course_id를 주면(기존 기능) 과목 단위 통계를 유지합니다.
		// - course_id가 없으면(신규) 교수/관리자의 담당 과목(주/보조강사) 전체를 합쳐서 집계합니다.
		int courseId = m.ri("course_id"); // optional

		int days = m.ri("days");
		if(days <= 0) days = 30;
		if(days > 365) days = 365;
		int limit = m.ri("limit");
		if(limit <= 0) limit = 100;
		if(limit > 300) limit = 300;

		// 왜: reg_date는 yyyymmddhhmmss 문자열이므로, 비교용 since도 동일 포맷이어야 합니다.
		// - Malgn.addDate()를 포맷 없이 쓰면 Date.toString() 형태가 되어 비교가 깨질 수 있습니다.
		String since = Malgn.addDate("D", -days, now.substring(0, 8), "yyyyMMdd") + "000000";

		// 통계 대상(수강생) 범위 결정
		int courseCount = 0;
		String courseInSql = "";
		String scope = "";

		// 왜: "로그는 있는데 통계가 0" 같은 상황을 빠르게 진단하려면,
		// - 원본 로그 수(전체/본인)를 먼저 찍어 두면 조인/조건 문제인지 바로 구분됩니다.
		try {
			DataSet raw1 = jobSearchLog.query(
				" SELECT COUNT(*) cnt FROM " + jobSearchLog.table + " WHERE site_id = ? AND status = 1 AND reg_date >= ? "
				, new Object[] { siteId, since }
			);
			int rawTotal = 0;
			if(raw1.next()) rawTotal = raw1.i("cnt");

			DataSet raw2 = jobSearchLog.query(
				" SELECT COUNT(*) cnt FROM " + jobSearchLog.table + " WHERE site_id = ? AND status = 1 AND reg_date >= ? AND user_id = ? "
				, new Object[] { siteId, since, userId }
			);
			int rawMine = 0;
			if(raw2.next()) rawMine = raw2.i("cnt");

			m.log("job_search_stat", "mode=stats rawLogTotal=" + rawTotal + ", rawLogMine=" + rawMine + " siteId=" + siteId + ", userId=" + userId + ", since=" + since);
		} catch(Exception e) {
			m.log("job_search_stat", "mode=stats rawLogCount error siteId=" + siteId + ", userId=" + userId + ", err=" + e.getMessage());
		}

		if(courseId > 0) {
			// 교수자는 본인 과목(주/보조강사)만 조회 가능
			if(!isAdmin) {
				int cnt = courseTutor.findCount("course_id = " + courseId + " AND user_id = " + userId + " AND site_id = " + siteId);
				if(cnt <= 0) { j.print(-403, "해당 과목의 조회 권한이 없습니다."); return; }
			}
			courseCount = 1;
			scope = "course";
		} else {
			// course_id가 없으면: 본인 담당 과목(주/보조강사) 전체 집계
			// 왜: 요구사항은 "내가 맡은 과목들(주/보조강사 모두) 학생들의 검색어 통계"입니다.
			// - 관리자도 동일하게 "본인이 맡은 과목" 기준으로 통계를 봅니다(수강 과정 기준 아님).
			DataSet courseIds = courseTutor.query(
				" SELECT DISTINCT course_id "
				+ " FROM " + courseTutor.table
				+ " WHERE site_id = ? AND user_id = ? "
				, new Object[] { siteId, userId }
			);
			scope = "tutor";

			StringBuilder sb = new StringBuilder();
			while(courseIds.next()) {
				int cid = courseIds.i("course_id");
				if(cid <= 0) continue;
				if(sb.length() > 0) sb.append(",");
				sb.append(cid);
			}

			courseInSql = sb.toString();
			if("".equals(courseInSql)) {
				// 담당 과목이 없으면 통계도 비어있습니다(정상 케이스).
				m.log("job_search_stat", "mode=stats no courses siteId=" + siteId + ", userId=" + userId + ", scope=" + scope + ", isAdmin=" + isAdmin);
				JSONObject payload = new JSONObject();
				payload.put("total", 0);
				payload.put("items", new JSONArray());
				payload.put("days", days);
				payload.put("course_count", 0);
				payload.put("scope", scope);
				j.setJson(payload.toString());
				j.print(0, "success");
				return;
			}

			courseCount = courseInSql.split(",").length;
		}

		// 왜: 통계가 안 나올 때, 과목 범위가 비었는지/잘못 잡혔는지 로그로 바로 확인하기 위해서입니다.
		String courseInLog = courseInSql;
		if(courseInLog != null && courseInLog.length() > 200) courseInLog = courseInLog.substring(0, 200) + "...";
		m.log("job_search_stat", "mode=stats courseInSql=" + (courseInLog == null ? "" : courseInLog));

		m.log("job_search_stat", "mode=stats siteId=" + siteId + ", userId=" + userId + ", courseId=" + courseId + ", courseCount=" + courseCount + ", days=" + days + ", limit=" + limit + ", scope=" + scope + ", isAdmin=" + isAdmin);

		// 왜: 익명 통계이므로 학생 개인정보는 반환하지 않고, 검색어(query_text)와 횟수만 집계합니다.
		// - 수강생 범위: TB_COURSE_USER(또는 courseUser.table)에서 status NOT IN (-1,-4) 조건을 그대로 사용합니다.
		// - 검색어 로그: TB_JOB_SEARCH_LOG(status=1, reg_date>=since)
		DataSet cnt = null;
		if(courseId > 0) {
			Object[] countParams = new Object[] { siteId, courseId, siteId, since };
			cnt = jobSearchLog.query(
				" SELECT COUNT(DISTINCT a.query_text) cnt "
				+ " FROM " + jobSearchLog.table + " a "
				+ " INNER JOIN " + courseUser.table + " cu ON cu.site_id = ? AND cu.course_id = ? AND cu.user_id = a.user_id AND cu.status NOT IN (-1, -4) "
				+ " WHERE a.site_id = ? AND a.status = 1 AND a.reg_date >= ? "
				, countParams
			);
		} else {
			// 왜: 한 학생이 여러 과목을 수강 중이면 JOIN이 중복되어 카운트가 부풀 수 있어 EXISTS로 필터링합니다.
			// 추가 요구(왜): 관리자/교수 계정으로도 자연어 검색을 테스트할 수 있어야 하므로,
			// - 수강생 범위(EXISTS) + 본인(userId) 검색 로그도 같이 집계합니다. (익명 집계이므로 개인정보 노출은 없습니다)
			Object[] countParams = new Object[] { siteId, since, userId, siteId };
			cnt = jobSearchLog.query(
				" SELECT COUNT(DISTINCT a.query_text) cnt "
				+ " FROM " + jobSearchLog.table + " a "
				+ " WHERE a.site_id = ? AND a.status = 1 AND a.reg_date >= ? "
				+ " AND ( a.user_id = ? OR EXISTS ( "
				+ "   SELECT 1 FROM " + courseUser.table + " cu "
				+ "   WHERE cu.site_id = ? AND cu.user_id = a.user_id AND cu.course_id IN (" + courseInSql + ") AND cu.status NOT IN (-1, -4) "
				+ " )) "
				, countParams
			);
		}
		int total = 0;
		if(cnt.next()) total = cnt.i("cnt");
		m.log("job_search_stat", "mode=stats total_keywords=" + total + " siteId=" + siteId + ", userId=" + userId + ", courseId=" + courseId);

		DataSet list = null;
		if(courseId > 0) {
			ArrayList<Object> listParams = new ArrayList<Object>();
			listParams.add(siteId);
			listParams.add(courseId);
			listParams.add(siteId);
			listParams.add(since);
			listParams.add(limit);

			list = jobSearchLog.query(
				" SELECT a.query_text, COUNT(*) cnt, MAX(a.reg_date) last_date "
				+ " FROM " + jobSearchLog.table + " a "
				+ " INNER JOIN " + courseUser.table + " cu ON cu.site_id = ? AND cu.course_id = ? AND cu.user_id = a.user_id AND cu.status NOT IN (-1, -4) "
				+ " WHERE a.site_id = ? AND a.status = 1 AND a.reg_date >= ? "
				+ " GROUP BY a.query_text "
				+ " ORDER BY cnt DESC, last_date DESC "
				+ " LIMIT ? "
				, listParams.toArray()
			);
		} else {
			Object[] listParams = new Object[] { siteId, since, userId, siteId, limit };
			list = jobSearchLog.query(
				" SELECT a.query_text, COUNT(*) cnt, MAX(a.reg_date) last_date "
				+ " FROM " + jobSearchLog.table + " a "
				+ " WHERE a.site_id = ? AND a.status = 1 AND a.reg_date >= ? "
				+ " AND ( a.user_id = ? OR EXISTS ( "
				+ "   SELECT 1 FROM " + courseUser.table + " cu "
				+ "   WHERE cu.site_id = ? AND cu.user_id = a.user_id AND cu.course_id IN (" + courseInSql + ") AND cu.status NOT IN (-1, -4) "
				+ " )) "
				+ " GROUP BY a.query_text "
				+ " ORDER BY cnt DESC, last_date DESC "
				+ " LIMIT ? "
				, listParams
			);
		}

		JSONArray items = new JSONArray();
		while(list.next()) {
			JSONObject row = new JSONObject();
			row.put("query", list.s("query_text"));
			row.put("cnt", list.i("cnt"));
			row.put("last_date", list.s("last_date"));
			items.put(row);
		}

		JSONObject payload = new JSONObject();
		payload.put("total", total);
		payload.put("items", items);
		payload.put("days", days);
		payload.put("course_id", courseId);
		payload.put("course_count", courseCount);
		payload.put("scope", scope);

		// 과목명(표시용)
		if(courseId > 0) {
			DataSet cinfo = course.find("id = " + courseId + " AND site_id = " + siteId + " AND status != -1");
			if(cinfo.next()) payload.put("course_nm", cinfo.s("course_nm"));
		}

		j.setJson(payload.toString());
		j.print(0, "success");
		return;
	}

	j.print(-1, "mode가 올바르지 않습니다. (log/stats)");

} catch(Throwable e) {
	Exception ex = (e instanceof Exception) ? (Exception)e : new Exception(e);
	Malgn.errorLog("{api.job_search_stat} error", ex);
	j.print(-1, "검색어 통계 처리 중 오류가 발생했습니다. " + (e.getMessage() == null ? "" : e.getMessage()));
}

%>
