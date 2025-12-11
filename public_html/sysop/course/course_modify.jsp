<%@ page contentType="text/html; charset=utf-8" %><%@ page import="java.text.DecimalFormat" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(33, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 있어야 합니다."); return; }

//객체
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
CourseRenewDao courseRenew = new CourseRenewDao();
CourseLessonDao courseLesson = new CourseLessonDao();
CourseModuleDao courseModule = new CourseModuleDao();
LmCategoryDao category = new LmCategoryDao("course");
LessonDao lesson = new LessonDao();

CourseBookDao courseBook = new CourseBookDao();
CourseTutorDao courseTutor = new CourseTutorDao();
CourseTargetDao courseTarget = new CourseTargetDao();
CoursePrecedeDao coursePrecede = new CoursePrecedeDao();
CourseManagerDao courseManager = new CourseManagerDao();
CoursePackageDao coursePackage = new CoursePackageDao();

CertificateTemplateDao certificateTemplate = new CertificateTemplateDao();

BookDao book = new BookDao();
UserDao user = new UserDao();
TutorDao tutor = new TutorDao();
GroupDao group = new GroupDao();

MCal mcal = new MCal(); mcal.yearRange = 10;

//정보-사이트설정
DataSet siteconfig = SiteConfig.getArr(new String[] {"cert_template_yn", "kollus"});

//m.p(siteconfig);

//카테고리
DataSet categories = category.getList(siteId);

DataSet info = course.query(
	"SELECT a.*, c.course_nm before_course_nm, l.lesson_nm sample_lesson_nm "
	+ " FROM " + course.table + " a "
	+ " LEFT JOIN " + course.table + " c ON a.before_course_id = c.id "
	+ " LEFT JOIN " + lesson.table + " l ON a.sample_lesson_id = l.id "
	+ " WHERE a.id = " + id	+ " AND a.status != -1 AND a.site_id = " + siteId + ""
	+ ("C".equals(userKind) ? " AND a.id IN (" + manageCourses + ") " : "")
);
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//온라인 정규강의의 경우 화상강의 차시가 존재하면 차시별 학습기간 사용으로 고정
boolean isOnlineRegular = "N".equals(info.s("onoff_type")) & "R".equals(info.s("course_type"));
boolean hasTwoway = false;
if(isOnlineRegular) {
	hasTwoway = 0 < courseLesson.getOneInt(
		" SELECT COUNT(*) FROM " + courseLesson.table + " a "
		+ " INNER JOIN " + lesson.table + " l ON a.lesson_id = l.id AND l.site_id = " + siteId
		+ " WHERE a.course_id = " + info.i("id") + " AND a.site_id = " + siteId	+ " AND l.onoff_type = 'T'"
	);
}

info.put("lesson_time", new DecimalFormat("#.##").format(info.d("lesson_time")));
info.put("limit_ratio", new DecimalFormat("#.##").format(info.d("limit_ratio")));
info.put("request_sdate", m.time("yyyy-MM-dd", info.s("request_sdate")));
info.put("request_edate", m.time("yyyy-MM-dd", info.s("request_edate")));
info.put("study_sdate", m.time("yyyy-MM-dd", info.s("study_sdate")));
info.put("study_edate", m.time("yyyy-MM-dd", info.s("study_edate")));
info.put("onoff_type_" + info.s("onoff_type"), true);
info.put("course_type_" + info.s("course_type"), true);
info.put("cate_name", category.getTreeNames(info.i("category_id")));
info.put("lesson_order_block", "N".equals(info.s("onoff_type")));
info.put("period_block", isOnlineRegular & !hasTwoway);
info.put("online_block", "N".equals(info.s("onoff_type")));
info.put("lesson_order_conv", info.b("lesson_order_yn") ? "사용" : "미사용");
info.put("period_yn_conv", info.b("period_yn") ? "사용" : "미사용");

//변수
boolean closed = info.b("close_yn");
boolean isPackage = "P".equals(info.s("onoff_type"));
boolean usePlayrate = "Y".equals(siteconfig.s("kollus_playrate_yn"));
String[] courseAddr = m.split("|", info.s("course_address"));

//파일삭제
if("fdel".equals(m.rs("mode"))) {
	//제한
	if(closed) { m.jsAlert("해당 과정은 종료되어 파일을 삭제할 수 없습니다."); return; }

	if(!"".equals(info.s("course_file"))) {
		course.item("course_file", "");
		if(course.update("id = " + id)) {
			m.delFileRoot(m.getUploadPath(info.s("course_file")));
		}
	}
	return;
}

//폼체크
f.addElement("onoff_type", info.s("onoff_type"), "hname:'과정 구분', required:'Y'");
f.addElement("category_id", info.i("category_id"), "hname:'카테고리', required:'Y'");
f.addElement("category_nm", category.getTreeNames(info.i("category_id")), "hname:'카테고리', required:'Y'");

f.addElement("course_nm", info.s("course_nm"), "hname:'과정명', required:'Y'");
f.addElement("course_type", info.s("course_type"), "hname:'과정구분', required:'Y'");
f.addElement("year", info.s("year"), "hname:'년도', required:'Y'");

//f.addElement("step", info.s("step"), "hname:'기수', required:'Y', option:'number'");
//f.addElement("grade", info.s("grade"), "hname:'학년', required:'Y'");
f.addElement("term", info.s("term"), "hname:'학기', required:'Y'");
//f.addElement("subject", info.s("subject"), "hname:'과목', required:'Y'");

f.addElement("request_sdate", info.s("request_sdate"), "hname:'수강신청시작일'");
f.addElement("request_edate", info.s("request_edate"), "hname:'수강신청종료일'");
f.addElement("study_sdate", info.s("study_sdate"), "hname:'학습시작일'");
f.addElement("study_edate", info.s("study_edate"), "hname:'학습종료일'");
f.addElement("user_date_yn", "N", "hname:'기존수강생 학습기간 일괄변경 여부'");
f.addElement("lesson_day", info.i("lesson_day"), "hname:'학습일수', option:'number', min:'1'");
f.addElement("course_file", null, "hname:'메인이미지', allow:'jpg|jpeg|gif|png'");
f.addElement("list_price", info.i("list_price"), "hname:'정가', option:'number', required:'Y'");
f.addElement("price", info.i("price"), "hname:'수강료', option:'number', required:'Y'");
f.addElement("taxfree_yn", info.s("taxfree_yn"), "hname:'부가세면세여부'");
f.addElement("disc_group_yn", info.s("disc_group_yn"), "hname:'그룹할인적용여부'");
f.addElement("memo_yn", info.s("memo_yn"), "hname:'주문메모 사용여부'");
if(!isPackage) {
	f.addElement("renew_yn", info.s("renew_yn"), "hname:'수강기간 연장결제 사용여부'");
	f.addElement("renew_max_cnt", info.i("renew_max_cnt"), "hname:'최대 연장횟수', option:'number', min:'0', max:'999'");
	f.addElement("renew_price", info.i("renew_price"), "hname:'연장비용', option:'number', min:'0'");
	f.addElement("credit", info.i("credit"), "hname:'학점', required:'Y'");
	f.addElement("lesson_time", info.s("lesson_time"), "hname:'시수', min:'0.01', required:'Y'");
}
f.addElement("mobile_yn", info.s("mobile_yn"), "hname:'모바일 지원여부'");
f.addElement("evaluation_yn", info.s("evaluation_yn"), "hname:'수료기준 노출여부'");
//f.addElement("top_yn", info.s("top_yn"), "hname:'상시 상위고정'");

f.addElement("recomm_yn", info.s("recomm_yn"), "hname:'추천과정'");
f.addElement("auto_approve_yn", info.s("auto_approve_yn"), "hname:'신청즉시 승인여부'");
f.addElement("sms_yn", info.s("sms_yn"), "hname:'SMS 인증여부'");
f.addElement("target_yn", info.s("target_yn"), "hname:'학습대상자 사용여부'");
if(!isPackage) f.addElement("complete_auto_yn", info.s("complete_auto_yn"), "hname:'자동 수료처리'");
//else f.addElement("complete_auto_yn", info.s("complete_auto_yn"), "hname:'자동 수료처리'");
f.addElement("restudy_yn", info.s("restudy_yn"), "hname:'복습사용여부'");
f.addElement("restudy_day", info.i("restudy_day"), "hname:'복습허용기간', option:'number', max:'3700'");

f.addElement("limit_lesson_yn", info.s("limit_lesson_yn"), "hname:'학습강의제한 사용여부'");
f.addElement("limit_lesson", info.i("limit_lesson"), "hname:'학습제한 강의 수', option:'number'");
f.addElement("limit_people_yn", info.s("limit_people_yn"), "hname:'수강인원제한 사용유무'");
f.addElement("limit_people", info.i("limit_people"), "hname:'수강제한인원', option:'number'");
f.addElement("limit_ratio_yn", info.s("limit_ratio_yn"), "hname:'배수제한 사용유무'");
f.addElement("limit_ratio", info.s("limit_ratio"), "hname:'배수제한비율'");
f.addElement("limit_seek_yn", info.s("limit_seek_yn"), "hname:'탐색제한 사용유무'");
f.addElement("lesson_order_yn", info.s("lesson_order_yn"), "hname:'강의 순차적용 여부'");
if(!isPackage) f.addElement("period_yn", info.s("period_yn"), "hname:'차시별 수강기간'");
if(usePlayrate) f.addElement("playrate_yn", info.s("playrate_yn"), "hname:'수강제한인원'");

f.addElement("exam_yn", info.s("exam_yn"), "hname:'시험 사용여부'");
f.addElement("homework_yn", info.s("homework_yn"), "hname:'과제 사용여부'");
f.addElement("forum_yn", info.s("forum_yn"), "hname:'토론 사용여부'");
f.addElement("survey_yn", info.s("survey_yn"), "hname:'설문 사용여부'");
f.addElement("review_yn", info.s("review_yn"), "hname:'사용후기 사용여부'");
f.addElement("cert_course_yn", info.s("cert_course_yn"), "hname:'수강증 사용여부'");
f.addElement("cert_complete_yn", info.s("cert_complete_yn"), "hname:'수료증 사용여부'");
//새로 추가 Start
f.addElement("cert_course2_yn", info.s("cert_course2_yn"), "hname:'2학기 합격증 사용여부'");
f.addElement("cert_complete2_yn", info.s("cert_complete2_yn"), "hname:'2학기 수료증 사용여부'");
f.addElement("status_fullcourse", info.s("status_fullcourse"), "hname:'수료증합격증 4번사용여부'");
//새로 추가 End
f.addElement("sample_lesson_nm", info.s("sample_lesson_nm"), "hname:'샘플동영상'");
f.addElement("before_course_nm", info.s("before_course_nm"), "hname:'선행과정'");
f.addElement("course_addr", courseAddr[0], "hname:'교육장 주소'");
f.addElement("course_addr_dtl", (1 < courseAddr.length ? courseAddr[1] : ""), "hname:'교육장 상세주소'");

f.addElement("subtitle", null, "hname:'과정목록 소개문구'");
f.addElement("content1", null, "hname:'텍스트1', allowiframe:'Y', allowhtml:'Y'");
f.addElement("content2", null, "hname:'텍스트2', allowiframe:'Y'");
f.addElement("content1_title", info.s("content1_title"), "hname:'텍스트1 타이틀'");
f.addElement("content2_title", info.s("content2_title"), "hname:'텍스트2 타이틀'");
//f.addElement("manager_id", info.s("manager_id"), "hname:'담당자'");
//f.addElement("manager_name", info.s("manager_name"), "hname:'담당자'");
f.addElement("etc1", info.s("etc1"), "hname:'기타1'");
f.addElement("etc2", info.s("etc2"), "hname:'기타2'");
f.addElement("sale_yn", info.s("sale_yn"), "hname:'판매여부'");
f.addElement("display_yn", info.s("display_yn"), "hname:'노출여부'");
f.addElement("status", info.s("status"), "hname:'상태'");

if(!isPackage) {
	f.addElement("assign_progress", info.i("assign_progress"), "hname:'출석(진도) 배점비율', option:'number', required:'Y'");
	f.addElement("assign_exam", info.i("assign_exam"), "hname:'시험 배점비율', option:'number', required:'Y'");
	f.addElement("assign_homework", info.i("assign_homework"), "hname:'과제 배점비율', option:'number', required:'Y'");
	f.addElement("assign_forum", info.i("assign_forum"), "hname:'토론 배점비율', option:'number', required:'Y'");
	f.addElement("assign_etc", info.i("assign_etc"), "hname:'기타 배점비율', option:'number', required:'Y'");
	f.addElement("assign_survey_yn", info.s("assign_survey_yn"), "hname:'설문참여 필수여부'");
	f.addElement("limit_total_score", info.i("limit_total_score"), "hname:'총점 수료기준', option:'number', required:'Y'");
	f.addElement("limit_progress", info.i("limit_progress"), "hname:'진도 수료기준', option:'number', required:'Y'");
	f.addElement("limit_exam", info.i("limit_exam"), "hname:'시험 수료기준', option:'number', required:'Y'");
	f.addElement("limit_homework", info.i("limit_homework"), "hname:'과제 수료기준', option:'number', required:'Y'");
	f.addElement("limit_forum", info.i("limit_forum"), "hname:'토론 수료기준', option:'number', required:'Y'");
	f.addElement("limit_etc", info.i("limit_etc"), "hname:'기타 수료기준', option:'number', required:'Y'");
	f.addElement("push_survey_yn", info.s("push_survey_yn"), "hname:'설문참여 독려여부'");

	f.addElement("cert_template_id", info.i("cert_template_id"), "hname:'수료증 템플릿'");
	f.addElement("complete_prefix", info.s("complete_prefix"), "hname:'수료번호'");
	f.addElement("complete_no_yn", info.s("complete_no_yn"), "hname:'수료번호 사용여부'");
	f.addElement("postfix_cnt", info.i("postfix_cnt"), "hname:'수료번호 뒷자리수'");
	f.addElement("postfix_type", info.s("postfix_type"), "hname:'수료번호 뒷자리방식'");
	f.addElement("postfix_ord", info.s("postfix_ord"), "hname:'수료번호 정렬방식'");
}

//등록
if(m.isPost() && f.validate()) {

	//제한
	if(closed) { m.jsAlert("해당 과정은 종료되어 수정할 수 없습니다."); return; }

	//제한-패키지
	if(isPackage && "Y".equals(f.get("sale_yn")) && 0 >= coursePackage.findCount("package_id = " + id)) {
		m.jsAlert("해당 패키지에 등록된 과정이 없어 판매여부를 변경할 수 없습니다.");
		return;
	}

	if(!isPackage) {
		if(f.get("complete_prefix").length() > 20) { m.jsAlert("수료번호 앞자리는 20자를 초과해 설정하실 수 없습니다."); return; }
		if(f.getInt("postfix_cnt") > 8) { m.jsAlert("수료번호 뒷자리수는 8개를 초과해 설정하실 수 없습니다."); return; }
	}


	//제한
	/*
	if(0 < course.findCount(
			"site_id = " + siteId + " AND subject_id = " + info.i("subject_id") + " "
			+ " AND year = " + f.getInt("year") + " AND step = " + f.getInt("step") + " "
			+ " AND id != " + id + " AND status != -1"
	)) {
		m.jsAlert("과정명/년도/기수를 사용 중입니다. 다시 입력하세요.");
		return;
	}
	*/

	//제한-이미지URI및용량
	String subtitle = f.get("subtitle");
	String content1 = f.get("content1");
	String content2 = f.get("content2");
	int bytest = subtitle.replace("\r\n", "\n").getBytes("UTF-8").length;
	int bytes1 = content1.replace("\r\n", "\n").getBytes("UTF-8").length;
	int bytes2 = content2.replace("\r\n", "\n").getBytes("UTF-8").length;
	if(-1 < content1.indexOf("<img") && -1 < content1.indexOf("data:image/") && -1 < content1.indexOf("base64")) {
		m.jsAlert(f.get("content1_title") + " 이미지는 첨부파일 기능으로 업로드 해 주세요.");
		return;
	}
	if(500 < bytest) { m.jsAlert("과정목록 소개문구 내용은 500바이트를 초과해 작성하실 수 없습니다.\\n(현재 " + bytest + "바이트)"); return; }
	if(60000 < bytes1) { m.jsAlert(f.get("content1_title") + " 내용은 60000바이트를 초과해 작성하실 수 없습니다.\\n(현재 " + bytes1 + "바이트)"); return; }
	if(60000 < bytes2) { m.jsAlert(f.get("content2_title") + " 내용은 60000바이트를 초과해 작성하실 수 없습니다.\\n(현재 " + bytes2 + "바이트)"); return; }

	course.item("course_nm", f.get("course_nm"));
	course.item("category_id", f.get("category_id"));

	course.item("year", f.get("year"));
//	course.item("step", f.get("step"));
//	course.item("grade", f.get("grade"));
	course.item("term", f.get("term"));
//	course.item("subject", f.get("subject"));

	String ssdate = "";
	String sedate = "";
	course.item("course_type", f.get("course_type"));
	if("R".equals(f.get("course_type"))) { //정규
		ssdate = m.time("yyyyMMdd", f.get("study_sdate"));
		sedate = m.time("yyyyMMdd", f.get("study_edate"));

		course.item("request_sdate", m.time("yyyyMMdd", f.get("request_sdate")));
		course.item("request_edate", m.time("yyyyMMdd", f.get("request_edate")));
		course.item("study_sdate", ssdate);
		course.item("study_edate", sedate);

	} else if("A".equals(f.get("course_type"))) { //상시
		course.item("request_sdate", "");
		course.item("request_edate", "");
		course.item("study_sdate", "");
		course.item("study_edate", "");
	}

	if("P".equals(f.get("onoff_type"))) {
		course.item("study_sdate", "");
		course.item("study_edate", "");
	}

	course.item("lesson_day", f.getInt("lesson_day"));
	course.item("lesson_time", f.getDouble("lesson_time"));

	boolean isUpload = false;
	if(null != f.getFileName("course_file")) {
		File f1 = f.saveFile("course_file");
		if(f1 != null) {
			isUpload = true;
			course.item("course_file", f.getFileName("course_file"));
			if(!"".equals(info.s("course_file")) && new File(m.getUploadPath(info.s("course_file"))).exists()) {
				m.delFileRoot(m.getUploadPath(info.s("course_file")));
			}
		}
	}
	course.item("list_price", f.getInt("list_price"));
	course.item("price", f.getInt("price"));
	course.item("taxfree_yn", f.get("taxfree_yn", "N"));
	course.item("disc_group_yn", f.get("disc_group_yn", "N"));
	course.item("memo_yn", f.get("memo_yn", "N"));
	course.item("renew_price", f.getInt("renew_price"));
	course.item("renew_max_cnt", f.getInt("renew_max_cnt"));
	course.item("renew_yn", f.get("renew_yn", "N"));

	course.item("credit", f.getInt("credit"));
	course.item("mobile_yn", f.get("mobile_yn", "N"));
	course.item("evaluation_yn", f.get("evaluation_yn", "N"));
	//course.item("top_yn", f.get("top_yn", "N"));

	course.item("recomm_yn", f.get("recomm_yn", "N"));
	course.item("auto_approve_yn", f.get("auto_approve_yn", "N"));
	course.item("sms_yn", f.get("sms_yn", "N"));
	course.item("target_yn", f.get("target_yn", "N"));
	course.item("complete_auto_yn", f.get("complete_auto_yn", "N"));
	course.item("restudy_yn", f.get("restudy_yn", "N"));
	course.item("restudy_day", "Y".equals(f.get("restudy_yn", "N")) ? (3700 > f.getInt("restudy_day") ? f.getInt("restudy_day") : 3700) : 0);

	course.item("limit_lesson_yn", f.get("limit_lesson_yn", "N"));
	course.item("limit_lesson", "Y".equals(f.get("limit_lesson_yn", "N")) ? f.getInt("limit_lesson") : 0);
	course.item("limit_people_yn", f.get("limit_people_yn", "N"));
	course.item("limit_people", "Y".equals(f.get("limit_people_yn", "N")) ? f.getInt("limit_people") : 0);
	course.item("limit_ratio_yn", f.get("limit_ratio_yn", "N"));
	course.item("limit_ratio", "Y".equals(f.get("limit_ratio_yn", "N")) ? f.getDouble("limit_ratio") : 0);
	course.item("limit_seek_yn", f.get("limit_seek_yn", "N"));
	course.item("lesson_order_yn", f.get("lesson_order_yn", "N"));
	if(!isPackage) {

		if(isOnlineRegular &&
			0 < courseLesson.getOneInt(
			" SELECT COUNT(*) FROM " + courseLesson.table + " a "
			+ " INNER JOIN " + lesson.table + " l ON a.lesson_id = l.id AND l.site_id = " + siteId
			+ " WHERE a.course_id = " + info.i("id") + " AND a.site_id = " + siteId	+ " AND l.onoff_type = 'T'"
		)) {
			course.item("period_yn", "Y");
		} else {
			course.item("period_yn", f.get("period_yn", "N"));
		}

	}
	if(usePlayrate) course.item("playrate_yn", f.get("playrate_yn", "N"));

	course.item("push_survey_yn", f.get("push_survey_yn", "N"));

	course.item("sample_lesson_id", f.getInt("sample_lesson_id"));
	//course.item("before_course_id", f.getInt("before_course_id"));
	//course.item("course_address", f.get("course_address"));
	course.item("course_address", f.glue("|", "course_addr,course_addr_dtl"));

	course.item("exam_yn", f.get("exam_yn", "N"));
	course.item("homework_yn", f.get("homework_yn", "N"));
	course.item("forum_yn", f.get("forum_yn", "N"));
	course.item("survey_yn", f.get("survey_yn", "N"));
	course.item("review_yn", f.get("review_yn", "N"));
	course.item("cert_course_yn", f.get("cert_course_yn", "N"));
	course.item("cert_complete_yn", f.get("cert_complete_yn", "N"));
	//새로 추가 Start
	course.item("cert_course2_yn", f.get("cert_course2_yn", "N"));
	course.item("cert_complete2_yn", f.get("cert_complete2_yn", "N"));
	course.item("status_fullcourse", f.get("status_fullcourse", "N"));
	//새로 추가 End
	course.item("subtitle", subtitle);
	course.item("content1_title", f.get("content1_title"));
	course.item("content1", content1);
	course.item("content2_title", f.get("content2_title"));
	course.item("content2", content2);
	//if(!"C".equals(userKind)) course.item("manager_id", f.getInt("manager_id") != 0 ? f.getInt("manager_id") : userId);
	course.item("etc1", f.get("etc1"));
	course.item("etc2", f.get("etc2"));
	course.item("sale_yn", f.get("sale_yn", "N"));
	course.item("display_yn", f.get("display_yn", "N"));
	course.item("status", f.get("status", "0"));

	if(!isPackage) {
		course.item("assign_progress", f.getInt("assign_progress"));
		course.item("assign_exam", f.getInt("assign_exam"));
		course.item("assign_homework", f.getInt("assign_homework"));
		course.item("assign_forum", f.getInt("assign_forum"));
		course.item("assign_etc", f.getInt("assign_etc"));
		course.item("assign_survey_yn", f.get("assign_survey_yn"));
		course.item("limit_progress", f.getInt("limit_progress"));
		course.item("limit_exam", f.getInt("limit_exam"));
		course.item("limit_homework", f.getInt("limit_homework"));
		course.item("limit_forum", f.getInt("limit_forum"));
		course.item("limit_etc", f.getInt("limit_etc"));
		course.item("limit_total_score", f.getInt("limit_total_score"));
		// 새로 추가 Start
		course.item("limit_total_score2", f.getInt("limit_total_score2"));
		course.item("limit_total_course", f.getInt("limit_total_course"));
		course.item("limit_total_course2", f.getInt("limit_total_course2"));
		course.item("cert_template_id", f.getInt("template_id"));
		course.item("complete_prefix", f.get("complete_prefix"));
		// 새로 추가 Start
		course.item("cert_template_id", f.getInt("cert_template_id"));
		course.item("complete_prefix", f.get("complete_prefix"));
		course.item("complete_no_yn", f.get("complete_no_yn"));
		course.item("postfix_cnt", f.getInt("postfix_cnt"));
		course.item("postfix_type", f.get("postfix_type"));
		course.item("postfix_ord", f.get("postfix_ord"));
	}

	if(!course.update("id = " + id + "")) { m.jsAlert("수정하는 중 오류가 발생했습니다."); return; }

	//갱신-학습기간변경시
	String oldSsdate = m.time("yyyyMMdd", info.s("study_sdate"));
	String oldSedate = m.time("yyyyMMdd", info.s("study_edate"));
	if("R".equals(f.get("course_type")) && "Y".equals(f.get("user_date_yn"))) {
		courseUser.item("start_date", ssdate);
		courseUser.item("end_date", sedate);
		if(!courseUser.update("course_id = " + id + "")) {
			m.jsAlert("수강생 정보를 수정하는 중 오류가 발생했습니다."); return;
		}

		//등록-수강기간이력
		courseRenew.item("site_id", siteId);
		courseRenew.item("renew_type", "U");
		courseRenew.item("user_id", userId);
		courseRenew.item("start_date", ssdate);
		courseRenew.item("end_date", sedate);
		courseRenew.item("order_item_id", -99);
		courseRenew.item("reg_date", sysNow);
		courseRenew.item("status", 1);
		DataSet culist = courseUser.find("course_id = " + id + "");
		while(culist.next()) {
			courseRenew.item("course_user_id", culist.i("id"));
			if(!courseRenew.insert()) { m.jsError("수강이력을 등록하는 중 오류가 발생했습니다."); return; }
		}


		//갱신-강의기간
		if(!oldSsdate.equals(ssdate)) {
			String where = (0 > m.diffDate("D", oldSsdate, ssdate) ? "a.start_date = '" + oldSsdate + "'" : "a.start_date <= '" + ssdate + "'");
			DataSet cllist = courseLesson.query(
				" SELECT a.lesson_id, a.start_date, l.onoff_type "
				+ " FROM " + courseLesson.table + " a "
				+ " INNER JOIN " + lesson.table + " l ON a.lesson_id = l.id "
				+ " WHERE a.course_id = " + id + " AND " + where + " AND a.status != -1 "
			);

			courseLesson.clear();
			courseLesson.item("start_date", ssdate);
			while(cllist.next()) {
				courseLesson.item("end_date", !"F".equals(cllist.s("onoff_type")) ? cllist.s("end_date") : ssdate);
				if(!courseLesson.update("course_id = " + id + " AND lesson_id = " + cllist.i("lesson_id"))) { m.jsAlert("강의 정보를 수정하는 중 오류가 발생했습니다."); return; }
			}
		}
		if(!oldSedate.equals(sedate)) {
			String where = (0 < m.diffDate("D", oldSedate, sedate) ? "a.end_date = '" + oldSedate + "'" : "a.end_date >= '" + sedate + "'");
			DataSet cllist = courseLesson.query(
				" SELECT a.lesson_id, a.start_date, l.onoff_type "
				+ " FROM " + courseLesson.table + " a "
				+ " INNER JOIN " + lesson.table + " l ON a.lesson_id = l.id "
				+ " WHERE a.course_id = " + id + " AND " + where + " AND a.status != -1 "
			);

			courseLesson.clear();
			courseLesson.item("end_date", sedate);
			while(cllist.next()) {
				courseLesson.item("start_date", !"F".equals(cllist.s("onoff_type")) ? cllist.s("start_date") : sedate);
				if(!courseLesson.update("course_id = " + id + " AND lesson_id = " + cllist.i("lesson_id"))) { m.jsAlert("강의 정보를 수정하는 중 오류가 발생했습니다."); return; }
			}
		}
	}

	//갱신-차시별순차학습변경시-기존차시학습기간부여
	if("Y".equals(f.get("period_yn")) && !"Y".equals(info.s("period_yn"))) {
		DataSet cllist = courseLesson.query(
			" SELECT a.lesson_id "
			+ " FROM " + courseLesson.table + " a "
			+ " INNER JOIN " + lesson.table + " l ON a.lesson_id = l.id AND l.onoff_type = 'N' "
			+ " WHERE a.course_id = " + id
			+ " AND (a.start_date IS NULL OR a.start_date = '') OR (a.end_date IS NULL OR a.end_date = '') "
			+ " AND a.status != -1 "
		);

		courseLesson.clear();
		courseLesson.item("start_date", ssdate);
		courseLesson.item("start_time", "000000");
		courseLesson.item("end_date", sedate);
		courseLesson.item("end_time", "235559");

		ArrayList<Integer> lidx = new ArrayList<Integer>();
		while(cllist.next()) {
			if(!lidx.contains(cllist.i("lesson_id"))) lidx.add(cllist.i("lesson_id"));
		}
		if(0 < cllist.size() && !courseLesson.update("course_id = " + id + " AND lesson_id IN (" + m.join(",", lidx.toArray()) + ")")) {
			m.jsAlert("강의 정보를 수정하는 중 오류가 발생했습니다.");
			return;
		}
	}

	//도서
	if(-1 != courseBook.execute("DELETE FROM " + courseBook.table + " WHERE course_id = " + id + "")) {
		if(null != f.getArr("book_id")) {
			courseBook.item("course_id", id);
			courseBook.item("site_id", siteId);
			for(int i = 0; i < f.getArr("book_id").length; i++) {
				courseBook.item("book_id", f.getArr("book_id")[i]);
				if(!courseBook.insert()) { }
			}
		}
	}

	//강사
	if(-1 != courseTutor.execute("DELETE FROM " + courseTutor.table + " WHERE course_id = " + id + "")) {
		if(null != f.getArr("major_tutor_id")) {
			courseTutor.item("course_id", id);
			courseTutor.item("site_id", siteId);
			courseTutor.item("type", "major");
			for(int i = 0; i < f.getArr("major_tutor_id").length; i++) {
				courseTutor.item("user_id", f.getArr("major_tutor_id")[i]);
				if(!courseTutor.insert()) { }
			}
		}
	}

	//과정담당자
	if(adminBlock && -1 != courseManager.execute("DELETE FROM " + courseManager.table + " WHERE course_id = " + id + "")) {
		if(null != f.getArr("manager_id")) {
			courseManager.item("course_id", id);
			courseManager.item("site_id", siteId);
			for(int i = 0; i < f.getArr("manager_id").length; i++) {
				courseManager.item("user_id", f.getArr("manager_id")[i]);
				if(!courseManager.insert()) { }
			}
		}
	}

	//그룹
	if(-1 != courseTarget.execute("DELETE FROM " + courseTarget.table + " WHERE course_id = " + id + "")) {
		if(null != f.getArr("group_id")) {
			courseTarget.item("course_id", id);
			courseTarget.item("site_id", siteId);
			for(int i = 0; i < f.getArr("group_id").length; i++) {
				courseTarget.item("group_id", f.getArr("group_id")[i]);
				if(!courseTarget.insert()) { }
			}
		}
	}

	//선행
	if(-1 != coursePrecede.execute("DELETE FROM " + coursePrecede.table + " WHERE course_id = " + id + "")) {
		if(null != f.getArr("precede_id")) {
			coursePrecede.item("course_id", id);
			coursePrecede.item("site_id", siteId);
			for(int i = 0; i < f.getArr("precede_id").length; i++) {
				coursePrecede.item("precede_id", f.getArr("precede_id")[i]);
				if(!coursePrecede.insert()) { }
			}
		}
	}

	//파일리사이징
	if(isUpload) {
		try {
			String imgPath = m.getUploadPath(f.getFileName("course_file"));
			String cmd = "convert -resize 1000x> " + imgPath + " " + imgPath;
			Runtime.getRuntime().exec(cmd);
		}
		catch(RuntimeException re) { m.errorLog("RuntimeException : " + re.getMessage(), re); }
		catch(Exception e) { m.errorLog("Exception : " + e.getMessage(), e); }
	}

	m.jsAlert("성공적으로 수정했습니다.");
	m.jsReplace("course_modify.jsp?" + m.qs(), "parent");
	return;
}

//포멧팅
info.put("content1", m.htt(info.s("content1")));
info.put("course_file_conv", m.encode(info.s("course_file")));
info.put("course_file_url", m.getUploadUrl(info.s("course_file")));
info.put("course_file_ek", m.encrypt(info.s("course_file") + m.time("yyyyMMdd")));

int userCnt = courseUser.findCount("course_id = " + id + " AND status != -1");
boolean isModify = 0 == userCnt; //수정가능여부
info.put("delete_block", isModify);

//목록-도서
DataSet books = courseBook.query(
	"SELECT a.*, b.book_nm "
	+ " FROM " + courseBook.table + " a "
	+ " INNER JOIN " + book.table + " b ON a.book_id = b.id "
	+ " WHERE a.course_id = " + id + ""
);

//목록-강사
DataSet tutors = courseTutor.query(
	"SELECT a.*, t.tutor_nm "
	+ " FROM " + courseTutor.table + " a "
	+ " INNER JOIN " + tutor.table + " t ON t.user_id = a.user_id "
	+ " WHERE a.course_id = " + id + ""
);

//목록-과정담당자
DataSet managers = courseManager.query(
	"SELECT a.*, u.user_nm manager_nm, u.login_id "
	+ " FROM " + courseManager.table + " a "
	+ " INNER JOIN " + user.table + " u ON u.id = a.user_id "
	+ " WHERE a.course_id = " + id + " AND u.site_id = " + siteId + " AND u.status != -1 "
);

//목록-대상자
DataSet targets = courseTarget.query(
	"SELECT a.*, g.group_nm "
	+ " FROM " + courseTarget.table + " a "
	+ " INNER JOIN " + group.table + " g ON a.group_id = g.id AND g.site_id = " + siteId + " "
	+ " WHERE a.course_id = " + id + ""
);

//목록-선행
DataSet pcourses = coursePrecede.query(
	"SELECT c.* "
	+ " FROM " + coursePrecede.table + " a "
	+ " INNER JOIN " + course.table + " c ON a.precede_id = c.id "
	+ " WHERE a.course_id = " + id + ""
);
while(pcourses.next()) {
	pcourses.put("course_nm_conv", m.cutString(pcourses.s("course_nm"), 40));
	pcourses.put("status_conv", m.getItem(pcourses.s("status"), course.statusList));
	pcourses.put("display_conv", pcourses.b("display_yn") ? "정상" : "숨김");
	pcourses.put("type_conv", m.getItem(pcourses.s("course_type"), course.types));
	pcourses.put("onoff_type_conv", m.getItem(pcourses.s("onoff_type"), course.onoffTypes));

	pcourses.put("alltimes_block", "A".equals(pcourses.s("course_type")));
	pcourses.put("request_sdate_conv", m.time("yyyy.MM.dd", pcourses.s("request_sdate")));
	pcourses.put("request_edate_conv", m.time("yyyy.MM.dd", pcourses.s("request_edate")));
	pcourses.put("study_sdate_conv", m.time("yyyy.MM.dd", pcourses.s("study_sdate")));
	pcourses.put("study_edate_conv", m.time("yyyy.MM.dd", pcourses.s("study_edate")));
}

//출력
p.setBody("course.course_insert");
p.setVar("list_query", m.qs("id"));
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setVar(info);
p.setVar("modify", true);
p.setVar("admin_block", adminBlock);
p.setVar("is_package", isPackage);

p.setLoop("years", mcal.getYears());
p.setLoop("types", m.arr2loop(course.types));
//p.setLoop("managers", user.getManagers(siteId, "C|S"));

p.setLoop("books", books);
p.setLoop("tutors", tutors);
p.setLoop("managers", managers);
p.setLoop("targets", targets);
p.setLoop("pcourses", pcourses);

p.setLoop("sale_yn", m.arr2loop(course.saleYn));
p.setLoop("display_yn", m.arr2loop(course.displayYn));
p.setLoop("taxfree_yn", m.arr2loop(course.taxfreeYn));
p.setLoop("status_list", m.arr2loop(course.statusList));
p.setVar("template_block", "Y".equals(siteconfig.s("cert_template_yn")));
p.setVar("playrate_block", usePlayrate);
p.setLoop("template_list", certificateTemplate.getList(siteId));
p.setLoop("pf_types", m.arr2loop(course.postfixType));
p.setLoop("pf_ord_list", m.arr2loop(course.postfixOrd));

p.setLoop("grades", m.arr2loop(course.grades));
p.setLoop("terms", m.arr2loop(course.terms));
p.setLoop("subjects", m.arr2loop(course.subjects));

p.setVar("closed", closed);
p.setVar("tab_modify", "current");
p.setVar("cid", id);
p.display();

%>