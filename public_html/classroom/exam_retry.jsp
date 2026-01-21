<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//기본키
int eid = m.ri("eid");
if(eid == 0 || !m.encrypt("" + cuid + eid).equals(m.rs("ek"))) { m.jsErrClose(_message.get("alert.common.abnormal_access")); return; }

//객체
ExamDao exam = new ExamDao();
ExamUserDao examUser = new ExamUserDao();
CourseProgressDao courseProgress = new CourseProgressDao();

QuestionDao question = new QuestionDao();
ExamResultDao examResult = new ExamResultDao();

//정보-시험
//courseModule.d(out);
DataSet info = courseModule.query(
	"SELECT a.*, e.exam_nm, e.exam_time, e.question_cnt, e.onoff_type "
	+ ", u.submit_yn, u.marking_score, u.confirm_yn , u.apply_cnt"
	+ " FROM " + courseModule.table + " a "
	+ " INNER JOIN " + exam.table + " e ON a.module_id = e.id AND e.status != -1 AND e.id = " + eid + " "
	+ " INNER JOIN " + examUser.table + " u ON "
		+ "u.exam_id = a.module_id AND u.course_user_id = " + cuid + " AND u.exam_step = 1 "
	+ " WHERE a.status = 1 AND a.module = 'exam' "
	+ " AND a.course_id = " + courseId + " AND e.site_id = " + siteId + ""
);
if(!info.next()) { m.jsErrClose(_message.get("alert.common.nodata")); return; };

//포맷팅
boolean isReady = false; //대기
boolean isEnd = false; //완료
boolean isPeriodApply = "1".equals(info.s("apply_type"));
if("1".equals(info.s("apply_type"))) { //기간
	// 왜: end_date를 99991231235959 같은 "아주 먼 미래"로 두는 환경에서는,
	//     diffDate("I") 내부에서 int 오버플로우가 나 종료로 잘못 판정되는 경우가 있습니다.
	//     그래서 yyyyMMddHHmmss 값을 숫자로 비교해 안전하게 판단합니다.
	long nowDateTime = m.parseLong(now);
	long startDateTime = m.parseLong(info.s("start_date"));
	long endDateTime = m.parseLong(info.s("end_date"));
	isReady = startDateTime > 0 && startDateTime > nowDateTime;
	isEnd = endDateTime > 0 && endDateTime < nowDateTime;
} else if("2".equals(info.s("apply_type"))) { //차시
	//if(info.i("chapter") > 0 && 0 == courseProgress.findCount("course_id = " + courseId + " AND chapter = " + info.i("chapter") + " AND course_user_id = " + cuid + " AND complete_yn = 'Y'")) isReady = true;
	if(info.i("chapter") > 0 && courseProgress.getExamReadyFlag(cuid, courseId, info.i("chapter"))) isReady = true;
}

// 왜: 기간형 시험(apply_type=1)은 "시험기간"이 곧 재응시 가능 조건이므로,
//     수강상태(progress)가 W/E/R로 남아 있더라도(특히 학사/매핑 과정) 시험기간 내면 재응시를 허용합니다.
//     (단, 차시형(apply_type=2)은 수강중(I)일 때만 재응시 가능하게 유지합니다.)
boolean canOpenByProgress = isPeriodApply ? true : "I".equals(progress);
if(!isReady && !isEnd
	&& canOpenByProgress
	&& info.b("confirm_yn") 
	&& info.b("submit_yn") 
	&& "N".equals(info.s("onoff_type")) 
	&& info.b("retry_yn")
	&& info.d("marking_score") < info.d("retry_score")
	&& info.i("apply_cnt") <= info.i("retry_cnt")
) {

	//삭제-결과
	if(!examResult.delete("exam_id = " + eid + " AND course_user_id = " + cuid + "")) {
		m.jsErrClose(_message.get("alert.classroom.error_retry")); return;
	}

	//삭제
	if(!examUser.delete("exam_id = " + eid + " AND course_user_id = " + cuid + "")) {
		m.jsErrClose(_message.get("alert.classroom.error_retry")); return;
	}

	//점수 업데이트
	courseUser.setCourseUserScore(cuid, "exam");

	m.js("try { opener.location.href = opener.location.href; } catch(e) {}");

	//등록
	examUser.item("exam_id", eid);
	examUser.item("course_user_id", cuid);
	examUser.item("exam_step", 1);
	examUser.item("course_id", courseId);
	examUser.item("user_id", userId);
	examUser.item("site_id", siteId);
	examUser.item("choice_yn", "Y");
	examUser.item("score", 0);
	examUser.item("marking_score", 0);
	examUser.item("feedback", "");
	examUser.item("duration", 0);
	examUser.item("ba_cnt", 0);
	// 왜: 응시 기록 재생성(재시험) 시에도 기본값이 NULL이면 화면 JS가 깨질 수 있어 0으로 초기화합니다.
	examUser.item("blur_cnt", 0);
	examUser.item("submit_yn", "N");
	examUser.item("confirm_yn", "N");
	examUser.item("confirm_date", "");
	examUser.item("submit_date", "");
	examUser.item("apply_cnt", info.i("apply_cnt") + 1);
	examUser.item("apply_date", now);
	examUser.item("onload_date", "");
	examUser.item("unload_date", "");
	examUser.item("ip_addr", "");
	examUser.item("mod_date", now);
	examUser.item("reg_date", now);
	examUser.item("status", 0);
	if(!examUser.insert()) { m.jsErrClose(_message.get("alert.classroom.error_retry")); return; }
	

	m.jsReplace("exam_apply.jsp?" + m.qs());

	
} else {
	 m.jsErrClose(_message.get("alert.common.abnormal_access")); return;
}

%>
