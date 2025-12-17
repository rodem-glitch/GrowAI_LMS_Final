<%@ page contentType="text/html; charset=utf-8" %><%@ include file="/init.jsp" %><%

//왜 필요한가:
//- "수료증/합격증 출력"은 JSON이 아니라 HTML 인쇄 화면이어야 합니다.
//- sysop의 증명서 템플릿 렌더링 로직을 참고하되, tutor 화면 권한(교수자/관리자) 기준으로 제한합니다.

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
CertificateTemplateDao certificateTemplate = new CertificateTemplateDao();
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

//상세 정보(템플릿에서 쓰는 값들을 최대한 준비)
DataSet info = courseUser.query(
	" SELECT a.* "
	+ " , b.course_nm, b.course_type, b.onoff_type, b.lesson_day, b.lesson_time, b.year, b.step, b.course_address, b.credit, b.cert_template_id, b.pass_cert_template_id "
	+ " , c.login_id, c.dept_id, c.user_nm, c.birthday, c.zipcode, c.new_addr, c.addr_dtl, c.gender "
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

int targetTemplateId = "P".equals(certType) ? info.i("pass_cert_template_id") : info.i("cert_template_id");

//템플릿이 과목에 지정되지 않은 경우: 사이트 기본 템플릿 중 첫 번째를 사용합니다.
DataSet ctinfo = new DataSet();
try {
	String templateTypeFilter = "P".equals(certType) ? "P" : "C";
	if(0 < targetTemplateId) {
		ctinfo = certificateTemplate.find("id = " + targetTemplateId + " AND template_type = '" + templateTypeFilter + "' AND site_id = " + siteId + " AND status != -1");
	} else {
		ctinfo = certificateTemplate.find("site_id = " + siteId + " AND template_type = '" + templateTypeFilter + "' AND status = 1", "*", "reg_date DESC", 1);
	}
} catch(Exception e) {
	//fallback(환경 차이)
	ctinfo = certificateTemplate.find("site_id = " + siteId + " AND status = 1", "*", "reg_date DESC", 1);
}
if(!ctinfo.next()) { m.jsErrClose("증명서 템플릿이 없습니다."); return; }

//포맷팅(템플릿에서 자주 쓰는 키들을 맞춰줍니다)
if(0 < info.i("dept_id")) info.put("dept_nm_conv", userDept.getNames(info.i("dept_id")));
else info.put("dept_nm_conv", "[미소속]");

info.put("lesson_time_conv", m.nf((int)info.d("lesson_time")));
info.put("birthday_conv", !"".equals(info.s("birthday")) ? m.time("yyyy.MM.dd", info.s("birthday")) : "-");
info.put("onoff_type_conv", m.getItem(info.s("onoff_type"), course.onoffTypes));

info.put("start_date_conv", !"".equals(info.s("start_date")) ? m.time("yyyy.MM.dd", info.s("start_date")) : "-");
info.put("end_date_conv", !"".equals(info.s("end_date")) ? m.time("yyyy.MM.dd", info.s("end_date")) : "-");
info.put("course_nm_conv", m.cutString(m.htmlToText(info.s("course_nm")), 48));

info.put("progress_ratio_conv", m.nf(info.d("progress_ratio"), 1));
info.put("total_score", m.nf(info.d("total_score"), 0));
info.put("complete_date_conv", !"".equals(info.s("complete_date")) ? m.time("yyyy.MM.dd", info.s("complete_date")) : "-");

info.put("certificate_no", m.time("yyyy.MM.dd", info.s("start_date")) + "-" + m.strrpad(id + "", 5, "0"));
info.put("today", m.time("yyyy년 MM월 dd일"));
info.put("today2", m.time("yyyy.MM.dd"));
info.put("today3", m.time("yy.MM.dd"));

//배경 이미지 URL
info.put("certificate_file_url", m.getUploadUrl(ctinfo.s("background_file")));

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
p.setVar(info);
p.setLoop("list", info);
p.setLoop("tutors", tutors);
p.setLoop("files", files);
p.setVar("single_block", true);
p.setVar("cert_title", "P".equals(certType) ? "합격증" : "수료증");

String tbody = "";
try {
	tbody = certificateTemplate.fetchTemplate(siteId, ctinfo.s("template_cd"), p);
} catch(Exception e) {
	m.jsErrClose("증명서 템플릿을 불러오는 중 오류가 발생했습니다.");
	return;
}

out.print(tbody);

%>
<script>
window.onload = function() {
	try { window.print(); } catch (e) { alert("인쇄할 수 없습니다."); }
}
</script>

