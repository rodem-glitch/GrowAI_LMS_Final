<%@ page contentType="application/json; charset=utf-8" %><%@ include file="init.jsp" %><%!

//왜 필요한가:
//- 학사(View) 데이터는 외부(e-poly)에서 내려오며, API는 cnt 제한 때문에 “앞부분만” 받으면 수강생/회원 조인이 깨질 수 있습니다.
//- 그래서 하루 1~2회 이 JSP를 호출해 우리 DB에 미리 저장(미러링)해두고, 화면은 로컬 DB만 조회하도록 만듭니다.

public String unwrapPre(String raw) {
	if(raw == null) return "";
	int preStart = raw.indexOf("<pre");
	if(preStart < 0) return raw;
	int gt = raw.indexOf(">", preStart);
	if(gt < 0) return raw;
	int preEnd = raw.indexOf("</pre>", gt);
	if(preEnd < 0) return raw;
	return raw.substring(gt + 1, preEnd);
}

public malgnsoft.db.DataSet parsePolyResponse(String raw) {
	malgnsoft.db.DataSet rs = new malgnsoft.db.DataSet();
	if(raw == null) return rs;

	String body = unwrapPre(raw);
	if(body == null) body = "";
	String trimmed = body.trim();
	if("".equals(trimmed)) return rs;

	// 1) JSON(유사 JSON) 형식이면 우선 Json.decode 시도
	if(trimmed.startsWith("[") || trimmed.startsWith("{")) {
		try { rs = malgnsoft.util.Json.decode(trimmed); return rs; }
		catch(Exception ignore) { /* fallthrough */ }
	}

	// 2) 텍스트(key: value) 형식 파싱
	String[] lines = body.split("\n");
	java.util.Map<String, String> currentRow = new java.util.HashMap<String, String>();
	for(String line : lines) {
		if(line == null) continue;
		String l = line.trim();
		if(l.startsWith("--")) continue;
		if(!l.contains(":")) continue;

		int sep = l.indexOf(":");
		String key = l.substring(0, sep).trim();
		String val = l.substring(sep + 1).trim().replaceAll(",\\s*$", "");

		if("".equals(key)) continue;
		if(currentRow.containsKey(key)) {
			rs.addRow(currentRow);
			currentRow = new java.util.HashMap<String, String>();
		}
		currentRow.put(key, val);
	}
	if(!currentRow.isEmpty()) rs.addRow(currentRow);
	return rs;
}

public String pick(malgnsoft.db.DataSet ds, String keyLower) {
	if(ds == null || keyLower == null) return "";
	String v = ds.s(keyLower);
	if(!"".equals(v)) return v;
	return ds.s(keyLower.toUpperCase());
}

public int toInt(String raw) {
	if(raw == null) return 0;
	try { return Integer.parseInt(raw.trim()); }
	catch(Exception ignore) { return 0; }
}

public int maxOpenYearFromRaw(String raw) {
	if(raw == null) return 0;
	String body = unwrapPre(raw);
	if(body == null) body = "";

	//왜: 외부 응답은 완전한 JSON이 아닐 수 있어, 문자열에서 open_year 값만 빠르게 최대값을 찾습니다.
	java.util.regex.Pattern ptn = java.util.regex.Pattern.compile("open_year\\s*:\\s*(\\d{4})");
	java.util.regex.Matcher mt = ptn.matcher(body);
	int max = 0;
	while(mt.find()) {
		int y = toInt(mt.group(1));
		if(y > max) max = y;
	}
	return max;
}

public String fetchPolyRaw(String endpoint, String tb, int cnt, int retry, int sleepMs) {
	String lastRaw = "";
	int maxTry = Math.max(1, retry);
	for(int i = 0; i < maxTry; i++) {
		try {
			malgnsoft.util.Http http = new malgnsoft.util.Http(endpoint);
			http.setParam("tb", tb);
			http.setParam("cnt", "" + cnt);
			lastRaw = http.send("POST");

			if(parsePolyResponse(lastRaw).size() > 0) return lastRaw;
		} catch(Exception ignore) {}

		if(i + 1 < maxTry && sleepMs > 0) {
			try { Thread.sleep(sleepMs); } catch(Exception ignore) {}
		}
	}
	return lastRaw;
}
%><%

Json result = new Json(out);
result.put("rst_code", "9999");
result.put("rst_message", "올바른 접근이 아닙니다.");

//보안: 서버 로컬(스케줄러)에서만 호출하도록 제한합니다.
//왜: 외부에서 이 URL을 호출하면 DB에 대량 쓰기가 발생할 수 있어 위험합니다.
boolean localOnly = userIp.startsWith("127.") || "0:0:0:0:0:0:0:1".equals(userIp) || "::1".equals(userIp);
if(!localOnly) {
	result.put("rst_code", "4030");
	result.put("rst_message", "로컬에서만 실행할 수 있습니다.");
	result.print();
	return;
}

int memberCnt = m.ri("member_cnt", 100000);
int studentCnt = m.ri("student_cnt", 100000);
int courseCnt = m.ri("course_cnt", 100000);
//왜: 기본은 최대치(100만)까지 받아서 로컬 DB에 저장하는 방식으로 운영합니다.
int requireYear = m.ri("require_year", toInt(m.time("yyyy")));
String syncMode = m.rs("mode");
boolean studentOnly = "student_only".equals(syncMode);

String syncKey = "poly_mirror";
String syncDate = m.time("yyyyMMddHHmmss");

PolySyncLogDao syncLog = new PolySyncLogDao();

//테이블 존재 확인(없으면 DDL을 먼저 적용해야 합니다)
String[] baseTables = {
	"LM_POLY_COURSE", "LM_POLY_MEMBER", "LM_POLY_MEMBER_KEY", "LM_POLY_STUDENT",
	"LM_POLY_SYNC_LOG"
};
int missing = 0;
for(int i = 0; i < baseTables.length; i++) {
	int exists = 0;
	try {
		exists = syncLog.getOneInt(
			" SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES "
			+ " WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = '" + baseTables[i] + "' "
		);
	} catch(Exception ignore) {}
	if(exists <= 0) missing++;
}
if(missing > 0) {
	result.put("rst_code", "5001");
	result.put("rst_message", "미러 테이블이 없습니다. DB에 `public_html/ddl_poly_mirror.sql`을 먼저 적용해 주세요.");
	result.put("rst_missing", missing);
	result.print();
	return;
}

String endpoint = "https://e-poly.kopo.ac.kr/main/vpn_test.jsp";

try {
	//1) 외부 데이터 조회 (빈 응답이면 재시도)
	malgnsoft.db.DataSet courseList = new malgnsoft.db.DataSet();
	malgnsoft.db.DataSet memberList = new malgnsoft.db.DataSet();
	int targetCourseMaxYear = 0;

	if(!studentOnly) {
		String rawCourse = fetchPolyRaw(endpoint, "COM.LMS_COURSE_VIEW", courseCnt, 3, 2000);
		courseList = parsePolyResponse(rawCourse);

		if(courseList.size() == 0) {
			result.put("rst_code", "5002");
			result.put("rst_message", "학사 과목 데이터가 비어 있습니다. 외부 응답을 확인해 주세요.");
			result.print();
			return;
		}

		courseList.first();
		while(courseList.next()) {
			int y = toInt(pick(courseList, "open_year"));
			if(y > targetCourseMaxYear) targetCourseMaxYear = y;
		}
		courseList.first();

		String rawMember = fetchPolyRaw(endpoint, "COM.LMS_MEMBER_VIEW", memberCnt, 3, 2000);
		memberList = parsePolyResponse(rawMember);
	}

	// 학생 데이터는 100만 기준으로 한 번에 받아서 그대로 저장합니다.
	String rawStudent = fetchPolyRaw(endpoint, "COM.LMS_STUDENT_VIEW", studentCnt, 2, 1500);
	malgnsoft.db.DataSet studentList = parsePolyResponse(rawStudent);
	int studentMaxYear = maxOpenYearFromRaw(rawStudent);
	int studentCntUsed = studentCnt;

	//2) DB 저장(동기화 기준시각(sync_date)으로 “이번에 받은 것만” 남깁니다)
	PolyCourseDao polyCourse = new PolyCourseDao();
	PolyStudentDao polyStudent = new PolyStudentDao();
	PolyMemberDao polyMember = new PolyMemberDao();
	PolyMemberKeyDao polyMemberKey = new PolyMemberKeyDao();

	int courseSaved = 0;
	int studentSaved = 0;
	int memberSaved = 0;
	int aliasSaved = 0;

	//2-1) 과목
	if(!studentOnly) {
		courseList.first();
		while(courseList.next()) {
			String courseCode = pick(courseList, "course_code");
			String openYear = pick(courseList, "open_year");
			String openTerm = pick(courseList, "open_term");
			String bunbanCode = pick(courseList, "bunban_code");
			String groupCode = pick(courseList, "group_code");
			if("".equals(courseCode) || "".equals(openYear) || "".equals(openTerm) || "".equals(bunbanCode)) continue;
			if("".equals(groupCode)) groupCode = "U";

			String courseName = pick(courseList, "course_name");
			String courseEname = pick(courseList, "course_ename");
			String deptCode = pick(courseList, "dept_code");
			String deptName = pick(courseList, "dept_name");
			String gradCode = pick(courseList, "grad_code");
			String gradName = pick(courseList, "grad_name");
			String week = pick(courseList, "week");
			String grade = pick(courseList, "grade");
			String dayCd = pick(courseList, "day_cd");
			String classroom = pick(courseList, "classroom");
			String curriculumCode = pick(courseList, "curriculum_code");
			String curriculumName = pick(courseList, "curriculum_name");
			String typeSyllabus = pick(courseList, "type_syllabus");
			String isSyllabus = pick(courseList, "is_syllabus");
			String english = pick(courseList, "english");
			String hour1 = pick(courseList, "hour1");
			String category = pick(courseList, "category");
			String visible = pick(courseList, "visible");
			String startdate = pick(courseList, "startdate");
			String enddate = pick(courseList, "enddate");

			int ret = polyCourse.execute(
				" REPLACE INTO " + polyCourse.table
				+ " (course_code, open_year, open_term, bunban_code, group_code, sync_date"
				+ " , course_name, course_ename, dept_code, dept_name, grad_code, grad_name"
				+ " , week, grade, day_cd, classroom, curriculum_code, curriculum_name"
				+ " , type_syllabus, is_syllabus, english, hour1"
				+ " , category, visible, startdate, enddate, raw_json, reg_date, mod_date) "
				+ " VALUES(?,?,?,?,?,? ,?,?,?,?,?,? ,?,?,?,?,?,? ,?,?,?,? ,?,?,?,?,?,?,?) "
				, new Object[] {
					courseCode, openYear, openTerm, bunbanCode, groupCode, syncDate
					, courseName, courseEname, deptCode, deptName, gradCode, gradName
					, week, grade, dayCd, classroom, curriculumCode, curriculumName
					, typeSyllabus, isSyllabus, english, hour1
					, category, visible, startdate, enddate, null, syncDate, syncDate
				}
			);
			if(-1 < ret) courseSaved++;
		}
	}

	//2-2) 회원
	if(!studentOnly) {
		memberList.first();
		while(memberList.next()) {
			String memberKey = pick(memberList, "member_key");
			if("".equals(memberKey)) continue;

			String rpstKey = pick(memberList, "rpst_member_key");
			String userType = pick(memberList, "user_type");
			String name = pick(memberList, "kor_name");
			String engName = pick(memberList, "eng_name");
			String email = pick(memberList, "email");
			String mobile = pick(memberList, "mobile");
			String phone = pick(memberList, "phone");
			String campusCode = pick(memberList, "campus_code");
			String campusName = pick(memberList, "campus_name");
			String institutionCode = pick(memberList, "institution_code");
			String institutionName = pick(memberList, "institution_name");
			String deptCode = pick(memberList, "dept_code");
			String deptName = pick(memberList, "dept_name");
			String state = pick(memberList, "state");
			String useYn = pick(memberList, "use_yn");
			String gender = pick(memberList, "gender");

			int ret = polyMember.execute(
				" REPLACE INTO " + polyMember.table
				+ " (member_key, rpst_member_key, sync_date, user_type"
				+ " , kor_name, eng_name, email, mobile, phone"
				+ " , campus_code, campus_name, institution_code, institution_name"
				+ " , dept_code, dept_name, state, use_yn, gender"
				+ " , raw_json, reg_date, mod_date) "
				+ " VALUES(?,?,?,? ,?,?,?,?,? ,?,?,?,? ,?,?,?,?,? ,?,?,?) "
				, new Object[] {
					memberKey, rpstKey, syncDate, userType
					, name, engName, email, mobile, phone
					, campusCode, campusName, institutionCode, institutionName
					, deptCode, deptName, state, useYn, gender
					, null, syncDate, syncDate
				}
			);
			if(-1 < ret) memberSaved++;

			//별칭 매핑(두 키 모두 조회 가능하게)
			int retAlias1 = polyMemberKey.execute(
				" REPLACE INTO " + polyMemberKey.table + " (alias_key, member_key, sync_date, reg_date, mod_date) VALUES(?,?,?,?,?) "
				, new Object[] { memberKey, memberKey, syncDate, syncDate, syncDate }
			);
			if(-1 < retAlias1) aliasSaved++;

			if(!"".equals(rpstKey)) {
				int retAlias2 = polyMemberKey.execute(
					" REPLACE INTO " + polyMemberKey.table + " (alias_key, member_key, sync_date, reg_date, mod_date) VALUES(?,?,?,?,?) "
					, new Object[] { rpstKey, memberKey, syncDate, syncDate, syncDate }
				);
				if(-1 < retAlias2) aliasSaved++;
			}
		}
	}

	//2-3) 수강(수강생-과목)
	studentList.first();
	while(studentList.next()) {
		String courseCode = pick(studentList, "course_code");
		String openYear = pick(studentList, "open_year");
		String openTerm = pick(studentList, "open_term");
		String bunbanCode = pick(studentList, "bunban_code");
		String groupCode = pick(studentList, "group_code");
		String memberKey = pick(studentList, "member_key");
		String visible = pick(studentList, "visible");

		if("".equals(courseCode) || "".equals(openYear) || "".equals(openTerm) || "".equals(bunbanCode) || "".equals(memberKey)) continue;
		if("".equals(groupCode)) groupCode = "U";

		int ret = polyStudent.execute(
			" REPLACE INTO " + polyStudent.table
			+ " (course_code, open_year, open_term, bunban_code, group_code, member_key, visible, sync_date, raw_json, reg_date, mod_date) "
			+ " VALUES(?,?,?,?,?,?,?, ?, ?, ?, ?) "
			, new Object[] {
				courseCode, openYear, openTerm, bunbanCode, groupCode, memberKey, visible
				, syncDate, null, syncDate, syncDate
			}
		);
		if(-1 < ret) studentSaved++;
	}

	//3) 로그 기록
	syncLog.upsert(syncKey, "OK", "성공(req=" + requireYear + ", smax=" + studentMaxYear + ", cnt=" + studentCntUsed + ")");

	result.put("rst_code", "0000");
	result.put("rst_message", "성공");
	result.put("rst_sync_date", syncDate);
	result.put("rst_course_max_year", targetCourseMaxYear);
	result.put("rst_require_year", requireYear);
	result.put("rst_student_max_year", studentMaxYear);
	result.put("rst_student_cnt_used", studentCntUsed);
	result.put("rst_course_saved", courseSaved);
	result.put("rst_member_saved", memberSaved);
	result.put("rst_alias_saved", aliasSaved);
	result.put("rst_student_saved", studentSaved);
	result.print();

} catch(Exception e) {
	try { syncLog.upsert(syncKey, "ERR", e.getMessage()); } catch(Exception ignore) {}
	result.put("rst_code", "9000");
	result.put("rst_message", "동기화 중 오류가 발생했습니다: " + e.getMessage());
	result.put("rst_sync_date", syncDate);
	result.print();
}

%>
