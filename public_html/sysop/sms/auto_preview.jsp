<%@ page contentType="text/html; charset=utf-8" %><%@ include file="init.jsp" %><%

//접근권한
if(!Menu.accessible(42, userId, userKind)) { m.jsError("접근 권한이 없습니다."); return; }

//기본키
int id = m.ri("id");
if(id == 0) { m.jsError("기본키는 반드시 지정해야 합니다."); return; }

//객체
SendAutoDao sendAuto = new SendAutoDao();
CourseAutoDao courseAuto = new CourseAutoDao();

CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();

UserDao user = new UserDao();
UserDeptDao userDept = new UserDeptDao();

MailDao mail = new MailDao();

ExamUserDao examUser = new ExamUserDao();
HomeworkUserDao homeworkUser = new HomeworkUserDao();

//정보
DataSet info = sendAuto.find("id = " + id + " AND status != -1 AND site_id = " + siteId + "");
if(!info.next()) { m.jsError("해당 정보가 없습니다."); return; }

//폼입력
String sday = !"".equals(m.rs("s_day")) ? m.time("yyyy-MM-dd", m.rs("s_day")) : m.time("yyyy-MM-dd");
String today = m.time("yyyyMMdd", sday);

StringBuilder sb = new StringBuilder();
sb.append("SELECT a.id, a.user_id, a.course_id, a.start_date, a.end_date, a.complete_yn ");
sb.append(", a.progress_ratio, a.progress_score, a.exam_score, a.homework_score, a.forum_score, a.etc_score, a.total_score ");
sb.append(", b.course_nm, b.year, b.step, b.limit_progress, b.limit_exam, b.limit_homework, b.limit_forum, b.limit_etc, b.limit_total_score, b.assign_progress, b.assign_exam, b.assign_homework, b.assign_forum, b.assign_etc, b.credit ");
sb.append(", u.user_nm, u.login_id, u.email, u.mobile, d.dept_nm ");

sb.append(", ( CASE WHEN ( EXISTS (SELECT 1 FROM " + examUser.table + " WHERE course_user_id = a.id AND submit_yn = 'Y') ) THEN 'Y' ELSE 'N' END ) exam_submit_yn ");
sb.append(", ( CASE WHEN ( EXISTS (SELECT 1 FROM " + examUser.table + " WHERE course_user_id = a.id AND submit_yn = 'Y' AND confirm_yn = 'Y') ) THEN 'Y' ELSE 'N' END ) exam_confirm_yn ");
sb.append(", ( CASE WHEN ( EXISTS (SELECT 1 FROM " + homeworkUser.table + " WHERE course_user_id = a.id AND submit_yn = 'Y' AND status != -1) ) THEN 'Y' ELSE 'N' END ) homework_submit_yn ");
sb.append(", ( CASE WHEN ( EXISTS (SELECT 1 FROM " + homeworkUser.table + " WHERE course_user_id = a.id AND submit_yn = 'Y' AND confirm_yn = 'Y' AND status != -1) ) THEN 'Y' ELSE 'N' END ) homework_confirm_yn ");

sb.append(" FROM " + courseUser.table + " a ");
sb.append(" INNER JOIN " + course.table + " b ON b.id = a.course_id AND b.status = 1 AND b.site_id = " + siteId);
sb.append(" INNER JOIN " + user.table +  " u ON u.id = a.user_id AND u.status = 1 AND u.site_id = " + siteId);
sb.append(" LEFT JOIN " + userDept.table + " d ON d.id = u.dept_id AND d.status = 1 AND d.site_id = " + siteId);

sb.append(" WHERE a.status = 1 AND a.site_id = " + siteId);
sb.append(" AND EXISTS (SELECT 1 FROM " + courseAuto.table + " WHERE site_id = " + siteId + " AND course_id = b.id AND auto_id = " + id + " ) ");

//기준일
String stdDate = m.addDate("D", info.i("std_day") * -1, today, "yyyyMMdd");
if("S".equals(info.s("std_type"))) sb.append(" AND a.start_date = '" + stdDate + "' ");
else sb.append(" AND a.end_date = '" + stdDate + "' ");

//과제
if("Y".equals(info.s("homework_yn"))) {
	sb.append(" AND EXISTS (SELECT 1 FROM " + homeworkUser.table + " WHERE course_user_id = a.id AND submit_yn = 'Y' AND status != -1) ");
} else if("N".equals(info.s("homework_yn"))) {
	sb.append(" AND NOT EXISTS (SELECT 1 FROM " + homeworkUser.table + " WHERE course_user_id = a.id AND submit_yn = 'Y' AND status != -1) ");
}

//시험
if("Y".equals(info.s("exam_yn"))) {
	sb.append(" AND EXISTS (SELECT 1 FROM " + examUser.table + " WHERE course_user_id = a.id AND submit_yn = 'Y') ");
} else if("N".equals(info.s("exam_yn"))) {
	sb.append(" AND NOT EXISTS (SELECT 1 FROM " + examUser.table + " WHERE course_user_id = a.id AND submit_yn = 'Y') ");
}

//진도율
if(info.d("min_ratio") > 0.00) sb.append(" AND a.progress_ratio >= " + info.d("min_ratio") + " ");
if(info.d("max_ratio") > 0.00) sb.append(" AND a.progress_ratio <= " + info.d("max_ratio") + " ");

//목록
DataSet list = courseUser.query(sb.toString());
while(list.next()) {

	list.put("progress_ratio_conv", m.nf(list.d("progress_ratio"),2));
	list.put("progress_score_conv", m.nf(list.d("progress_score"), 2));
	list.put("exam_score_conv", m.nf(list.d("exam_score"),2));
	list.put("homework_score_conv", m.nf(list.d("homework_score"),2));
	list.put("total_score_conv", m.nf(list.d("total_score"),2));
	list.put("forum_score_conv", m.nf(list.d("forum_score"), 2));
	list.put("etc_score_conv", m.nf(list.d("etc_score"), 2));
	list.put("mobile_conv", !"".equals(list.s("mobile")) ? SimpleAES.decrypt(list.s("mobile")) : "" );

	list.put("start_date", m.time("yyyy.MM.dd", list.s("start_date") + "000000"));
	list.put("start_date_conv", list.s("start_date"));
	list.put("end_date", m.time("yyyy.MM.dd", list.s("end_date") + "235959"));
	list.put("end_date_conv", list.s("end_date"));

	list.put("complete_yn_conv", list.b("complete_yn") ? "수료" : "-");
	list.put("close_conv", list.b("close_yn") ? "마감" : "미마감");

	list.put("email_content", "");
	list.put("sms_content", "");

	list.put("domain", siteinfo.s("domain"));
	list.put("site_nm", siteinfo.s("site_nm"));
	list.put("logo_url", siteinfo.s("logo_url"));
	list.put("company_nm", siteinfo.s("company_nm"));
	list.put("receive_email", siteinfo.s("receive_email"));
	list.put("new_addr", siteinfo.s("new_addr"));
	list.put("zipcode", siteinfo.s("zipcode"));


	DataSet uinfo = new DataSet(); uinfo.addRow();
	if(info.b("sms_yn")) {
		String mobile = list.s("mobile_conv");

		if(sms.isMobile(mobile)) {
			uinfo.put("id", list.i("user_id"));
			uinfo.put("mobile", mobile);
			uinfo.put("user_nm", list.s("user_nm"));
			p.clear();
			p.setVar(list);

			String content = p.fetchString(info.s("sms_content"));

			list.put("sms_content", content);
		}
	}

	if(info.b("email_yn")) {
		String email = list.s("email");
		if(mail.isMail(email)) {
			String subject = info.s("subject");
			if("".equals(siteinfo.s("site_email"))) siteinfo.put("site_email", "webmaster@" + siteinfo.s("domain"));
			m.mailFrom = siteinfo.s("site_email");

			p.clear();
			p.setRoot(siteinfo.s("doc_root") + "/html");
			p.setLayout("auto");
			p.setVar("subject", subject);

			uinfo.put("id", list.i("user_id"));
			uinfo.put("email", email);
			uinfo.put("user_nm", list.s("user_nm"));
			p.setVar(list);
			p.setVar("domain", siteinfo.s("domain"));;

			String mbody = p.fetchString(info.s("email_content"));
			p.setVar("MBODY", mbody);

			String content = p.fetchAll();

			list.put("email_content", content);
		}
	}
}

//폼체크
f.addElement("s_day", sday, null);

//출력
p.clear();
p.setRoot(tplRoot);
p.setLayout("pop");
p.setBody("sms.auto_preview");
p.setVar("p_title", "학습독려 결과 미리보기");
p.setVar("query", m.qs());
p.setVar("list_query", m.qs("id"));
p.setVar("form_script", f.getScript());

p.setVar(info);
p.setLoop("list", list);

p.setVar("IS_AUTH_CRM", superBlock || Menu.accessible(-999, userId, userKind, false));

p.display(out);

%>