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
if(!"".equals(haksaCuid)) {
	String[] parts = haksaCuid.split("_");
	if(parts.length >= 4) {
		boolean debugHaksa = "Y".equalsIgnoreCase(m.rs("debug"));

		// 왜: 마이페이지(수강현황)에서는 TB_USER.login_id를 기준으로 학사 member_key를 매핑합니다.
		//     그런데 세션(Auth)에 저장된 loginId 값이 TB_USER.login_id와 다르게 들어오는 케이스가 있어(SSO/관리자 로그인 등),
		//     강의실 진입에서는 둘 다 시도해야 "목록은 보이는데 입장은 안 되는" 문제가 생기지 않습니다.
		String dbLoginId = loginId;
		try {
			// 왜: getOne() 내부에서 LIMIT이 붙을 수 있어, 단순 find로 조회한 뒤 꺼내야 SQL 오류가 나지 않습니다.
			DataSet loginInfo = user.find("id = " + userId);
			if(loginInfo.next() && !"".equals(loginInfo.s("login_id"))) dbLoginId = loginInfo.s("login_id");
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

				// 왜: 학사 과목에서도 과제/시험/자료/공지/Q&A가 동작하려면 LMS 과정/수강자 매핑이 필요합니다.
				//     다만 LM_COURSE.course_cd 는 길이가 짧아(예: 20) 학사 5종키를 그대로 넣으면 잘리거나 중복될 수 있습니다.
				//     그래서 "전체키는 etc1에 저장"하고, "course_cd에는 해시(고정 길이)"를 저장해 안정적으로 재매핑합니다.
				String haksaCourseKey = haksaInfo.s("course_code") + "_" + haksaInfo.s("open_year") + "_" + haksaInfo.s("open_term")
					+ "_" + haksaInfo.s("bunban_code") + "_" + haksaInfo.s("group_code");
				// 왜: 메뉴 이동 시에도 학사 키가 계속 유지되어야 주차 UI/커리큘럼 조회가 끊기지 않습니다.
				//     (마이페이지 등에서 4종 키만 넘어오는 경우가 있어도, 여기서 5종 전체키로 보정합니다.)
				haksaCuid = haksaCourseKey;
				String haksaCourseCd = m.md5(haksaCourseKey);
				if(haksaCourseCd != null && haksaCourseCd.length() > 20) haksaCourseCd = haksaCourseCd.substring(0, 20);
				if(haksaCourseCd == null) haksaCourseCd = "";

				String safeHaksaCourseKey = m.replace(haksaCourseKey, "'", "''");
				String safeHaksaCourseCd = m.replace(haksaCourseCd, "'", "''");

				int mappedCourseId = 0;
				// 왜: 이미 운영 중인 DB에는 과거 버전(전체키를 course_cd에 저장) 데이터가 있을 수 있어,
				//     해시(course_cd)/전체키(course_cd)/전체키(etc1) 3가지를 모두 조회해 호환성을 확보합니다.
				DataSet mappedCourse = course.find(
					"site_id = " + siteId
					+ " AND (course_cd = '" + safeHaksaCourseCd + "' OR course_cd = '" + safeHaksaCourseKey + "' OR etc1 = '" + safeHaksaCourseKey + "')"
					+ " AND status != -1"
				);
				if(mappedCourse.next()) {
					mappedCourseId = mappedCourse.i("id");
					try {
						// 왜: 수강현황(비정규/LMS) 목록에서 학사 매핑 과정이 같이 뜨면 사용자 입장에서는 "과정이 2개 생긴 것"처럼 보입니다.
						//     그래서 과정 생성/조회 시 etc2에 표식을 남겨, 목록에서 제외할 수 있게 합니다.
						boolean needCourseUpdate = false;
						course.clear();
						if(!haksaCourseKey.equals(mappedCourse.s("etc1"))) { course.item("etc1", haksaCourseKey); needCourseUpdate = true; }
						if(!"HAKSA_MAPPED".equals(mappedCourse.s("etc2"))) { course.item("etc2", "HAKSA_MAPPED"); needCourseUpdate = true; }
						if(needCourseUpdate) course.update("id = " + mappedCourseId);
					} catch(Exception ignore) {}
				}
				if(mappedCourseId == 0) {
					int newCourseId = course.getSequence();
					course.item("id", newCourseId);
					course.item("site_id", siteId);
					course.item("course_cd", haksaCourseCd);
					course.item("etc1", haksaCourseKey);
					// 왜: 학사 연동용으로 자동 생성된 "숨김 LMS 과정"임을 표시합니다. (수강현황 화면 중복 노출 방지용)
					course.item("etc2", "HAKSA_MAPPED");
					course.item("year", haksaInfo.s("open_year"));

					int stepVal = m.parseInt(haksaInfo.s("open_term"));
					if(stepVal <= 0) stepVal = 1;
					course.item("step", stepVal);
					course.item("course_nm", haksaInfo.s("course_name"));
					course.item("course_type", "R");
					course.item("onoff_type", "N");
					// 왜: 일부 DB에서는 LESSON_DAY/LESSON_TIME 이 NOT NULL + 기본값 없음으로 설정되어 있어,
					//     값을 지정하지 않으면 INSERT가 실패합니다(현상: "Field 'LESSON_DAY' doesn't have a default value").
					course.item("lesson_day", 0);
					course.item("lesson_time", 0);
					// 왜: 일부 DB는 LIST_PRICE/PRICE/CREDIT 등이 NOT NULL + 기본값 없음으로 설정되어 있어,
					//     기본값을 명시하지 않으면 학사 과정 자동 생성이 실패합니다.
					course.item("list_price", 0);
					course.item("price", 0);
					course.item("credit", 0);
					// 왜: RENEW_PRICE도 NOT NULL + 기본값 없음인 환경이 있어,
					//     값이 비면 INSERT가 실패합니다.
					course.item("renew_price", 0);
					// 왜: 일부 DB는 ASSIGN_*/LIMIT_* 계열도 NOT NULL + 기본값 없음이라,
					//     기본값을 명시하지 않으면 INSERT가 연쇄로 실패합니다.
					course.item("assign_progress", 100);
					course.item("assign_exam", 0);
					course.item("assign_homework", 0);
					course.item("assign_forum", 0);
					course.item("assign_etc", 0);
					course.item("limit_progress", 60);
					course.item("limit_exam", 0);
					course.item("limit_homework", 0);
					course.item("limit_forum", 0);
					course.item("limit_etc", 0);
					course.item("complete_limit_progress", 60);
					course.item("complete_limit_total_score", 0);
					course.item("study_sdate", startDate);
					course.item("study_edate", endDate);
					course.item("request_sdate", startDate);
					course.item("request_edate", endDate);
					course.item("display_yn", "N");
					course.item("sale_yn", "N");
					course.item("manager_id", 0);
					course.item("exam_yn", "Y");
					course.item("homework_yn", "Y");
					course.item("forum_yn", "N");
					course.item("survey_yn", "N");
					course.item("review_yn", "Y");
					course.item("reg_date", m.time("yyyyMMddHHmmss"));
					course.item("status", 1);
					if(course.insert()) mappedCourseId = newCourseId;
				}

				int mappedCuid = 0;
				if(mappedCourseId > 0) {
					DataSet mappedCu = courseUser.find("course_id = " + mappedCourseId + " AND user_id = " + userId + " AND status IN (1,3)");
					if(mappedCu.next()) mappedCuid = mappedCu.i("id");
					if(mappedCuid == 0) {
						int newCuid = courseUser.getSequence();
						courseUser.item("id", newCuid);
						courseUser.item("site_id", siteId);
						// 왜: 일부 DB는 LM_COURSE_USER의 PACKAGE_ID/RENEW_CNT/점수필드 등이 NOT NULL + 기본값 없음(STRICT)이라
						//     최소값을 명시하지 않으면 수강생 자동 등록이 계속 실패합니다.
						//     (비정규는 기존 등록 플로우에서 이미 세팅되지만, 학사 자동 매핑은 우리가 직접 insert 하므로 보정이 필요합니다.)
						courseUser.item("package_id", 0);
						courseUser.item("course_id", mappedCourseId);
						courseUser.item("user_id", userId);
						courseUser.item("order_id", 0);
						courseUser.item("order_item_id", 0);
						courseUser.item("grade", 1);
						courseUser.item("renew_cnt", 0);
						courseUser.item("start_date", startDate);
						courseUser.item("end_date", endDate);
						courseUser.item("progress_ratio", 0);
						courseUser.item("progress_score", 0);
						courseUser.item("exam_value", 0);
						courseUser.item("exam_score", 0);
						courseUser.item("homework_value", 0);
						courseUser.item("homework_score", 0);
						courseUser.item("forum_value", 0);
						courseUser.item("forum_score", 0);
						courseUser.item("etc_value", 0);
						courseUser.item("etc_score", 0);
						courseUser.item("total_score", 0);
						courseUser.item("credit", 0);
						courseUser.item("complete_status", "");
						courseUser.item("complete_yn", "");
						courseUser.item("complete_no", "");
						courseUser.item("complete_date", "");
						courseUser.item("close_yn", "N");
						courseUser.item("close_date", "");
						courseUser.item("close_user_id", 0);
						courseUser.item("change_date", "");
						courseUser.item("mod_date", "");
						courseUser.item("reg_date", m.time("yyyyMMddHHmmss"));
						courseUser.item("status", 1);
						if(courseUser.insert()) mappedCuid = newCuid;
					}
				}

				if(mappedCourseId > 0 && mappedCuid > 0) {
					cuinfo.put("course_id", mappedCourseId);
					cuinfo.put("id", mappedCuid);
					cuid = mappedCuid;
				}
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
} else if(cuid > 0) {
	cuinfo = courseUser.query(
		"SELECT a.*, c.course_nm, c.course_type, c.onoff_type, c.sms_yn, c.limit_seek_yn, t.user_nm tutor_name, c.subject_id, c.renew_max_cnt, c.renew_yn, u.id user_id, u.user_nm, u.mobile "
		+ " FROM " + courseUser.table + " a "
		+ " INNER JOIN " + course.table + " c ON a.course_id = c.id AND c.site_id = " + siteId + " "
		+ " INNER JOIN " + user.table + " u ON a.user_id = u.id"
		+ " LEFT JOIN " + user.table + " t ON a.tutor_id = t.id"
		+ " WHERE a.id = " + cuid + " AND a.user_id = '" + userId + "' AND a.status IN (1,3)"
	);
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
	if(cinfo.next()) {
		// 왜: 학사 강의실은 메뉴 이동/새로고침/북마크 등으로 `haksa_cuid` 파라미터가 빠져도,
		//     계속 "학사 주차 UI"로 보여야 사용자가 길을 잃지 않습니다.
		//     학사 연동용으로 자동 생성한 숨김 LMS 과정은 etc2='HAKSA_MAPPED'로 표식해두었으므로,
		//     이 표식을 기준으로 학사 키를 복구하고 학사 분기를 유지합니다.
		if(!cuinfo.b("is_haksa") && "HAKSA_MAPPED".equals(cinfo.s("etc2"))) {
			cuinfo.put("is_haksa", true);

			if("".equals(haksaCuid)) haksaCuid = cinfo.s("etc1");

			if(!"".equals(haksaCuid)) {
				String[] hk = haksaCuid.split("_");
				if(hk.length >= 5) {
					if("".equals(cuinfo.s("haksa_course_code"))) cuinfo.put("haksa_course_code", hk[0]);
					if("".equals(cuinfo.s("haksa_open_year"))) cuinfo.put("haksa_open_year", hk[1]);
					if("".equals(cuinfo.s("haksa_open_term"))) cuinfo.put("haksa_open_term", hk[2]);
					if("".equals(cuinfo.s("haksa_bunban_code"))) cuinfo.put("haksa_bunban_code", hk[3]);
					if("".equals(cuinfo.s("haksa_group_code"))) cuinfo.put("haksa_group_code", hk[4]);
				}
			}

			// 왜: 주차 수는 학사 과목별로 다를 수 있어, 가능하면 학사 테이블 값으로 보정합니다.
			if("".equals(cuinfo.s("haksa_week")) && !"".equals(cuinfo.s("haksa_course_code")) && !"".equals(cuinfo.s("haksa_open_year")) && !"".equals(cuinfo.s("haksa_open_term")) && !"".equals(cuinfo.s("haksa_bunban_code")) && !"".equals(cuinfo.s("haksa_group_code"))) {
				try {
					String safeHkCourseCode = m.replace(cuinfo.s("haksa_course_code"), "'", "''");
					String safeHkOpenYear = m.replace(cuinfo.s("haksa_open_year"), "'", "''");
					String safeHkOpenTerm = m.replace(cuinfo.s("haksa_open_term"), "'", "''");
					String safeHkBunbanCode = m.replace(cuinfo.s("haksa_bunban_code"), "'", "''");
					String safeHkGroupCode = m.replace(cuinfo.s("haksa_group_code"), "'", "''");
					DataSet wkInfo = polyCourse.query(
						"SELECT week FROM " + polyCourse.table
						+ " WHERE course_code = '" + safeHkCourseCode + "' AND open_year = '" + safeHkOpenYear + "' AND open_term = '" + safeHkOpenTerm + "'"
						+ " AND bunban_code = '" + safeHkBunbanCode + "' AND group_code = '" + safeHkGroupCode + "' LIMIT 1"
					);
					if(wkInfo.next() && !"".equals(wkInfo.s("week"))) cuinfo.put("haksa_week", wkInfo.s("week"));
				} catch(Exception ignore) {}
			}
		}
	}
}

// 왜: 학사 과정인데 cinfo가 아직 비어있다면(매핑 전이거나 조회 실패), 화면 구성을 위해 기본 정보를 강제로 채웁니다.
if(cuinfo.b("is_haksa") && cinfo.size() == 0) {
	cinfo.addRow();
	cinfo.put("id", 0);
	cinfo.put("course_nm", cuinfo.s("course_nm"));
	cinfo.put("year", cuinfo.s("haksa_open_year"));
	cinfo.put("step", cuinfo.s("haksa_open_term"));
	cinfo.put("course_type", "R");
	cinfo.put("onoff_type", "N");
	cinfo.put("period_yn", false);
	cinfo.put("lesson_order_yn", false);
	cinfo.put("restudy_yn", false);
	cinfo.put("limit_lesson_yn", false);
	cinfo.put("limit_ratio_yn", false);
	cinfo.put("exam_yn", "Y");
	cinfo.put("homework_yn", "Y");
	cinfo.put("review_yn", "Y");
	cinfo.put("forum_yn", "N");
	cinfo.put("survey_yn", "N");
}

if(cinfo.size() > 0) cinfo.first();

if("".equals(cinfo.s("course_nm")) && 0 == cinfo.size()) { m.jsError(_message.get("alert.course.nodata")); return; }

// 왜: 학사 과정은 메뉴 사용 여부를 LMS 기본값과 다르게 강제로 맞춰야 합니다.
if(cuinfo.b("is_haksa")) {
	cinfo.put("exam_yn", "Y");
	cinfo.put("homework_yn", "Y");
	cinfo.put("review_yn", "Y");
	cinfo.put("forum_yn", "N");
	cinfo.put("survey_yn", "N");
}

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

// 왜: 학사/비정규 모두 같은 템플릿을 쓰므로, 메뉴 링크용 쿼리를 공통으로 내려줍니다.
// 왜: 학사 강의실은 "학사 주차 UI"가 계속 유지되어야 하므로(haksa_cuid 필요),
//     cuid(권한/다운로드용) + haksa_cuid(학사 UI/연동용)를 같이 넘겨줍니다.
String courseQs = "";
if(cuinfo.b("is_haksa")) {
	if(cuid > 0 && !"".equals(haksaCuid)) courseQs = "cuid=" + cuid + "&haksa_cuid=" + haksaCuid;
	else if(cuid > 0) courseQs = "cuid=" + cuid;
	else courseQs = "haksa_cuid=" + haksaCuid;
} else {
	courseQs = "cuid=" + cuid;
}

p.setVar("cuinfo", cuinfo);
p.setVar("course", cinfo);
p.setVar("cuid", cuid);
p.setVar("haksa_cuid", haksaCuid);
p.setVar("course_qs", courseQs);

%>
