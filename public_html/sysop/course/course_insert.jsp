<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(33, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }
if(!adminBlock) { m.jsError("접근 권한이 없습니다."); return; }

//객체
CourseDao course = new CourseDao();
LmCategoryDao category = new LmCategoryDao("course");
CourseModuleDao courseModule = new CourseModuleDao();

CourseBookDao courseBook = new CourseBookDao();
CourseTutorDao courseTutor = new CourseTutorDao();
CourseTargetDao courseTarget = new CourseTargetDao();
CertificateTemplateDao certificateTemplate = new CertificateTemplateDao();

BookDao book = new BookDao();
UserDao user = new UserDao();
TutorDao tutor = new TutorDao();
GroupDao group = new GroupDao();

MCal mcal = new MCal(); mcal.yearRange = 10;
DataSet siteconfig = SiteConfig.getArr(new String[] {"cert_template_yn"});

//폼체크
f.addElement("onoff_type", "N", "hname:'과정 구분', required:'Y'");
f.addElement("category_id", null, "hname:'카테고리', required:'Y'");

f.addElement("course_nm", null, "hname:'과정명', required:'Y'");
f.addElement("course_type", "A", "hname:'과정구분', required:'Y'");
f.addElement("year", null, "hname:'년도', required:'Y'");
//f.addElement("step", 1, "hname:'기수', required:'Y', option:'number'");

//f.addElement("grade", "H1", "hname:'학년', required:'Y'");
//f.addElement("term", "1T", "hname:'학기', required:'Y'");
//f.addElement("subject", "K", "hname:'과목', required:'Y'");

f.addElement("request_sdate", null, "hname:'수강신청시작일'");
f.addElement("request_edate", null, "hname:'수강신청종료일'");
f.addElement("study_sdate", null, "hname:'학습시작일'");
f.addElement("study_edate", null, "hname:'학습종료일'");
f.addElement("lesson_day", 30, "hname:'학습일수', option:'number', min:'1'");
f.addElement("course_file", null, "hname:'메인이미지', allow:'jpg|jpeg|gif|png'");
f.addElement("list_price", 0, "hname:'정가', option:'number', required:'Y'");
f.addElement("price", 0, "hname:'수강료', option:'number', required:'Y'");
f.addElement("taxfree_yn", "N", "hname:'부가세면세여부'");
f.addElement("disc_group_yn", "Y", "hname:'그룹할인적용여부'");
f.addElement("memo_yn", "N", "hname:'주문메모 사용여부'");
f.addElement("renew_yn", "N", "hname:'수강기간 연장결제 사용여부'");
f.addElement("renew_max_cnt", 0, "hname:'최대 연장횟수', option:'number', min:'0', max:'999'");
f.addElement("renew_price", 0, "hname:'연장비용', option:'number', min:'0'");
f.addElement("credit", 0, "hname:'학점', required:'Y'");
f.addElement("lesson_time", 1, "hname:'시수', min:'0.01', required:'Y'");
f.addElement("mobile_yn", "Y", "hname:'모바일 지원여부'");
//f.addElement("evaluation_yn", "N", "hname:'수료기준 노출여부'");
//f.addElement("top_yn", "N", "hname:'상시 상위고정'");
f.addElement("recomm_yn", null, "hname:'추천과정'");
f.addElement("pass_yn", "N", "hname:'합격 상태 사용여부'");
f.addElement("cert_template_id", 0, "hname:'수료증 템플릿'");
f.addElement("pass_cert_template_id", 0, "hname:'합격증 템플릿'");

f.addElement("subtitle", null, "hname:'과정목록 소개문구'");
f.addElement("content1", null, "hname:'텍스트1', allowiframe:'Y', allowhtml:'Y'");
f.addElement("content2", null, "hname:'텍스트2', allowiframe:'Y'");
f.addElement("content1_title", "과정소개", "hname:'텍스트1 타이틀'");
f.addElement("content2_title", "학습목표", "hname:'텍스트2 타이틀'");

f.addElement("etc1", null, "hname:'기타1'");
f.addElement("etc2", null, "hname:'기타2'");
//f.addElement("status", 1, "hname:'상태', required:'Y'");

//등록
if(m.isPost() && f.validate()) {

	//제한
	/*
	if(0 < course.findCount(
			"site_id = " + siteId + " AND subject_id = " + f.getInt("subject_id") + " "
			+ " AND year = " + f.getInt("year") + " AND step = " + f.getInt("step") + ""
			+ " AND status != -1 "
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
		m.jsAlert("이미지는 첨부파일 기능으로 업로드 해 주세요.");
		return;
	}
	if(500 < bytest) { m.jsAlert("과정목록 소개문구 내용은 500바이트를 초과해 작성하실 수 없습니다.\\n(현재 " + bytest + "바이트)"); return; }
	if(60000 < bytes1) { m.jsAlert(f.get("content1_title") + " 내용은 60000바이트를 초과해 작성하실 수 없습니다.\\n(현재 " + bytes1 + "바이트)"); return; }
	if(60000 < bytes2) { m.jsAlert(f.get("content2_title") + " 내용은 60000바이트를 초과해 작성하실 수 없습니다.\\n(현재 " + bytes2 + "바이트)"); return; }

	//과정
	int newId = course.getSequence();
	course.item("id", newId);
	course.item("site_id", siteId);
	course.item("course_nm", f.get("course_nm"));
	course.item("category_id", f.getInt("category_id"));
	course.item("year", f.get("year", m.time("yyyy")));
	course.item("step", f.get("step", "1"));

	course.item("grade", f.get("grade", "H1"));
	course.item("term", f.get("term", "1T"));
	course.item("subject", f.get("subject", "K"));

	course.item("onoff_type", f.get("onoff_type"));
	course.item("course_type", f.get("course_type"));

	if("R".equals(f.get("course_type"))) { //정규
		course.item("request_sdate", m.time("yyyyMMdd", f.get("request_sdate")));
		course.item("request_edate", m.time("yyyyMMdd", f.get("request_edate")));
		course.item("study_sdate", m.time("yyyyMMdd", f.get("study_sdate")));
		course.item("study_edate", m.time("yyyyMMdd", f.get("study_edate")));
		course.item("renew_price", 0);
		course.item("renew_max_cnt", 0);
		course.item("renew_yn", "N");
	} else if("A".equals(f.get("course_type"))) { //상시
		course.item("request_sdate", "");
		course.item("request_edate", "");
		course.item("study_sdate", "");
		course.item("study_edate", "");
		course.item("renew_price", f.getInt("renew_price"));
		course.item("renew_max_cnt", f.getInt("renew_max_cnt"));
		course.item("renew_yn", f.get("renew_yn", "N"));
	}
	
	if("P".equals(f.get("onoff_type"))) {
		course.item("study_sdate", "");
		course.item("study_edate", "");
		course.item("renew_price", 0);
		course.item("renew_max_cnt", 0);
		course.item("renew_yn", "N");
	}

	course.item("lesson_day", f.getInt("lesson_day"));
	course.item("lesson_time", f.getDouble("lesson_time"));
	course.item("pass_yn", f.get("pass_yn", "N"));

	boolean isUpload = false;
	if(null != f.getFileName("course_file")) {
		File f1 = f.saveFile("course_file");
		if(f1 != null) {
			course.item("course_file", f.getFileName("course_file"));
			isUpload = true;
		}
	}

	course.item("list_price", f.getInt("list_price"));
	course.item("price", f.getInt("price"));
	course.item("taxfree_yn", f.get("taxfree_yn", "N"));
	course.item("disc_group_yn", f.get("disc_group_yn", "Y"));
	course.item("memo_yn", f.get("memo_yn", "N"));

	course.item("credit", f.getInt("credit"));
	course.item("mobile_yn", f.get("mobile_yn", "N"));
	course.item("evaluation_yn", "N");
	//course.item("top_yn", f.get("top_yn", "N"));

	course.item("recomm_yn", f.get("recomm_yn", "N"));
	course.item("auto_approve_yn", "Y");
	course.item("sms_yn", "N");
	course.item("target_yn", "N");
	course.item("complete_auto_yn", "N");
	course.item("restudy_yn", "N");
	course.item("restudy_day", 0);

	course.item("limit_lesson_yn", "N");
	course.item("limit_lesson", 0);
	course.item("limit_people_yn", "N");
	course.item("limit_people", 0);
	course.item("limit_ratio_yn", "N");
	course.item("limit_ratio", 0);
	course.item("limit_seek_yn", "N");

	course.item("period_yn", !"N".equals(f.get("onoff_type")) ? "Y" : "N");
	course.item("lesson_order_yn", "N");

	course.item("assign_progress", 100);
	course.item("assign_exam", 0);
	course.item("assign_homework", 0);
	course.item("assign_forum", 0);
	course.item("assign_etc", 0);
	course.item("assign_survey_yn", "N");
	course.item("limit_progress", 60);
	course.item("limit_exam", 0);
	course.item("limit_homework", 0);
	course.item("limit_forum", 0);
	course.item("limit_etc", 0);
	course.item("limit_total_score", 60);
	course.item("complete_limit_progress", 60);
	course.item("complete_limit_total_score", 60);
	course.item("class_member", 40); //고정

    course.item("push_survey_yn", "N");

	course.item("sample_lesson_id", 0);
	course.item("before_course_id", 0);

	course.item("subtitle", subtitle);
	course.item("content1_title", f.get("content1_title"));
	course.item("content1", content1);
	course.item("content2_title", f.get("content2_title"));
	course.item("content2", content2);

	course.item("exam_yn", "Y");
	course.item("homework_yn", "Y");
	course.item("forum_yn", "Y");
	course.item("survey_yn", "Y");
	course.item("review_yn", "Y");
	course.item("cert_course_yn", "N");
	course.item("cert_complete_yn", "Y");
	course.item("cert_template_id", f.getInt("cert_template_id"));
	course.item("pass_cert_template_id", f.getInt("pass_cert_template_id"));

	course.item("etc1", f.get("etc1"));
	course.item("etc2", f.get("etc2"));

	course.item("display_yn", "N");
	course.item("sale_yn", "N");
	course.item("reg_date", m.time("yyyyMMddHHmmss"));
	course.item("status", 1);

	if(!course.insert()) { m.jsAlert("등록하는 중 오류가 발생했습니다."); return; }


	//과정게시판
	ClBoardDao board = new ClBoardDao(siteId);
	if(!board.insertBoard(newId)) { }

	//파일리사이징
	if(isUpload) {
		try {
			String imgPath = m.getUploadPath(f.getFileName("course_file"));
			String cmd = "convert -resize 1000x " + imgPath + " " + imgPath;
			Runtime.getRuntime().exec(cmd);
		}
		catch(RuntimeException re) { m.errorLog("RuntimeException : " + re.getMessage(), re); }
		catch(Exception e) { m.errorLog("Exception : " + e.getMessage(), e); }
	}

	m.jsAlert(
		"성공적으로 등록했습니다. "
		+ "\\n현재 [노출 숨김 및 판매 중지] 상태입니다. "
		+ "\\n운영정보/강의목차/평가정보를 반드시 확인하시고 정상상태로 변경하시길 바랍니다."
	);

	m.jsReplace("course_modify.jsp?id=" + newId, "parent");
	return;
}

//출력
p.setBody("course.course_insert");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());
p.setVar("pass_yn", f.get("pass_yn", "N"));

p.setLoop("status_list", m.arr2loop(course.statusList));
p.setLoop("taxfree_yn", m.arr2loop(course.taxfreeYn));

p.setLoop("years", mcal.getYears());
p.setLoop("types", m.arr2loop(course.types));
p.setLoop("onoff_types", m.arr2loop(course.onoffTypes));

p.setLoop("grades", m.arr2loop(course.grades));
p.setLoop("terms", m.arr2loop(course.terms));
p.setLoop("subjects", m.arr2loop(course.subjects));

p.setVar("year", m.time("yyyy"));
p.setVar("template_block", "Y".equals(siteconfig.s("cert_template_yn")));
p.setLoop("template_list", certificateTemplate.getList(siteId, "C"));
p.setLoop("pass_template_list", certificateTemplate.getList(siteId, "P"));

p.display();

%>
