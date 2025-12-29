<%@ include file="../init.jsp"%><%

//로그인
if(1 > userId) { auth.loginForm(); return; }

//기본키
int cuid = m.ri("cuid");
String haksaCuid = m.rs("haksa_cuid");

if(cuid == 0 && "".equals(haksaCuid)) { m.jsError(_message.get("alert.common.required_key")); return; }

//객체
UserDao user = new UserDao();
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
CourseModuleDao courseModule = new CourseModuleDao();

CourseUserDao cu = new CourseUserDao();
CourseModuleDao cm = new CourseModuleDao();

PolyStudentDao polyStudent = new PolyStudentDao();
PolyCourseDao polyCourse = new PolyCourseDao();
PolyMemberKeyDao polyMemberKey = new PolyMemberKeyDao();

//변수
String today = m.time("yyyyMMdd");
String now = m.time("yyyyMMddHHmmss");

//정보
DataSet cuinfo = new DataSet();
if(cuid > 0) {
	cuinfo = courseUser.query(
		"SELECT a.*, c.course_nm, c.course_type, c.onoff_type, c.sms_yn, c.limit_seek_yn, t.user_nm tutor_name, c.subject_id, c.renew_max_cnt, c.renew_yn, u.id user_id, u.user_nm, u.mobile "
		+ " FROM " + courseUser.table + " a "
		+ " INNER JOIN " + course.table + " c ON a.course_id = c.id AND c.site_id = " + siteId + " "
		+ " INNER JOIN " + user.table + " u ON a.user_id = u.id"
		+ " LEFT JOIN " + user.table + " t ON a.tutor_id = t.id"
		+ " WHERE a.id = " + cuid + " AND a.user_id = '" + userId + "' AND a.status IN (1,3)"
	);
} else if(!"".equals(haksaCuid)) {
	String[] parts = haksaCuid.split("_");
	if(parts.length >= 4) {
		boolean debugHaksa = "Y".equalsIgnoreCase(m.rs("debug"));

		// 왜: 마이페이지(수강현황)에서는 TB_USER.login_id를 기준으로 학사 member_key를 매핑합니다.
		//     그런데 세션(Auth)에 저장된 loginId 값이 TB_USER.login_id와 다르게 들어오는 케이스가 있어(SSO/관리자 로그인 등),
		//     강의실 진입에서는 둘 다 시도해야 "목록은 보이는데 입장은 안 되는" 문제가 생기지 않습니다.
		String dbLoginId = loginId;
		try {
			// 왜: DataObject.getOne()은 내부에서 DB별로 LIMIT 처리를 추가할 수 있어,
			//     여기서 LIMIT을 직접 붙이면 "LIMIT 1 LIMIT 1" 같은 문법 오류가 날 수 있습니다.
			String fetched = user.getOne("SELECT login_id FROM " + user.table + " WHERE id = " + userId);
			if(!"".equals(fetched)) dbLoginId = fetched;
		} catch(Exception ignore) {}

		String safeCourseCode = m.replace(parts[0], "'", "''");
		String safeOpenYear = m.replace(parts[1], "'", "''");
		String safeOpenTerm = m.replace(parts[2], "'", "''");
		String safeBunbanCode = m.replace(parts[3], "'", "''");
		String safeGroupCode = parts.length >= 5 ? m.replace(parts[4], "'", "''") : "";
		String safeLoginId = m.replace(loginId, "'", "''");
		String safeDbLoginId = m.replace(dbLoginId, "'", "''");

		String groupWhere = "";
		if(!"".equals(safeGroupCode)) groupWhere = " AND s.group_code = '" + safeGroupCode + "' ";

		// 왜: 마이페이지와 동일하게 "login_id → member_key"를 먼저 자바 코드에서 확정한 뒤 조회해야,
		//     DB별 서브쿼리/캐시 영향 없이 안정적으로 동일한 결과를 얻을 수 있습니다.
		String resolvedMemberKey = "";
		try {
			DataSet mk = polyMemberKey.query(
				"SELECT member_key FROM " + polyMemberKey.table
				+ " WHERE alias_key = '" + safeDbLoginId + "' OR member_key = '" + safeDbLoginId + "'"
				+ " OR alias_key = '" + safeLoginId + "' OR member_key = '" + safeLoginId + "'"
				+ " LIMIT 1"
			);
			if(mk.next()) resolvedMemberKey = mk.s("member_key");
		} catch(Exception ignore) {}
		if("".equals(resolvedMemberKey)) resolvedMemberKey = dbLoginId;
		String safeResolvedMemberKey = m.replace(resolvedMemberKey, "'", "''");

		String baseHaksaSql =
			// 왜: 학습기간/상태 계산에 startdate/enddate가 필요하고, 주차/표시를 위해 week도 같이 가져옵니다.
			" SELECT s.*, c.course_name, c.course_ename, c.startdate startdate, c.enddate enddate, c.week "
			+ " FROM " + polyStudent.table + " s "
			+ " INNER JOIN " + polyCourse.table + " c ON s.course_code = c.course_code "
			+ "   AND s.open_year = c.open_year AND s.open_term = c.open_term "
			+ "   AND s.bunban_code = c.bunban_code AND s.group_code = c.group_code "
			+ " WHERE s.course_code = '" + safeCourseCode + "' AND s.open_year = '" + safeOpenYear + "' AND s.open_term = '" + safeOpenTerm + "' AND s.bunban_code = '" + safeBunbanCode + "' "
			+ groupWhere;

		DataSet haksaInfo = polyStudent.query(baseHaksaSql + " AND s.member_key = '" + safeResolvedMemberKey + "' ");
		boolean foundHaksa = haksaInfo.next();
		if(!foundHaksa) {
			// 왜: 매핑 데이터가 꼬였거나(테스트/이관) login_id 자체가 member_key인 환경도 있어 추가로 시도합니다.
			haksaInfo = polyStudent.query(baseHaksaSql + " AND s.member_key = '" + safeDbLoginId + "' ");
			foundHaksa = haksaInfo.next();
			if(!foundHaksa && !safeLoginId.equals(safeDbLoginId)) {
				haksaInfo = polyStudent.query(baseHaksaSql + " AND s.member_key = '" + safeLoginId + "' ");
				foundHaksa = haksaInfo.next();
			}
		}
			if(foundHaksa) {
				cuinfo.addRow();
				cuinfo.put("id", 0);
				cuinfo.put("course_id", 0);
				cuinfo.put("user_id", userId);
				cuinfo.put("course_nm", haksaInfo.s("course_name"));
			cuinfo.put("course_type", "R");
			cuinfo.put("onoff_type", "N");
			cuinfo.put("status", 1);
			cuinfo.put("progress", "I");

			// 왜: 테스트/동기화 초기에는 학사 과목의 STARTDATE/ENDDATE가 비어 있을 수 있습니다.
			//     그런데 아래 로직에서 m.diffDate()가 날짜가 비면 예외를 던져 강의실이 500으로 깨집니다.
			//     그래서 최소한의 기본값을 넣어 "강의실 진입 자체"가 막히지 않게 합니다.
			String startDate = haksaInfo.s("startdate");
			String endDate = haksaInfo.s("enddate");
			// 왜: 외부/미러 데이터는 날짜 포맷이 섞일 수 있어(예: 2025-12-01), 숫자만 남겨 yyyyMMdd로 맞춥니다.
			if(startDate != null) startDate = startDate.replaceAll("[^0-9]", "");
			if(endDate != null) endDate = endDate.replaceAll("[^0-9]", "");
			if(startDate == null) startDate = "";
			if(endDate == null) endDate = "";

			if(startDate.length() >= 8) startDate = startDate.substring(0, 8);
			if(endDate.length() >= 8) endDate = endDate.substring(0, 8);

			if(startDate.length() != 8) startDate = today;
			if(endDate.length() != 8) endDate = "99991231";

				cuinfo.put("start_date", startDate);
				cuinfo.put("end_date", endDate);
				cuinfo.put("is_haksa", true);
				// 왜: 학생 강의실에서 학사 커리큘럼 JSON을 조회하려면 5종 키가 필요합니다.
				cuinfo.put("haksa_course_code", haksaInfo.s("course_code"));
				cuinfo.put("haksa_open_year", haksaInfo.s("open_year"));
				cuinfo.put("haksa_open_term", haksaInfo.s("open_term"));
				cuinfo.put("haksa_bunban_code", haksaInfo.s("bunban_code"));
				cuinfo.put("haksa_group_code", haksaInfo.s("group_code"));
				cuinfo.put("haksa_week", haksaInfo.s("week"));
			} else {
			// 왜: 로컬 테스트에서 원인 파악이 어렵기 때문에, debug=Y 일 때는 화면에 진단 정보를 보여줍니다.
			if(debugHaksa) {
				String dbg =
					"학사 강의실 진입용 수강정보를 찾지 못했습니다."
					+ "\\n- haksa_cuid=" + haksaCuid
					+ "\\n- userId=" + userId
					+ "\\n- loginId(세션)=" + loginId
					+ "\\n- loginId(DB)=" + dbLoginId
					+ "\\n- resolvedMemberKey=" + resolvedMemberKey
					+ "\\n- course_key=" + parts[0] + "/" + parts[1] + "/" + parts[2] + "/" + parts[3] + (parts.length >= 5 ? ("/" + parts[4]) : "");
				m.jsError(dbg);
				return;
			}
		}
	}
}

// 왜: 학사 분기에서는 DataSet에 직접 addRow()로 넣기 때문에 커서가 마지막 행에 머물 수 있습니다.
//     아래의 `cuinfo.next()`가 정상 동작하도록 항상 커서를 처음으로 되돌립니다.
cuinfo.first();
if(!cuinfo.next()) { m.jsError(_message.get("alert.course_user.nodata")); return; }

//정보-과정
String courseId = cuinfo.s("course_id");
DataSet cinfo = new DataSet();
if(!"0".equals(courseId)) {
	cinfo = course.find("id = " + courseId + " AND site_id = " + siteId + "");
	if(!cinfo.next()) { m.jsError(_message.get("alert.course.nodata")); return; }
	} else if(cuinfo.b("is_haksa")) {
		cinfo.addRow();
		cinfo.put("id", 0);
		cinfo.put("course_nm", cuinfo.s("course_nm"));
		// 왜: 학사 과목은 course_id가 없어서 화면 표시용 연도/학기 값을 여기서 채웁니다.
		cinfo.put("year", cuinfo.s("haksa_open_year"));
		cinfo.put("step", cuinfo.s("haksa_open_term"));
		cinfo.put("course_type", "R");
	cinfo.put("onoff_type", "N");
	cinfo.put("period_yn", false);
	cinfo.put("lesson_order_yn", false);
	cinfo.put("restudy_yn", false);
	cinfo.put("limit_lesson_yn", false);
	cinfo.put("limit_ratio_yn", false);
	cinfo.first(); // 커서를 첫 번째 행으로 이동
}

if("".equals(cinfo.s("course_nm")) && 0 == cinfo.size()) { m.jsError(_message.get("alert.course.nodata")); return; }

cinfo.put("lesson_time_conv", m.nf((int)cinfo.d("lesson_time")));
cinfo.put("onoff_type_conv", m.getValue(cinfo.s("onoff_type"), course.onoffTypesMsg));
cinfo.put("std_progress", m.nf(cinfo.i("assign_progress") * cinfo.i("limit_progress") / 100, 1));
cinfo.put("std_exam", m.nf(cinfo.i("assign_exam") * cinfo.i("limit_exam") / 100, 1));
cinfo.put("std_homework", m.nf(cinfo.i("assign_homework") * cinfo.i("limit_homework") / 100, 1));
cinfo.put("std_forum", m.nf(cinfo.i("assign_forum") * cinfo.i("limit_forum") / 100, 1));
cinfo.put("std_etc", m.nf(cinfo.i("assign_etc") * cinfo.i("limit_etc") / 100, 1));

boolean alltime = "A".equals(cuinfo.s("course_type"));
cinfo.put("alltime_block", alltime);

//상태 [progress] (W : 대기, E : 종료, I : 수강중, R : 복습중)
cuinfo.put("restudy_edate", cuinfo.s("end_date"));
cuinfo.put("restudy_block", false);
String progress = "I";
if(0 > m.diffDate("D", cuinfo.s("start_date"), today)) progress = "W"; //대기
else if(0 >= m.diffDate("D", cuinfo.s("end_date"), today)) progress = "I"; //수강중
else {
	if(cinfo.b("restudy_yn")) {  //복습
		progress = "R";
		cuinfo.put("restudy_edate", m.addDate("D", cinfo.i("restudy_day"), cuinfo.s("end_date"), "yyyyMMdd"));
		cuinfo.put("restudy_block", true);
	} else progress = "E"; //종료
}
cuinfo.put("restudy_edate_conv", m.time(_message.get("format.date.dot"), cuinfo.s("restudy_edate")));
cuinfo.put("progress", progress);
cuinfo.put("status_conv", m.getValue(progress, courseUser.progressListMsg));
if("Y".equals(cuinfo.s("close_yn"))) cuinfo.put("status_conv", "마감");

cuinfo.put("tutor_name", !"".equals(cuinfo.s("tutor_name")) ? cuinfo.s("tutor_name") : "-");
cuinfo.put("start_date_conv", m.time(_message.get("format.date.dot"), cuinfo.s("start_date")));
cuinfo.put("end_date_conv", m.time(_message.get("format.date.dot"), cuinfo.s("end_date")));
cuinfo.put("past_day", m.diffDate("D", cuinfo.s("start_date"), today));  //경과일

cuinfo.put("total_score_conv", m.nf(cuinfo.d("total_score"), 1));
cuinfo.put("progress_ratio", m.nf(cuinfo.d("progress_ratio"), 1));
cuinfo.put("progress_ratio_conv", m.nf(cuinfo.d("progress_ratio"), 1));
cuinfo.put("exam_value_conv", m.nf(cuinfo.d("exam_value"), 1));
cuinfo.put("homework_value_conv", m.nf(cuinfo.d("homework_value"), 1));
cuinfo.put("forum_value_conv", m.nf(cuinfo.d("forum_value"), 1));
cuinfo.put("etc_value_conv", m.nf(cuinfo.d("etc_value"), 1));

cuinfo.put("progress_score_conv", m.nf(cuinfo.d("progress_score"), 1));
cuinfo.put("exam_score_conv", m.nf(cuinfo.d("exam_score"), 1));
cuinfo.put("homework_score_conv", m.nf(cuinfo.d("homework_score"), 1));
cuinfo.put("forum_score_conv", m.nf(cuinfo.d("forum_score"), 1));
cuinfo.put("etc_score_conv", m.nf(cuinfo.d("etc_score"), 1));


//채널
String ch = "classroom";

p.setVar("cuinfo", cuinfo);
p.setVar("course", cinfo);

%>
