<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//객체
OrderDao order = new OrderDao();
OrderItemDao orderItem = new OrderItemDao();
RefundDao refund = new RefundDao();
NoticeDao notice = new NoticeDao();
NoticeLogDao noticeLog = new NoticeLogDao(siteId);
CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();
LmCategoryDao lmCategory = new LmCategoryDao("course");
BoardDao board = new BoardDao();
PostDao post = new PostDao();
PostLogDao postLog = new PostLogDao(siteId);
CategoryDao category = new CategoryDao();
ClBoardDao clBoard = new ClBoardDao();
ClPostDao clPost = new ClPostDao();
UserDao user = new UserDao();
UserOutDao userOut = new UserOutDao();
UserDeptDao userDept = new UserDeptDao();

//카테고리
DataSet categories = lmCategory.getList(siteId);

//변수
String today = m.time("yyyyMMdd");
String sdate = m.time("yyyyMM") + "01";
String edate = m.time("yyyyMM") + "31";

//목록-당월매출
DataSet statOrder = order.find(
	"order_date >= '" + sdate + "' AND order_date <= '" + edate + "' AND site_id = " + siteId + ""
	, "status, pay_price, refund_price"
);
int cntDone = 0; int sumDone = 0;
int cntWait = 0; int sumWait = 0;
int cntCancel = 0; int sumCancel = 0;
while(statOrder.next()) {
	if(statOrder.i("status") == 1 || statOrder.i("status") == 3) { //완료 또는 부분환불
		cntDone++;
		sumDone += statOrder.i("pay_price") - statOrder.i("refund_price");
	} else if(statOrder.i("status") == 2) { //대기
		cntWait++;
		sumWait += statOrder.i("pay_price");
	} else if(statOrder.i("status") == -2) { //취소
		cntCancel++;
		sumCancel += statOrder.i("pay_price");
	}
}

//목록-당월환불
Hashtable<String, Double> priceMap = new Hashtable<String, Double>();
Hashtable<String, Integer> countMap = new Hashtable<String, Integer>();
DataSet statRefund = refund.query(
	" SELECT SUM(a.refund_price) price, COUNT(*) cnt "
	+ " FROM " + refund.table + " a "
	+ " INNER JOIN " + order.table + " o ON a.order_id = o.id "
	+ " WHERE a.status = 2 AND a.refund_date >= '" + sdate + "000000' AND a.refund_date <= '" + edate + "235959' AND o.site_id = " + siteId + ""
);
while(statRefund.next()) {
	statRefund.put("cnt_conv", m.nf(statRefund.i("cnt")));
	statRefund.put("price_conv", m.nf(statRefund.i("price")));
}

//목록-과정통계
int totalCourseCnt = 0;
DataSet cstat = course.query(
	"SELECT onoff_type, COUNT(*) cnt "
	+ " FROM " + course.table + " "
	+ " WHERE status = 1 AND site_id = " + siteId + " "
	+ " GROUP BY onoff_type "
	+ " ORDER BY onoff_type DESC "
);
while(cstat.next()) {
	cstat.put("onoff_type_conv", m.getItem(cstat.s("onoff_type"), course.onoffPackageTypes));
	cstat.put("cnt_conv", m.nf(cstat.i("cnt")));
	totalCourseCnt += cstat.i("cnt");
}

//정보-수강현황
int openACourseCnt = 0;
int openRCourseCnt = 0;
int stopCourseCnt = 0;
int waitCourseCnt = 0;
int finishCourseCnt = 0;
DataSet allCourses = course.find("status = 1 AND site_id = " + siteId + " ", "course_type, study_sdate, study_edate, display_yn");
while(allCourses.next()) {
	if("R".equals(allCourses.s("course_type")) && (allCourses.i("study_sdate") > Integer.parseInt(m.time("yyyyMMdd")))) waitCourseCnt++;
	else if("R".equals(allCourses.s("course_type")) && (allCourses.i("study_edate") < Integer.parseInt(m.time("yyyyMMdd")))) finishCourseCnt++;
	else if("Y".equals(allCourses.s("display_yn")))
		if("R".equals(allCourses.s("course_type"))) openRCourseCnt++;
		else openACourseCnt++;
	else if("N".equals(allCourses.s("display_yn"))) stopCourseCnt++;
}

//목록-서비스공지
DataSet notices = notice.find("status = 1", "*", "id desc", 5);
while(notices.next()) {
	notices.put("category_conv", m.getItem(notices.s("category"), notice.categories));
	notices.put("subject_conv", m.cutString(notices.s("subject"), 150));
	notices.put("reg_date_conv", m.time("yyyy.MM.dd", notices.s("reg_date")));
	notices.put("new_block", m.diffDate("H", notices.s("reg_date"), m.time("yyyyMMddHHmmss")) <= newHour);
}
//notice.d(out);
DataSet ninfo = notice.query(
	" SELECT a.* "
	+ " FROM " + notice.table + " a "
	+ " WHERE a.status = 1 AND 1 > (SELECT COUNT(*) FROM " + noticeLog.table + " WHERE notice_id = a.id AND user_id = " + userId + ") "
	+ " AND a.reg_date >= '" + m.addDate("D", -7, today, "yyyyMMdd") + "000000' "
	+ " ORDER BY a.id DESC "
	+ " LIMIT 1 "
);
if(ninfo.next()) {
	ninfo.put("category_conv", m.getItem(ninfo.s("category"), notice.categories));
	ninfo.put("subject_conv", m.cutString(ninfo.s("subject"), 150));
	ninfo.put("reg_date_conv", m.time("yyyy.MM.dd", ninfo.s("reg_date")));
	ninfo.put("new_block", m.diffDate("H", ninfo.s("reg_date"), m.time("yyyyMMddHHmmss")) <= newHour);
}

//목록-QNA
//DataSet qnas = post.find(
	//"site_id = " + siteId + " AND status > -1 AND board_id = 10 AND depth = 'A'"
	//, "*", "thread asc, depth asc", 5
//);

DataSet qnas = post.query(
	" ( SELECT a.id, 0 course_user_id, a.user_id, a.writer, a.subject, a.secret_yn, a.proc_status, a.reg_date "
	+ " , b.id board_id, b.code, 0 course_id, b.board_nm, c.category_nm, u.login_id, pu.id assign_id, pu.user_nm assign_nm, pu.login_id assign_login_id "
	+ " FROM " + post.table + " a "
	+ " INNER JOIN " + board.table + " b ON a.board_id = b.id AND b.site_id = " + siteId + " AND b.board_type = 'qna' AND b.status != -1 "
	+ " LEFT JOIN " + category.table + " c ON a.category_id = c.id AND c.site_id = " + siteId + ""
	+ " LEFT JOIN " + user.table + " u ON a.user_id = u.id AND u.site_id = " + siteId + ""
	+ " LEFT JOIN " + postLog.table + " pl ON a.id = pl.post_id AND pl.log_type = 'assign' AND pl.site_id = " + siteId + " "
	+ " LEFT JOIN " + user.table + " pu ON pl.user_id = pu.id AND pu.site_id = " + siteId + " "
	+ " WHERE a.site_id = " + siteId + " AND a.status > -1 AND a.depth = 'A' ) "
	+ " UNION "
	+ " ( SELECT a.id, a.course_user_id, a.user_id, a.writer, a.subject, a.secret_yn, a.proc_status, a.reg_date "
	+ " , b.id board_id, b.code, b.course_id, c.course_nm board_nm, '' category_nm, u.login_id, 0 assign_id, '' assign_nm, '' assign_login_id "
	+ " FROM " + clPost.table + " a "
	+ " INNER JOIN " + clBoard.table + " b ON a.board_id = b.id AND b.site_id = " + siteId + " AND b.board_type = 'qna' "
	+ " INNER JOIN " + course.table + " c ON b.course_id = c.id AND c.site_id = " + siteId + " AND c.status != -1 "
	+ " LEFT JOIN " + user.table + " u ON a.user_id = u.id AND u.site_id = " + siteId + ""
	+ " WHERE a.site_id = " + siteId + " AND a.status > -1 AND a.depth = 'A' ) "
	+ " ORDER BY proc_status asc, reg_date desc "
	, 20
);

while(qnas.next()) {
	qnas.put("reg_date_conv", m.time("yyyy.MM.dd", qnas.s("reg_date")));
	qnas.put("proc_status_conv", m.getItem(qnas.s("proc_status"), post.procStatusList));
	qnas.put("new_block", m.diffDate("H", qnas.s("reg_date"), m.time("yyyyMMddHHmmss")) <= newHour);
}

//목록-수강신청기간인과정
DataSet requestCourses = course.query(
	"SELECT a.*, (SELECT COUNT(*) FROM " + courseUser.table + " WHERE course_id = a.id AND status IN (0,1,2,3)) user_cnt FROM " + course.table + " a "
	+ " WHERE status = 1 AND display_yn = 'Y' AND site_id = " + siteId + " AND request_sdate <= " + today + " AND request_edate >= " + today + " "
	+ " ORDER BY request_sdate DESC, reg_date DESC "
	+ " LIMIT 0, 10 "
);
while(requestCourses.next()) {
	requestCourses.put("cate_name", lmCategory.getTreeNames(requestCourses.i("category_id")));
	requestCourses.put("onoff_type_conv", m.getItem(requestCourses.s("onoff_type"), course.onoffPackageTypes));
	requestCourses.put("request_sdate_conv", m.time("yyyy.MM.dd", requestCourses.s("request_sdate")));
	requestCourses.put("request_edate_conv", m.time("yyyy.MM.dd", requestCourses.s("request_edate")));
	requestCourses.put("user_cnt_conv", m.nf(requestCourses.i("user_cnt")));
}

//목록-학습기간인과정
DataSet studyCourses = course.query(
	"SELECT a.*, (SELECT COUNT(*) FROM " + courseUser.table + " WHERE course_id = a.id AND status IN (1,3)) user_cnt FROM " + course.table + " a "
	+ " WHERE status = 1 AND display_yn = 'Y' AND site_id = " + siteId + " AND study_sdate <= " + today + " AND study_edate >= " + today + " "
	+ " ORDER BY study_sdate DESC, reg_date DESC "
	+ " LIMIT 0, 10 "
);
while(studyCourses.next()) {
	studyCourses.put("cate_name", lmCategory.getTreeNames(studyCourses.i("category_id")));
	studyCourses.put("onoff_type_conv", m.getItem(studyCourses.s("onoff_type"), course.onoffPackageTypes));
	studyCourses.put("study_sdate_conv", m.time("yyyy.MM.dd", studyCourses.s("study_sdate")));
	studyCourses.put("study_edate_conv", m.time("yyyy.MM.dd", studyCourses.s("study_edate")));
	studyCourses.put("user_cnt_conv", m.nf(studyCourses.i("user_cnt")));
}

//변수-승인대기
int confirmCnt = courseUser.getOneInt(
	" SELECT COUNT(*) "
	+ " FROM " + courseUser.table + " a "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id AND u.status != -1 "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id "
	+ " WHERE a.site_id = " + siteId + " AND a.status = 0 "
	+ (courseManagerBlock ? " AND a.course_id IN (" + manageCourses + ")" : "")
	+ (deptManagerBlock ? " AND u.dept_id IN (" + userDept.getSubIdx(siteId, userDeptId) + ")" : "")
);
//변수-입금대기
int depositCnt = order.findCount("site_id = " + siteId + " AND status = 2 AND paymethod = '90'");
//변수-환불요청
int refundCnt = refund.findCount("site_id = " + siteId + " AND status = 1");
/*
int depositCnt = courseUser.getOneInt(
	" SELECT COUNT(*) "
	+ " FROM " + courseUser.table + " a "
	+ " INNER JOIN " + user.table + " u ON a.user_id = u.id "
	+ " INNER JOIN " + course.table + " c ON a.course_id = c.id "
	+ " LEFT JOIN " + order.table + " o ON a.order_id = o.id "
	+ " WHERE a.site_id = " + siteId + " AND a.status = 2 AND o.paymethod = '90' "
);
*/
//변수-배송대기
int deliveryCnt = order.getOneInt(
	" SELECT COUNT(*) "
	+ " FROM " + order.table + " a "
	+ " WHERE a.site_id = " + siteId + " AND a.status = 1 AND a.delivery_status IN (0, 2) "
	+ " AND EXISTS (SELECT 1 FROM " + orderItem.table + " WHERE order_id = a.id AND product_type = 'book') "
);
//변수-탈퇴승인
int userOutCnt = userOut.findCount("site_id = " + siteId + " AND (out_date IS NULL OR out_date = '')");

//포맷팅-사이트정보
DataSet master = new DataSet();
if(isUserMaster) {
	//폼입력
	master.addRow();
	master.put("site_status_conv", m.getItem(siteinfo.s("status"), Site.statusList));
	master.put("is_prepare", "Y".equals(SiteConfig.s("prepare_yn")));
	
	f.addElement("open_yn", !"Y".equals(SiteConfig.s("prepare_yn")) ? "Y" : "", "hname:'사이트 준비중 여부', required:'Y'");
	f.addElement("master-slogin", siteId, "hname:'고객사 이동'");

	//객체
	SiteDao site = new SiteDao();
	UserSiteDao userSite = new UserSiteDao();

	//목록-고객사
	DataSet sites = userSite.query(
		" SELECT s.id, s.site_nm, s.company_nm, s.domain, s.sysop_status, s.status "
		+ " FROM " + userSite.table + " a "
		+ " INNER JOIN " + site.table + " s ON a.site_id = s.id AND s.sysop_status = 1 AND s.status != -1 "
		+ " WHERE a.user_id = " + userId
	);
	while(sites.next()) {
		sites.put("name_equal_block", sites.s("site_nm").equals(sites.s("company_nm")));
	}

	//출력
	p.setLoop("sites", sites);
}

//출력
p.setLayout(ch);
p.setBody("main.index");
p.setVar("p_title", "운영현황");
p.setVar("query", m.qs());
p.setVar("form_script", f.getScript());

p.setVar("notice_block", 0 < ninfo.size());
p.setVar("notice", ninfo);

p.setVar("today", m.time("yyyy-MM-dd"));
p.setVar("sdate", sdate);
p.setVar("edate", edate);

p.setVar("cnt_done", m.nf(cntDone));
p.setVar("sum_done", m.nf(sumDone));
p.setVar("cnt_wait", m.nf(cntWait));
p.setVar("sum_wait", m.nf(sumWait));
p.setVar("cnt_cancel", m.nf(cntCancel));
p.setVar("sum_cancel", m.nf(sumCancel));
p.setVar("stat_refund", statRefund);

p.setVar("total_course_cnt", m.nf(totalCourseCnt));
p.setVar("open_course_cnt", m.nf(openACourseCnt + openRCourseCnt));
p.setVar("open_a_course_cnt", m.nf(openACourseCnt));
p.setVar("open_r_course_cnt", m.nf(openRCourseCnt));
p.setVar("stop_course_cnt", m.nf(stopCourseCnt));
p.setVar("wait_course_cnt", m.nf(waitCourseCnt));
p.setVar("finish_course_cnt", m.nf(finishCourseCnt));
p.setLoop("notices", notices);
p.setLoop("qnas", qnas);
p.setLoop("request_courses", requestCourses);
p.setLoop("study_courses", studyCourses);
p.setVar("qnas_size", qnas.size());
p.setVar("request_courses_size", requestCourses.size());
p.setVar("study_courses_size", studyCourses.size());

p.setVar("confirm_cnt_conv", m.nf(confirmCnt));
p.setVar("deposit_cnt_conv", m.nf(depositCnt));
p.setVar("refund_cnt_conv", m.nf(refundCnt));
p.setVar("delivery_cnt_conv", m.nf(deliveryCnt));
p.setVar("user_out_cnt_conv", m.nf(userOutCnt));

p.setVar("master_info", master);

p.display();

%>