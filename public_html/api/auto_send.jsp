<%@ page contentType="text/html; charset=utf-8" %><%@ include file="../init.jsp" %><%

//폼입력
String mode = m.rs("mode");
String today = !"".equals(m.rs("today")) ? m.rs("today") : m.time("yyyyMMdd");
int aid = m.ri("aid");
String groupCd = m.rs("gcd");

//gcd가 있는 경우 -> 스케쥴러에서 호출
//aid가 있는 경우 -> 수동 독려 실행버튼
//if("".equals(groupCd) && 0 == aid) { return; }

//변수
boolean isTest = "test".equals(mode);
boolean isExec = "exec".equals(mode);
String now = m.time("yyyyMMddHHmmss");

//객체
SendAutoDao sendAuto = new SendAutoDao();
CourseAutoDao courseAuto = new CourseAutoDao();

CourseDao course = new CourseDao();
CourseUserDao courseUser = new CourseUserDao();

UserDao user = new UserDao();
UserDeptDao userDept = new UserDeptDao();

SmsDao sms = new SmsDao();
SmsUserDao smsUser = new SmsUserDao();
MailDao mail = new MailDao();
MailUserDao mailUser = new MailUserDao();

ExamUserDao examUser = new ExamUserDao();
HomeworkUserDao homeworkUser = new HomeworkUserDao();

SiteDao site = new SiteDao();

//로그
StringBuffer _l = new StringBuffer();
_l.append("---------- 실행시간 : " + m.time("yyyy.MM.dd HH:mm:ss") + " ----------");

//목록
sendAuto.d(out);
DataSet list = sendAuto.query(
    " SELECT a.*, "
    +" s.sms_yn ssms_yn, s.site_nm, s.site_email, s.sms_sender, s.sms_id, s.sms_pw, s.domain, s.doc_root, s.auto_group_cd, s.company_nm, s.receive_email, s.new_addr, s.zipcode, s.logo "
    + " FROM " + sendAuto.table + " a "
    + " INNER JOIN " + site.table + " s ON a.site_id = s.id AND s.status = 1 "
    + " WHERE " + (aid > 0 ? "a.id = " + aid + " AND a.status != -1 " : " a.status = 1 ")
//    + (!"".equals(groupCd) ? " AND s.auto_group_cd = '" + groupCd + "'" : "")
    + " AND EXISTS ( SELECT 1 FROM " + courseAuto.table + " WHERE auto_id = a.id AND site_id = a.site_id ) "
    + " ORDER BY a.id ASC"
);

_l.append("\n자동설정 수 : " + list.size() + " 건");
if(isTest) m.p("자동설정 수 : " + list.size() + " 건");
while(list.next()) {

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
    sb.append(" INNER JOIN " + course.table + " b ON b.id = a.course_id AND b.status = 1 ");
    sb.append(" INNER JOIN " + courseAuto.table + " c ON c.course_id = b.id AND c.site_id = b.site_id AND c.auto_id = " + list.i("id"));
    sb.append(" INNER JOIN " + user.table +  " u ON u.id = a.user_id AND u.status = 1 ");
    sb.append(" LEFT JOIN " + userDept.table + " d ON d.id = u.dept_id AND d.status = 1 ");
    sb.append(" WHERE a.status = 1 ");

    //기준일
    String stdDate = m.addDate("D", list.i("std_day") * -1, today, "yyyyMMdd");
    if("S".equals(list.s("std_type"))) sb.append(" AND a.start_date = '" + stdDate + "' ");
    else sb.append(" AND a.end_date = '" + stdDate + "' ");

    //과제
    if("Y".equals(list.s("homework_yn"))) { sb.append(" AND EXISTS (SELECT 1 FROM " + homeworkUser.table + " WHERE course_user_id = a.id AND submit_yn = 'Y' AND status != -1) "); }
    else if("N".equals(list.s("homework_yn"))) { sb.append(" AND NOT EXISTS (SELECT 1 FROM " + homeworkUser.table + " WHERE course_user_id = a.id AND submit_yn = 'Y' AND status != -1) "); }

    //시험
    if("Y".equals(list.s("exam_yn"))) { sb.append(" AND EXISTS (SELECT 1 FROM " + examUser.table + " WHERE course_user_id = a.id AND submit_yn = 'Y') "); }
    else if("N".equals(list.s("exam_yn"))) { sb.append(" AND NOT EXISTS (SELECT 1 FROM " + examUser.table + " WHERE course_user_id = a.id AND submit_yn = 'Y') "); }

    //진도율
    if(list.d("min_ratio") > 0.00) sb.append(" AND a.progress_ratio >= " + list.d("min_ratio") + " ");
    if(list.d("max_ratio") > 0.00) sb.append(" AND a.progress_ratio <= " + list.d("max_ratio") + " ");

    String sauto = "ID : " + list.s("id") + " / " + list.s("subject") + " "
            + " / 기준일 : " + list.s("std_type") + ", " + list.s("std_day") + "일, " + stdDate + " "
            + " / SMS : " + list.s("sms_yn") + ", " + list.s("sms_template_cd") + " "
            + " / 이메일 : " + list.s("email_yn") + ", " + list.s("email_template_cd") + " "
            + " / 과제 : " + list.s("homework_yn") + " "
            + " / 시험 : " + list.s("exam_yn") + " "
            + " / 진도율 : " + list.s("min_ratio") + " - " + list.s("max_ratio");

    if(isTest) { m.p(sauto); m.p(sb.toString()); }

    _l.append("\n자동설정 : " + sauto + "");

    DataSet culist = courseUser.query(sb.toString());

    //정보
    boolean smsYn = "Y".equals(list.s("sms_yn")) && "Y".equals(list.s("ssms_yn")) && !"".equals(list.s("sms_sender")) && !"".equals(list.s("sms_id")) && !"".equals(list.s("sms_pw"));
    int newSmsId = 0;
    int sscnt = 0, sfcnt = 0;
    if(smsYn) {
        String sender = list.s("sms_sender");
        String content = p.fetchString(list.s("sms_content"));

        newSmsId = sms.getSequence();
        sms.item("id", newSmsId);
        sms.item("site_id", list.i("site_id"));

        sms.item("module", "user");
        sms.item("module_id", 0);
        sms.item("user_id", -9);
        sms.item("sms_type", "I");
        sms.item("sender", sender);
        sms.item("content", content);
        sms.item("resend_id", 0);
        sms.item("send_cnt", 0);
        sms.item("fail_cnt", 0);
        sms.item("send_date", now);
        sms.item("reg_date", now);
        sms.item("site_id", list.s("site_id"));
        sms.item("status", 1);

        if(!sms.insert()) {
            smsYn = true;
            newSmsId = 0;
        }
    }

    boolean isEmail = "Y".equals(list.s("email_yn")) && !"".equals(list.s("site_email"));
    int newMailId = 0;
    int mscnt = 0, mfcnt = 0;
    if(isEmail) {
        String subject = list.s("subject");
        String sender = list.s("site_email");
        String mbody = p.fetchString(list.s("content"));

        newMailId = mail.getSequence();

        mail.item("id", newMailId);
        mail.item("site_id", list.i("site_id"));
        mail.item("module", "user");
        mail.item("module_id", 0);
        mail.item("user_id", -9);
        mail.item("mail_type", "I");
        mail.item("sender", sender);
        mail.item("subject", subject);
        mail.item("content", mbody);
        mail.item("resend_id", 0);
        mail.item("send_cnt", 0);
        mail.item("fail_cnt", 0);
        mail.item("reg_date", now);
        mail.item("status", 1);

        if(!mail.insert()) {
            isEmail = false;
            newMailId = 0;
        }
    }

    if(!(smsYn || isEmail)) {
        _l.append("\n\t-- SMS/이메일 - 해당 없음");
        if(isTest) m.p("SMS/이메일 - 해당 없음");
        continue;
    }

    //목록
    if(culist.size() == 0) {
        _l.append("\n\t-- 해당 수강생 없음");
        if(isTest) m.p("해당 수강생 없음");
        continue;
    } else {
        _l.append("\n\t-- 수강생 : " + culist.size() + " 명");
        if(isTest) m.p("수강생 : " + culist.size() + " 명");
    }

    while(culist.next()) {

        culist.put("progress_ratio_conv", m.nf(culist.d("progress_ratio"),2));
        culist.put("progress_score_conv", m.nf(culist.d("progress_score"), 2));
        culist.put("exam_score_conv", m.nf(culist.d("exam_score"),2));
        culist.put("homework_score_conv", m.nf(culist.d("homework_score"),2));
        culist.put("total_score_conv", m.nf(culist.d("total_score"),2));
        culist.put("forum_score_conv", m.nf(culist.d("forum_score"), 2));
        culist.put("etc_score_conv", m.nf(culist.d("etc_score"), 2));
        culist.put("mobile_conv", !"".equals(culist.s("mobile")) ? SimpleAES.decrypt(culist.s("mobile")) : "" );

        culist.put("start_date", m.time("yyyy.MM.dd", culist.s("start_date") + "000000"));
        culist.put("start_date_conv", culist.s("start_date"));
        culist.put("end_date", m.time("yyyy.MM.dd", culist.s("end_date") + "235959"));
        culist.put("end_date_conv", culist.s("end_date"));

        culist.put("complete_yn_conv", culist.b("complete_yn") ? "수료" : "-");
        culist.put("close_conv", culist.b("close_yn") ? "마감" : "미마감");

        culist.put("email_content", "");
        culist.put("sms_content", "");

        culist.put("domain", list.s("domain"));
        culist.put("site_nm", list.s("site_nm"));
        culist.put("company_nm", list.s("company_nm"));
        culist.put("receive_email", list.s("receive_email"));
        culist.put("new_addr", list.s("new_addr"));
        culist.put("zipcode", list.s("zipcode"));
        culist.put("logo_url", m.getUploadUrl(list.s("logo")));

        String suser = culist.s("id") + ". 수강생명 : " + culist.s("user_nm") + " \t| 로그인아이디 : " + culist.s("login_id") + " "
                + " \t| 휴대전화번호 : " + culist.s("mobile_conv") + " \t| 이메일 : " + culist.s("email");

        _l.append("\n\t-- " + suser);
        if(isTest) m.p(suser);

        DataSet uinfo = new DataSet(); uinfo.addRow();
        if(smsYn) {
            String mobile = culist.s("mobile_conv");
            if(sms.isMobile(mobile)) {
                uinfo.put("id", culist.i("user_id"));
                uinfo.put("mobile", mobile);
                uinfo.put("user_nm", culist.s("user_nm"));

                p.clear();
                p.setVar(culist);

                sms.setAccount(list.s("sms_id"), list.s("sms_pw"));
                sms.setSite(list.i("site_id"));

                String sender = list.s("sms_sender");
                String content = p.fetchString(list.s("sms_content"));

                smsUser.item("sms_id", newSmsId);
                smsUser.item("mobile", SimpleAES.encrypt(uinfo.s("mobile")));
                smsUser.item("user_id", uinfo.i("id"));
                smsUser.item("user_nm", uinfo.s("user_nm"));
                smsUser.item("send_yn", "Y");
                if(smsUser.insert()) {
                    if(isTest) m.p(content);
                    else sms.send(mobile, sender, content);
                    sscnt++;
                } else {
                    smsUser.item("send_yn", "N");
                    if(smsUser.insert()) { }
                    sfcnt++;
                }
            } else sfcnt++;
        }


        if(isEmail && newMailId > 0) {
            String email = culist.s("email");
            if(mail.isMail(email)) {
                String subject = list.s("subject");
                m.mailFrom = list.s("site_email");

                p.clear();
                p.setRoot(culist.s("doc_root") + "/html");
                p.setLayout("auto");
                p.setVar("subject", subject);

                uinfo.put("id", culist.i("user_id"));
                uinfo.put("email", email);
                uinfo.put("user_nm", culist.s("user_nm"));
                p.setVar(culist);
                p.setVar("domain", list.s("domain"));

                String mbody = p.fetchString(list.s("email_content"));
                p.setVar("MBODY", mbody);

                mailUser.item("mail_id", newMailId);
                mailUser.item("email", uinfo.s("email"));
                mailUser.item("user_id", uinfo.s("id"));
                mailUser.item("user_nm", uinfo.s("user_nm"));
                mailUser.item("send_yn", "Y");
                if(mailUser.insert()) {
                    if(isTest) m.p(mbody);
                    else m.mail(email, subject, p.fetchAll());
                    mscnt++;
                } else {
                    mailUser.item("send_yn", "N");
                    if(mailUser.insert()) {}
                    mfcnt++;
                }
            } else mfcnt++;
        }
    }

    if(newSmsId > 0) {
        sms.execute("UPDATE " + sms.table + " SET send_cnt = " + sscnt + ", fail_cnt = " + sfcnt + " WHERE id = " + newSmsId + "");
    }

    if(newMailId > 0) {
        mail.execute("UPDATE " + mail.table + " SET send_cnt = " + mscnt + ", fail_cnt = " + mfcnt + " WHERE id = " + newMailId + "");
    }
}

_l.append("\n---------- 종료 -------------------------------------\n");

m.log("auto", _l.toString());

if(isExec) {
    m.jsAlert("학습독려를 실행하였습니다.");
    //m.jsReplace("auto_list.jsp", "parent");
    return;
}
%>