<%@ page contentType="text/html; charset=utf-8" %><%@ include file="/init.jsp" %><%

//왜 필요한가:
//- 과목에 증명서 템플릿이 지정되지 않은 경우(또는 템플릿이 삭제/오류인 경우)에도
//  교수자 화면에서 수료증/합격증 출력이 막히지 않도록 "기본 수료증 화면"을 제공합니다.
//- sysop의 기본 수료증 출력(page.certificate)을 tutor 권한 기준으로 재사용합니다.

//로그인 확인
if(0 == userId) { m.jsErrClose("로그인이 필요합니다."); return; }
boolean isAdmin = "S".equals(userKind) || "A".equals(userKind);

int id = m.ri("cuid");
if(0 == id) { m.jsErrClose("cuid가 필요합니다."); return; }
String certType = m.rs("type"); //P(합격), C(수료)
if(!"P".equals(certType)) certType = "C";

CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
CourseLessonDao courseLesson = new CourseLessonDao();
TutorDao tutor = new TutorDao();
CourseTutorDao courseTutor = new CourseTutorDao();
UserDao user = new UserDao();
UserDeptDao userDept = new UserDeptDao();
FileDao file = new FileDao();

//권한: 교수자는 본인 과목만
DataSet cuBase = courseUser.find("id = " + id + " AND site_id = " + siteId + " AND status IN (1,3)");
if(!cuBase.next()) { m.jsErrClose("수강 정보를 찾을 수 없습니다."); return; }
if(!isAdmin) {
	if(0 >= courseTutor.findCount("course_id = " + cuBase.i("course_id") + " AND user_id = " + userId + " AND type = 'major' AND site_id = " + siteId)) {
		m.jsErrClose("해당 과목의 증명서를 출력할 권한이 없습니다.");
		return;
	}
}

//상세 정보(기본 수료증 템플릿(page.certificate)에서 사용하는 값들)
DataSet info = courseUser.query(
	" SELECT a.* "
	+ " , b.course_nm, b.course_type, b.onoff_type, b.lesson_day, b.lesson_time, b.year, b.step, b.course_address, b.credit "
	+ " , c.login_id, c.dept_id, c.user_nm, c.birthday, c.zipcode, c.new_addr, c.addr_dtl, c.gender, c.etc1, c.etc2, c.etc3, c.etc4, c.etc5 "
	+ " , d.dept_nm "
	+ " , (SELECT COUNT(*) FROM " + courseLesson.table + " WHERE course_id = a.course_id AND status = 1) lesson_cnt "
	+ " FROM " + courseUser.table + " a "
	+ " INNER JOIN " + course.table + " b ON a.course_id = b.id AND b.site_id = " + siteId + " AND b.status != -1 "
	+ " INNER JOIN " + user.table + " c ON a.user_id = c.id AND c.status != -1 "
	+ " LEFT JOIN " + userDept.table + " d ON c.dept_id = d.id "
	+ " WHERE a.id = " + id + " AND a.complete_yn = 'Y' AND a.status IN (1, 3) "
	+ ("P".equals(certType) ? " AND a.complete_status = 'P' " : " AND a.complete_status IN ('C','P') ")
);
if(!info.next()) { m.jsErrClose("수료(또는 합격) 처리된 수강 정보가 없습니다."); return; }

//포맷팅(기본 템플릿이 기대하는 키들)
if(0 < info.i("dept_id")) info.put("dept_nm_conv", userDept.getNames(info.i("dept_id")));
else {
	// 왜: 기본 수료증 템플릿(page.certificate)은 dept_nm을 직접 출력합니다.
	// 소속이 없으면 빈칸으로 보이지 않게 기본 문구를 넣어줍니다.
	info.put("dept_nm", "[미소속]");
	info.put("dept_nm_conv", "[미소속]");
}

info.put("lesson_time_conv", m.nf((int)info.d("lesson_time")));
info.put("birthday_conv", !"".equals(info.s("birthday")) ? m.time("yyyy.MM.dd", info.s("birthday")) : "-");
info.put("onoff_type_conv", m.getItem(info.s("onoff_type"), course.onoffTypes));

info.put("start_date_conv", !"".equals(info.s("start_date")) ? m.time("yyyy.MM.dd", info.s("start_date")) : "-");
info.put("end_date_conv", !"".equals(info.s("end_date")) ? m.time("yyyy.MM.dd", info.s("end_date")) : "-");
info.put("course_nm_conv", m.cutString(m.htmlToText(info.s("course_nm")), 48));

info.put("progress_ratio_conv", m.nf(info.d("progress_ratio"), 1));
info.put("total_score", m.nf(info.d("total_score"), 0));
info.put("complete_date_conv", !"".equals(info.s("complete_date")) ? m.time("yyyy.MM.dd", info.s("complete_date")) : "-");

info.put("today", m.time("yyyy년 MM월 dd일"));
info.put("today2", m.time("yyyy.MM.dd"));
info.put("today3", m.time("yy.MM.dd"));

//배경 이미지 URL(사이트 기본 수료증 배경)
String bgUrl = (!"/data".equals(Config.getDataUrl()) ? "" : siteDomain) + m.getUploadUrl(siteinfo.s("certificate_file"));
info.put("certificate_file_url", bgUrl);

//강사 목록(템플릿에서 사용할 수 있게)
DataSet tutors = courseTutor.query(
	"SELECT t.*, u.display_yn "
	+ " FROM " + courseTutor.table + " a "
	+ " LEFT JOIN " + tutor.table + " t ON a.user_id = t.user_id "
	+ " LEFT JOIN " + user.table + " u ON t.user_id = u.id "
	+ " WHERE a.course_id = " + info.i("course_id") + " "
	+ " ORDER BY t.tutor_nm ASC "
);

//사용자 파일(선택)
DataSet files = file.getFileList(info.i("user_id"), "user", true);
while(files.next()) {
	files.put("image_block", -1 < files.s("filetype").indexOf("image/"));
	files.put("file_url", m.getUploadUrl(files.s("filename")));
}

//렌더링
// 왜: 기본 수료증은 Malgn 템플릿(page.certificate)을 사용하므로, 루트를 /html로 맞춥니다.
p.setRoot(siteinfo.s("doc_root") + "/html");
p.setLayout(null);
p.setBody("page.certificate");

p.setVar(info);
p.setLoop("list", info);
p.setLoop("tutors", tutors);
p.setLoop("files", files);

p.setVar("single_block", true);
p.setVar("cert_title", "P".equals(certType) ? "합격증" : "수료증");
p.display();

%>
